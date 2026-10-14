"""Android dev process force-stop/relaunch; never asserts K1..K4 correctness.

Stop at the documented debugger boundary BEFORE invoking this command. This
records PID facts only; server attempts, costs, points and document uniqueness
need separate inspection. Does not clear data, upload logs, deploy or enable AI.
"""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import time

PACKAGE = 'co.byite.soongong.dev'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--serial', required=True)
    parser.add_argument('--checkpoint', choices=['K1', 'K2', 'K3', 'K4'], required=True)
    parser.add_argument('--operation', choices=['text', 'math', 'grading'], required=True)
    parser.add_argument('--boundary-proof', type=Path, required=True,
                        help='Private local evidence of the observed debugger/server boundary; only hash recorded')
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    if args.output.resolve().is_relative_to(root) or args.output.exists():
        parser.error('output must be new and outside the repository')
    if not re.fullmatch(r'[A-Za-z0-9_.:-]+', args.serial):
        parser.error('invalid device serial')
    adb = shutil.which('adb')
    if not adb:
        parser.error('adb unavailable; real device execution remains UNVERIFIED')
    # Read evidence and reserve the output before performing any device action.
    proof = hashlib.sha256(args.boundary_proof.read_bytes()).hexdigest()
    def command(*parts, allow_empty=False):
        result = subprocess.run([adb, '-s', args.serial, *parts], capture_output=True,
                                text=True, timeout=20, check=False)
        if result.returncode and not (allow_empty and result.returncode == 1 and not result.stdout.strip()):
            raise RuntimeError('adb_command_failed')  # no device log, private path or ID
        return result.stdout.strip()
    def pids():
        value = command('shell', 'pidof', PACKAGE, allow_empty=True)
        if value and not re.fullmatch(r'[0-9 ]+', value):
            raise RuntimeError('invalid_pid_response')
        return [int(v) for v in value.split()]
    report = {'checkpoint': args.checkpoint, 'operation': args.operation,
              'package': PACKAGE, 'kill_method': 'Android am force-stop',
              'created_at': datetime.now(timezone.utc).isoformat(),
              'source_head': subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=root, text=True).strip(),
              'installed_build_source_match': 'UNVERIFIED',
              'boundary_proof_sha256': proof, 'checkpoint_independently_verified': False,
              'device_serial_sha256': hashlib.sha256(args.serial.encode()).hexdigest(),
              'pid_cycle_status': 'UNVERIFIED', 'recovery_status': 'UNVERIFIED',
              'attempt_count': None, 'point_debits': None, 'provider_cost': None,
              'document_count': None}
    with args.output.open('x', encoding='utf-8') as output:
        try:
            if command('get-state') != 'device':
                raise RuntimeError('device_unavailable')
            component = command('shell', 'cmd', 'package', 'resolve-activity', '--brief', PACKAGE).splitlines()[-1]
            if not re.fullmatch(re.escape(PACKAGE) + r'/[A-Za-z0-9_.$]+', component):
                raise RuntimeError('dev_activity_unavailable')
            before = pids(); report['pid_before'] = before
            if not before:
                raise RuntimeError('app_not_running_at_boundary')
            command('shell', 'am', 'force-stop', PACKAGE)
            stopped = pids(); report['pid_after_stop'] = stopped
            if stopped:
                raise RuntimeError('process_not_stopped')
            command('shell', 'am', 'start', '-W', '-n', component)
            after = []
            for _ in range(40):
                after = pids()
                if after: break
                time.sleep(.25)
            report['pid_after_start'] = after
            if not after or set(before) & set(after):
                raise RuntimeError('new_process_not_verified')
            report['pid_cycle_status'] = 'PASS'
        except (RuntimeError, subprocess.SubprocessError, IndexError):
            report['pid_cycle_status'] = 'FAIL'
            raise
        finally:
            json.dump(report, output, indent=2)
            output.write('\n')
    print('PID cycle recorded; K recovery/ledger verification remains UNVERIFIED')


if __name__ == '__main__':
    main()
