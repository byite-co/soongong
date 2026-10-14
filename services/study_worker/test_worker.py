import base64
import hashlib
import io
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from PIL import Image
from worker import checked_models, decode_image


class WorkerTests(unittest.TestCase):
    def test_valid_image_and_orientation(self):
        source = io.BytesIO()
        Image.new("RGB", (8, 4)).save(source, format="PNG")
        image = decode_image(base64.b64encode(source.getvalue()).decode())
        self.assertEqual(image.size, (8, 4))

    def test_invalid_base64_and_not_image(self):
        for value in ["@@", "YQ==", "", "A" * 5_592_409]:
            with self.assertRaises(Exception): decode_image(value)

    def test_manifest_detects_unlisted_and_modified_weights(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / "weights").write_bytes(b"fixture")
            (root / "models.lock.json").write_text(json.dumps({"revision": "fixture", "files": {
                "weights": hashlib.sha256(b"fixture").hexdigest()}}))
            with patch.dict(os.environ, {"MODEL_ROOT": directory}):
                self.assertEqual(checked_models()[1], "fixture")
                (root / "weights").write_bytes(b"tampered")
                with self.assertRaises(ValueError): checked_models()
                (root / "extra").write_text("not locked")
                with self.assertRaises(ValueError): checked_models()


if __name__ == "__main__": unittest.main()
