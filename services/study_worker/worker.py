"""Stateless study inference. Bind behind TLS/private ingress, never expose directly.

Only the Edge gateway holds WORKER_SECRET. No Supabase credential is given to
model children. Payloads are neither logged nor persisted; one child per call
gives an enforceable deadline, reclaimed model memory, and no retained images.
"""
import base64
import hashlib
import hmac
import io
import json
import multiprocessing as mp
import os
from pathlib import Path
import signal
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

MAX_BYTES = 4 * 1024 * 1024
MAX_BODY = 5_600_000
SLOT = threading.BoundedSemaphore(1)


def decode_image(encoded):
    from PIL import Image, ImageOps
    if not isinstance(encoded, str) or len(encoded) > 5_592_408:
        raise ValueError("invalid_image")
    raw = base64.b64decode(encoded, validate=True)
    if not raw or len(raw) > MAX_BYTES:
        raise ValueError("invalid_image")
    Image.MAX_IMAGE_PIXELS = 12_000_000
    with Image.open(io.BytesIO(raw)) as image:
        if image.format not in {"JPEG", "PNG", "WEBP"} or image.width * image.height > 12_000_000:
            raise ValueError("invalid_image")
        if getattr(image, "n_frames", 1) != 1:
            raise ValueError("invalid_image")
        image.load()
        return ImageOps.exif_transpose(image).convert("RGB")


def checked_models():
    """Every model file must be listed and hashed; no runtime model download."""
    root = Path(os.environ["MODEL_ROOT"]).resolve()
    manifest = json.loads((root / "models.lock.json").read_text())
    files = manifest["files"]
    if not files or not isinstance(manifest.get("revision"), str):
        raise ValueError("model_manifest_required")
    actual = {str(p.relative_to(root)) for p in root.rglob("*") if p.is_file() and p.name != "models.lock.json"}
    if actual != set(files):
        raise ValueError("model_manifest_mismatch")
    for relative, expected in files.items():
        path = (root / relative).resolve()
        if not path.is_relative_to(root) or path.is_symlink() or len(expected) != 64:
            raise ValueError("model_manifest_invalid")
        with path.open("rb") as stream:
            digest = hashlib.file_digest(stream, "sha256").hexdigest()
        if not hmac.compare_digest(digest, expected):
            raise ValueError("model_manifest_mismatch")
    return root, manifest["revision"]


def infer_ocr(body):
    image = decode_image(body["image"])
    root, revision = checked_models()
    kind = body["kind"]
    if kind == "text":
        import numpy as np
        from paddleocr import PaddleOCR
        engine = PaddleOCR(lang="korean", ocr_version="PP-OCRv3",
            text_detection_model_dir=str(root / "detection"),
            text_recognition_model_dir=str(root / "korean"),
            use_doc_orientation_classify=False, use_doc_unwarping=False,
            use_textline_orientation=False)
        result = next(iter(engine.predict(np.asarray(image))))
        blocks = []
        for text, score, poly in zip(result["rec_texts"], result["rec_scores"], result["rec_polys"], strict=True):
            points = np.asarray(poly)
            box = [float(points[:, 0].min() / image.width), float(points[:, 1].min() / image.height),
                   float(points[:, 0].max() / image.width), float(points[:, 1].max() / image.height)]
            blocks.append({"text": str(text), "confidence": float(score), "box": [max(0., min(1., x)) for x in box]})
        name = "paddleocr-3.7.0"
    elif kind == "math":
        from unimernet_adapter import recognize
        blocks = [{"text": recognize(image, root), "confidence": None, "box": [0., 0., 1., 1.]}]
        name = "unimernet-0.2.3"
    else:
        raise ValueError("invalid_kind")
    if len(blocks) > 500 or sum(len(b["text"]) + 1 for b in blocks) > 20000:
        raise ValueError("result_too_large")
    return {"schema_version": 1, "kind": kind, "engine": name + ":" + revision, "blocks": blocks}


def child(body, connection):
    # Child exceptions never serialize input, paths, model logs, or secrets.
    os.setsid()
    os.environ.pop("WORKER_SECRET", None)
    try:
        import resource
        resource.setrlimit(resource.RLIMIT_CPU, (45, 45))
        resource.setrlimit(resource.RLIMIT_CORE, (0, 0))
        with open(os.devnull, "w") as sink:
            os.dup2(sink.fileno(), 1)
            os.dup2(sink.fileno(), 2)
        if body["operation"] == "solve":
            from solver import solve
            result = solve(body)
        else:
            result = infer_ocr(body)
        connection.send({"ok": result})
    except BaseException:
        connection.send({"error": "inference_failed"})
    finally:
        connection.close()


def execute(body, timeout=50):
    context = mp.get_context("spawn")
    parent, remote = context.Pipe(duplex=False)
    process = context.Process(target=child, args=(body, remote))
    process.start()
    remote.close()
    try:
        if not parent.poll(timeout):
            raise TimeoutError("inference_timeout")
        result = parent.recv()
        if "ok" not in result:
            raise ValueError("inference_failed")
        return result["ok"]
    finally:
        if process.is_alive():
            try: os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError: process.kill()
        process.join(timeout=2)
        parent.close()


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *_):
        pass

    def do_POST(self):
        expected = "Bearer " + os.environ["WORKER_SECRET"]
        if not hmac.compare_digest(self.headers.get("Authorization", ""), expected):
            self.send_error(401); return
        if self.path != "/infer" or self.headers.get("Transfer-Encoding"):
            self.send_error(400); return
        try: length = int(self.headers.get("Content-Length", "0"))
        except ValueError: length = 0
        if not 0 < length <= MAX_BODY:
            self.send_error(413); return
        if not SLOT.acquire(blocking=False):
            self.send_error(429); return
        try:
            self.connection.settimeout(10)
            raw = self.rfile.read(length)
            if len(raw) != length: raise ValueError("truncated_body")
            body = json.loads(raw)
            if body.get("schema_version") != 1 or body.get("operation") not in {"ocr", "solve"} or (body.get("operation") == "ocr" and body.get("kind") not in {"text", "math"}):
                raise ValueError("invalid_payload")
            result = json.dumps(execute(body), ensure_ascii=False, allow_nan=False).encode()
            if len(result) > 256000: raise ValueError("result_too_large")
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Cache-Control", "no-store")
            self.send_header("Content-Length", str(len(result)))
            self.end_headers()
            self.wfile.write(result)
        except (Exception, TimeoutError):
            self.send_error(503, "inference_unavailable")
        finally: SLOT.release()


if __name__ == "__main__":
    if len(os.environ.get("WORKER_SECRET", "")) < 32:
        raise SystemExit("WORKER_SECRET must contain at least 32 characters")
    ThreadingHTTPServer(("0.0.0.0", int(os.environ.get("PORT", "8080"))), Handler).serve_forever()
