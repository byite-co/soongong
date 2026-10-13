"""Opt-in numeric diagnostics; no model output, exception text or logging I/O.

One fixed shared buffer belongs to one spawned request. Only that child writes
it; the parent takes the snapshot after cleanup. A killed child can leave an
incomplete sample, which is never promoted to complete request accounting.
"""
import math
import os
import resource
import sys
import time

STAGES = ('decode', 'model_validation', 'model_load', 'detect_recognize',
          'recognize', 'grading', 'serialize', 'ipc', 'child_cleanup')
REJECTIONS = ('byte_limit', 'empty', 'base64', 'format', 'frames', 'corrupt', 'pixels')
ERRORS = ('input_rejected', 'python_exception', 'cancelled')
EVENT_LIMIT = 32
HEADER = 10
_current = None


def rss_bytes(value, platform=None):
    # getrusage(2): Linux reports KiB; macOS reports bytes. Never guess on
    # another OS. RUSAGE_SELF excludes separately executing descendants.
    platform = platform or sys.platform
    if platform.startswith('linux'):
        return int(value * 1024)
    if platform == 'darwin':
        return int(value)
    return None


def set_current(trace):
    global _current
    _current = trace


def stage(name):
    if _current is not None:
        _current.mark(name)


def rejected(reason):
    if _current is not None:
        _current.data[1] = REJECTIONS.index(reason) + 1
        _current.fail('input_rejected')


def failure(code):
    if _current is not None:
        _current.fail(code)


class ChildTrace:
    def __init__(self, context):
        self.data = context.RawArray('d', HEADER + EVENT_LIMIT * 2)

    def sample(self, complete=False):
        try:
            usage = resource.getrusage(resource.RUSAGE_SELF)
            self.data[3] = usage.ru_maxrss
            self.data[4] = usage.ru_utime
            self.data[5] = usage.ru_stime
            self.data[6] = time.monotonic()
            self.data[7] = 1 if complete else 0
            self.data[8] = 1
        except (OSError, ValueError):
            pass

    def mark(self, name):
        index = int(self.data[0])
        if index < EVENT_LIMIT:
            offset = HEADER + index * 2
            self.data[offset] = STAGES.index(name) + 1
            self.data[offset + 1] = time.monotonic()
            self.data[0] = index + 1
        self.sample()

    def fail(self, code):
        self.data[2] = ERRORS.index(code) + 1

    def snapshot(self):
        values = list(self.data)
        if any(not math.isfinite(v) for v in values):
            return {'available': False, 'reason': 'invalid_numeric_sample'}
        events = []
        for i in range(min(EVENT_LIMIT, max(0, int(values[0])))):
            code, stamp = values[HEADER + i * 2:HEADER + i * 2 + 2]
            if 1 <= int(code) <= len(STAGES):
                events.append({'stage': STAGES[int(code) - 1], 'monotonic_seconds': stamp})
        def named(index, names):
            code = int(values[index])
            return names[code - 1] if 1 <= code <= len(names) else None
        available = bool(values[8])
        return {
            'available': available, 'stages': events,
            'input_rejection': named(1, REJECTIONS), 'error_code': named(2, ERRORS),
            'resource': {
                'scope': 'request_child_RUSAGE_SELF_excludes_descendants',
                'sampling': 'stage_boundaries_and_target_return',
                'sampling_interval_seconds': None,
                'complete_target_lifetime': bool(values[7]),
                'may_miss_final_peak': not bool(values[7]),
                'max_rss_bytes': rss_bytes(values[3]) if available else None,
                'raw_ru_maxrss': values[3] if available else None,
                'raw_ru_maxrss_unit': 'KiB' if sys.platform.startswith('linux') else 'bytes' if sys.platform == 'darwin' else None,
                'user_cpu_seconds': values[4] if available else None,
                'system_cpu_seconds': values[5] if available else None,
                'sample_monotonic_seconds': values[6] if available else None,
                'gpu_peak_bytes': None,
                'unavailable_reason': None if available else 'child_did_not_report',
            },
        }


def observe_exit_without_reaping(pid):
    """WNOWAIT leaves the group leader for multiprocessing's single join.

An observed signal is an exit status, not evidence of OOM/native failure.
If the child exits after this observation, parent cleanup races remain unknown.
"""
    try:
        result = os.waitid(os.P_PID, pid, os.WEXITED | os.WNOHANG | os.WNOWAIT)
    except (AttributeError, ChildProcessError, OSError):
        return {'state': 'unknown', 'exitcode': None}
    if result is None:
        return {'state': 'not_observed_exited', 'exitcode': None}
    if result.si_code == os.CLD_EXITED:
        code = result.si_status
    elif result.si_code in (os.CLD_KILLED, os.CLD_DUMPED):
        code = -result.si_status
    else:
        return {'state': 'unknown', 'exitcode': None}
    return {'state': 'exited_before_parent_cleanup', 'exitcode': code}


def parent_children_usage():
    # Python resource docs: RUSAGE_CHILDREN covers terminated, waited-for
    # children. CPU totals can be differenced; ru_maxrss cannot.
    # https://docs.python.org/3.11/library/resource.html#resource.RUSAGE_CHILDREN
    # https://man7.org/linux/man-pages/man2/getrusage.2.html (ru_maxrss units)
    value = resource.getrusage(resource.RUSAGE_CHILDREN)
    return {'user_cpu_seconds': value.ru_utime, 'system_cpu_seconds': value.ru_stime,
            'max_rss_bytes': rss_bytes(value.ru_maxrss)}
