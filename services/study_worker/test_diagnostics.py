"""Real isolated-process diagnostics and input policy regressions, no models."""
import base64
import io
import json
import multiprocessing as mp
from multiprocessing.connection import wait
import os
import signal
import struct
import threading
import time
import unittest
from unittest.mock import patch

from PIL import Image
import diagnostics
import worker
from process_ipc import ResultReader
from ocr_evaluation import summarize


def synthetic_worker(body, connection):
    def infer(_body):
        diagnostics.stage('recognize')
        if body.get('exception'):
            raise RuntimeError('/private/path TOKEN_PRIVATE transcription-private')
        return {'text': 'transcription-private'}
    with patch('worker.infer_ocr', side_effect=infer):
        worker.child(body, connection)


def early_exit(_body, connection):
    os.setsid()
    diagnostics.stage('model_load')
    os._exit(23)


def partial_output(_body, connection):
    os.setsid()
    signal.signal(signal.SIGTERM, signal.SIG_IGN)
    diagnostics.stage('ipc')
    os.write(connection.fileno(), struct.pack('!i', 100) + b'{')
    time.sleep(30)


def large_output(body, connection):
    with patch('worker.infer_ocr', return_value={'text': 's' * worker.MAX_RESPONSE * 2}):
        worker.child(body, connection)


def rss_worker(body, connection):
    # Touch real pages. Low requests after high ones must not inherit the
    # parent's lifetime RUSAGE_CHILDREN high-water value.
    allocation = bytearray(body['allocation_bytes'])
    with patch('worker.infer_ocr', return_value={'bytes': len(allocation)}):
        worker.child(body, connection)


class ImageAdmissionTests(unittest.TestCase):
    def image(self, format='PNG', **kwargs):
        raw = io.BytesIO()
        Image.new('RGB', (8, 4)).save(raw, format=format, **kwargs)
        return base64.b64encode(raw.getvalue()).decode()

    def assert_rejected(self, encoded, reason):
        with patch('worker.checked_models') as model:
            with self.assertRaises(worker.ImageInputRejected) as caught:
                worker.infer_ocr({'operation': 'ocr', 'kind': 'text', 'image': encoded})
            self.assertEqual(caught.exception.reason, reason)
            self.assertEqual(str(caught.exception), 'invalid_image')
            model.assert_not_called()

    def test_byte_boundary_is_not_an_image_validity_claim(self):
        for size in (worker.MAX_BYTES - 1, worker.MAX_BYTES):
            raw = b'x' * size
            worker.validate_image_bytes(raw)
            self.assert_rejected(base64.b64encode(raw).decode(), 'corrupt')
        with self.assertRaises(worker.ImageInputRejected) as caught:
            worker.validate_image_bytes(b'x' * (worker.MAX_BYTES + 1))
        self.assertEqual(caught.exception.reason, 'byte_limit')

    def test_reported_oversize_lengths_reject_three_times_before_model_load(self):
        for size in (4_540_191, 4_207_053):
            encoded = base64.b64encode(b'x' * size).decode()
            for repetition in range(3):
                with self.subTest(bytes=size, repetition=repetition):
                    self.assert_rejected(encoded, 'byte_limit')

    def test_corruption_multiframe_and_unsupported_format_are_distinct(self):
        self.assert_rejected('@@', 'base64')
        self.assert_rejected('', 'empty')
        self.assert_rejected('YQ==', 'corrupt')
        self.assert_rejected(self.image('BMP'), 'format')
        self.assert_rejected(self.image('PNG', save_all=True,
            append_images=[Image.new('RGB', (8, 4), 'red')]), 'frames')

    def test_pixel_limit_and_exif_dimensions(self):
        raw = io.BytesIO()
        Image.new('1', (4001, 3000)).save(raw, format='PNG')
        self.assertLess(len(raw.getvalue()), worker.MAX_BYTES)
        self.assert_rejected(base64.b64encode(raw.getvalue()).decode(), 'pixels')
        exif = Image.Exif(); exif[274] = 6
        image = worker.decode_image(self.image('JPEG', exif=exif))
        self.assertEqual(image.size, (4, 8))
        image.close()


