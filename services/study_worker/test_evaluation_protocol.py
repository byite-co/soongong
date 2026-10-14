"""Synthetic evidence-pipeline tests; these are not model accuracy results."""
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import sys
from types import SimpleNamespace
import unittest
from unittest.mock import patch

from PIL import Image
import ocr_evaluation as evaluation


class EvaluationProtocolTests(unittest.TestCase):
    def test_policy_strata_cannot_relabel_model_eof_as_expected_rejection(self):
        accepted = {'status': 'accepted', 'reason': None}
        rejected = {'status': 'rejected', 'reason': 'byte_limit'}
        rows = [
            {'seconds': 1, 'valid': True, 'input_validation': accepted},
            {'seconds': 1, 'valid': False, 'error': 'EOFError', 'input_validation': accepted},
            {'seconds': 1, 'valid': False, 'input_validation': rejected,
             'diagnostics': {'child': {'input_rejection': 'byte_limit'}}},
            {'seconds': 1, 'valid': False, 'error': 'EOFError', 'input_validation': rejected},
        ]
        result = evaluation.summarize(rows, 'text')
        self.assertEqual(result['attempts'], 4)
        self.assertEqual(result['valid_rate'], .25)
        self.assertEqual(result['input_policy']['accepted_attempts'], 2)
        self.assertEqual(result['input_policy']['accepted_valid_rate'], .5)
        self.assertEqual(result['input_policy']['expected_rejections'], 2)
        self.assertEqual(result['input_policy']['matched_rejections'], 1)

    def test_raw_output_preserves_existing_report_and_rejects_repository_path(self):
        with tempfile.TemporaryDirectory() as directory:
            folder = Path(directory); manifest = folder / 'manifest.json'
            manifest.write_text('[]')
            report = folder / 'original.json'; report.write_text('original evidence')
            args = SimpleNamespace(manifest=manifest, output=report, repetitions=1)
            with self.assertRaisesRegex(ValueError, 'report_already_exists'):
                evaluation.run(args)
            self.assertEqual(report.read_text(), 'original evidence')
            args.output = Path(__file__).resolve().parent / 'never-write-raw.json'
            with self.assertRaisesRegex(ValueError, 'raw_report_must_be_outside_repository'):
                evaluation.run(args)
            self.assertFalse(args.output.exists())

    def test_input_metadata_checks_exif_dimensions_and_hash(self):
        raw = io.BytesIO(); exif = Image.Exif(); exif[274] = 6
        Image.new('RGB', (8, 4)).save(raw, format='JPEG', exif=exif)
        result = evaluation.classify_input(raw.getvalue())
        self.assertEqual(result['status'], 'accepted')
        self.assertEqual((result['width_after_exif'], result['height_after_exif']), (4, 8))
        self.assertEqual(result['frames'], 1)
        with tempfile.TemporaryDirectory() as directory:
            image = Path(directory) / 'synthetic.jpg'; image.write_bytes(raw.getvalue())
            with self.assertRaisesRegex(ValueError, 'input_hash_mismatch'):
                evaluation.input_bytes({'path': str(image), 'sha256': '0' * 64})

    def test_repeat_execution_keeps_each_attempt_and_preflights_before_dispatch(self):
        with tempfile.TemporaryDirectory() as directory:
            folder = Path(directory); image = folder / 'synthetic.png'
            Image.new('RGB', (8, 4)).save(image)
            row = {'path': str(image), 'sha256': hashlib.sha256(image.read_bytes()).hexdigest(),
                   'ground_truth': 'x', 'source': 'synthetic', 'split': 'fixture'}
            manifest = folder / 'manifest.json'; manifest.write_text(json.dumps([row]))
            protocol = folder / 'protocol.json'; protocol.write_text('{}')
            (folder / 'models.lock.json').write_text('{}')
            args = SimpleNamespace(manifest=manifest, protocol=protocol, output=folder / 'report.json',
                                   kind='math', repetitions=3)
            def execute(_body, timeout, diagnostics):
                self.assertEqual(timeout, 50)
                diagnostics['child'] = {'resource': {'max_rss_bytes': 100}}
                return {'blocks': [{'text': 'x'}]}
            with patch('worker.checked_models', return_value=(folder, 'fixture')), \
                 patch.dict('os.environ', {'WORKER_MODEL_ID': 'fixture'}), \
                 patch('worker.execute', side_effect=execute) as dispatch:
                evaluation.run(args)
            report = json.loads(args.output.read_text())
            self.assertEqual(dispatch.call_count, 3)
            self.assertEqual([r['repetition'] for r in report['rows']], [1, 2, 3])
            self.assertEqual(report['summary']['input_policy']['accepted_attempts'], 3)
            self.assertEqual(report['summary']['normalized_exact_match'], 1)
            self.assertIn('files_sha256', report['code'])

    def test_new_selection_is_deterministic_and_excludes_previous_diagnostic_rows(self):
        path = Path(__file__).resolve().parents[2] / 'tool/prepare_next02b_holdout.py'
        spec = importlib.util.spec_from_file_location('next02b_selection', path)
        module = importlib.util.module_from_spec(spec); spec.loader.exec_module(module)
        first = module.select_indices()
        self.assertEqual(first, module.select_indices())
        self.assertEqual(len(set(first)), 5921 - 60)
        self.assertTrue(all(60 <= i < 5921 for i in first))
        self.assertNotEqual(first[:60], module.select_indices(seed=20261015)[:60])
        with self.assertRaisesRegex(ValueError, 'insufficient_unseen_rows'):
            module.select_indices(total=70, previous=60, count=60)

    def test_thread_comparison_passes_exact_setting_and_restores_adapter(self):
        import paddle_adapter
        with tempfile.TemporaryDirectory() as directory:
            folder=Path(directory)
            (folder/'models.lock.json').write_text('{"revision":"paddle-v5-next02"}')
            received=[]
            fake=SimpleNamespace(PaddleOCR=lambda **options: received.append(options))
            with patch.dict(sys.modules, {'paddleocr':fake}):
                # Exercise the unmodified product child path, not an eval override.
                paddle_adapter.load(folder)
                self.assertEqual(received[-1]['cpu_threads'],1)
                self.assertFalse(received[-1]['enable_mkldnn'])
                self.assertEqual(received[-1]['device'],'cpu')
                for count in (1,2,4):
                    with patch('worker.child', side_effect=lambda _b,_c:paddle_adapter.load(folder)):
                        original=paddle_adapter.load
                        evaluation.paddle_evaluation_child({},None,cpu_threads=count)
                        self.assertIs(paddle_adapter.load,original)
                    self.assertEqual(received[-1]['cpu_threads'],count)
                    self.assertFalse(received[-1]['enable_mkldnn'])
                for invalid in (0,8,True,'4'):
                    with self.assertRaisesRegex(ValueError,'invalid_cpu_threads'):
                        paddle_adapter.load(folder,cpu_threads=invalid)
            with patch('worker.child',side_effect=ValueError('synthetic')):
                with self.assertRaises(ValueError):
                    evaluation.paddle_evaluation_child({},None,cpu_threads=1)
                self.assertIs(paddle_adapter.load,original)


if __name__ == '__main__':
    unittest.main()