class DiagnosticTests(unittest.TestCase):
    def tearDown(self):
        self.assertEqual(mp.active_children(), [])

    def test_success_keeps_content_out_of_bounded_diagnostic_snapshot(self):
        details = {}
        self.assertEqual(worker.execute({'operation': 'ocr'}, timeout=5,
            _target=synthetic_worker, diagnostics=details), {'text': 'transcription-private'})
        text = json.dumps(details)
        self.assertNotIn('transcription-private', text)
        self.assertLess(len(text), 8192)
        self.assertEqual(details['parent_outcome'], 'result')
        self.assertTrue(details['result_received'])
        self.assertEqual(details['exit_cause'], 'unknown')
        self.assertTrue(all(s['reason'] == 'result' for s in details['parent_signals']))
        phases = [x['stage'] for x in details['child']['stages']]
        self.assertIn('serialize', phases)
        self.assertIn('ipc', phases)

    def test_exception_never_copies_message_or_private_path(self):
        details = {}
        with self.assertRaisesRegex(ValueError, '^inference_failed$'):
            worker.execute({'operation': 'ocr', 'exception': True}, timeout=5,
                _target=synthetic_worker, diagnostics=details)
        text = json.dumps(details)
        for secret in ('TOKEN_PRIVATE', '/private/path', 'transcription-private'):
            self.assertNotIn(secret, text)
        self.assertEqual(details['child']['error_code'], 'python_exception')

    def test_input_rejection_is_observed_without_loading_model(self):
        details = {}
        with self.assertRaisesRegex(ValueError, '^inference_failed$'):
            worker.execute({'operation': 'ocr', 'kind': 'text', 'image': 'YQ=='},
                timeout=5, diagnostics=details)
        self.assertEqual(details['child']['input_rejection'], 'corrupt')
        self.assertNotIn('model_load', [s['stage'] for s in details['child']['stages']])

    def test_eof_exit_and_parent_cleanup_are_separate(self):
        details = {}
        with self.assertRaises(EOFError):
            worker.execute({}, timeout=5, _target=early_exit, diagnostics=details)
        self.assertEqual(details['parent_outcome'], 'ipc_eof')
        self.assertFalse(details['result_received'])
        self.assertEqual(details['exitcode_after_parent_cleanup'], 23)
        self.assertEqual(details['exit_cause'], 'unknown')
        self.assertFalse(details['child']['resource']['complete_target_lifetime'])

    def test_wnowait_observation_does_not_steal_multiprocessing_reap(self):
        context = mp.get_context('spawn')
        parent, remote = context.Pipe(duplex=False)
        process = context.Process(target=early_exit, args=({}, remote))
        try:
            process.start(); remote.close()
            self.assertTrue(wait([process.sentinel], timeout=5))
            self.assertEqual(diagnostics.observe_exit_without_reaping(process.pid),
                {'state': 'exited_before_parent_cleanup', 'exitcode': 23})
            # A second WNOWAIT sees the same unreaped status; join is the owner.
            self.assertEqual(diagnostics.observe_exit_without_reaping(process.pid)['exitcode'], 23)
            process.join(timeout=1)
            self.assertEqual(process.exitcode, 23)
            process.close()
        finally:
            parent.close(); remote.close()

    def test_truncated_ipc_deadline_remains_bounded_and_does_not_claim_natural_kill(self):
        details = {}; before = set(threading.enumerate()); started = time.monotonic()
        with self.assertRaises(TimeoutError):
            worker.execute({}, timeout=1, _target=partial_output, diagnostics=details)
        self.assertLess(time.monotonic() - started, 2)
        self.assertEqual(details['parent_outcome'], 'deadline')
        self.assertEqual(details['exit_cause'], 'unknown')
        self.assertTrue(any(s['signal'] == 'SIGKILL' and s['sent'] for s in details['parent_signals']))
        self.assertEqual(set(threading.enumerate()), before)

    def test_large_output_is_rejected_before_pipe_write(self):
        details = {}
        with self.assertRaisesRegex(ValueError, '^inference_failed$'):
            worker.execute({'operation': 'ocr'}, timeout=5, _target=large_output, diagnostics=details)
        self.assertEqual(details['parent_outcome'], 'child_reported_error')
        self.assertEqual(details['child']['error_code'], 'python_exception')

    def test_cleanup_failure_is_not_reported_as_success(self):
        details = {}; real_close = ResultReader.close
        def closed_but_unconfirmed(reader, timeout):
            self.assertTrue(real_close(reader, timeout))
            return False
        with patch.object(ResultReader, 'close', closed_but_unconfirmed):
            with self.assertRaises(worker.ProcessCleanupFailed):
                worker.execute({'operation': 'ocr'}, timeout=5, _target=synthetic_worker, diagnostics=details)
        self.assertTrue(details['cleanup_failed'])

    def test_pre_cancel_clears_previous_request_diagnostics(self):
        details = {'result_received': True, 'old_request': True}
        with self.assertRaises(TimeoutError):
            worker.execute({}, cancelled=lambda: True, diagnostics=details)
        self.assertEqual(details['parent_outcome'], 'not_started')
        self.assertFalse(details['result_received'])
        self.assertNotIn('old_request', details)

    def test_sequential_self_rss_is_not_parent_children_high_water(self):
        samples = []
        for size in (1024, 96 * 1024**2, 1024):
            details = {}
            worker.execute({'operation': 'ocr', 'allocation_bytes': size}, timeout=5,
                _target=rss_worker, diagnostics=details)
            sample = details['child']['resource']
            self.assertEqual(sample['scope'], 'request_child_RUSAGE_SELF_excludes_descendants')
            self.assertIsNone(sample['gpu_peak_bytes'])
            samples.append(sample['max_rss_bytes'])
        self.assertGreater(samples[1], samples[0] + 64 * 1024**2)
        self.assertLess(samples[2], samples[1] - 64 * 1024**2)

    def test_units_and_legacy_report_scope(self):
        self.assertEqual(diagnostics.rss_bytes(3, 'linux'), 3072)
        self.assertEqual(diagnostics.rss_bytes(3, 'darwin'), 3)
        self.assertIsNone(diagnostics.rss_bytes(3, 'unknown'))
        result = summarize([{'seconds': 1, 'valid': True, 'child_rss_kib': 999999}], 'math')
        self.assertIsNone(result['max_reported_request_self_rss_bytes'])
        self.assertNotIn('max_child_rss_kib', result)

    def test_unstarted_request_has_no_resource_sample(self):
        result = summarize([{'seconds': 0, 'diagnostics': {'child': None},
                             'error': 'TimeoutError'}], 'text')
        self.assertEqual(result['request_resource_samples'], 0)
        self.assertIsNone(result['max_reported_request_self_rss_bytes'])


if __name__ == '__main__':
    unittest.main()
