"""Stateless study inference. Bind behind TLS/private ingress, never expose directly.

Only the Edge gateway holds WORKER_SECRET. No Supabase credential is given to
model children. Payloads are neither logged nor persisted; one child per call
gives an enforceable deadline, reclaimed model memory, and no retained images.
"""
import base64
import ctypes
import hashlib
import hmac
import io
import json
import multiprocessing as mp
from multiprocessing.connection import wait
import os
from pathlib import Path
import signal
import select
import socket
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from process_ipc import ResultReader, send_result

MAX_BYTES = 4 * 1024 * 1024
MAX_BODY = 5_600_000
MAX_RESPONSE = 256_000
BODY_SECONDS = 10
REQUEST_SECONDS = 50
PROCESS_CLEANUP_SECONDS = 1
SLOT = threading.BoundedSemaphore(1)


class ProcessCleanupFailed(RuntimeError):
    """Fail closed: do not admit another request over an unreaped worker."""


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
    def cancelled(_signum, _frame):
        raise InterruptedError("inference_cancelled")
    signal.signal(signal.SIGTERM, cancelled)
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
        send_result(connection, {"ok": result})
    except BaseException:
        try: send_result(connection, {"error": "inference_failed"})
        except (BrokenPipeError, EOFError, OSError): pass
    finally:
        connection.close()


def execute(body, timeout=REQUEST_SECONDS, *, cancelled=lambda: False, _target=None, _clock=None):
    now = _clock or time.monotonic
    if timeout <= 0 or cancelled():
        raise TimeoutError("inference_timeout")
    deadline = now() + timeout
    # Linux subreaper: if a hard kill prevents the worker from reaping CAS,
    # those children are adopted here, not left to an unknown container PID 1.
    # Reaping below is restricted to this request's own process group.
    if ctypes.CDLL(None, use_errno=True).prctl(36, 1, 0, 0, 0) != 0:
        raise OSError(ctypes.get_errno(), "subreaper_unavailable")
    # Reserve part of this same budget for graceful CAS kill/join. It is not
    # another allowance added after the caller's 50-second deadline.
    cleanup = min(PROCESS_CLEANUP_SECONDS, timeout / 2)
    context = mp.get_context("spawn")
    parent, remote = context.Pipe(duplex=False)
    process = context.Process(target=_target or child, args=(body, remote))
    started = False
    reader = None
    try:
        process.start(); started = True; remote.close()
        reader = ResultReader(parent, MAX_RESPONSE + 64)
        while True:
            remaining = deadline - cleanup - now()
            if remaining <= 0 or cancelled():
                raise TimeoutError("inference_timeout")
            if reader.done.wait(min(remaining, 0.05)): break
        result = reader.result()
        if cancelled() or now() >= deadline:
            raise TimeoutError("inference_timeout")
        if "ok" not in result:
            raise ValueError("inference_failed")
        return result["ok"]
    finally:
        cleanup_failed = False
        if started:
            # SIGTERM interrupts the worker's Python wait, allowing bounded_cas
            # to kill AND reap its child before the worker exits. All request
            # descendants share this worker's group for the hard fallback.
            # Do not reap the group leader until killpg: its unreaped PID
            # prevents that group ID from being recycled for another request.
            try: os.kill(process.pid, signal.SIGTERM)
            except ProcessLookupError: pass
            wait([process.sentinel], timeout=max(0, min(cleanup * 0.75, deadline - now())))
            try: os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                try: os.kill(process.pid, signal.SIGKILL)
                except ProcessLookupError: pass
            process.join(timeout=max(0, deadline - now()))
            cleanup_failed = process.is_alive()
            if not cleanup_failed:
                while True:
                    try: pid, _ = os.waitpid(-process.pid, os.WNOHANG)
                    except ChildProcessError: break
                    if pid: continue
                    remaining = deadline - now()
                    if remaining <= 0:
                        cleanup_failed = True; break
                    threading.Event().wait(min(.005, remaining))
            if not cleanup_failed: process.close()
        if reader is not None and not reader.close(deadline - now()):
            cleanup_failed = True
        remote.close(); parent.close()
        if cleanup_failed: raise ProcessCleanupFailed("inference_cleanup_failed")


def read_body(stream, connection, length, deadline):
    """read1 performs at most one socket read, so a drip cannot reset the budget."""
    raw = bytearray()
    while len(raw) < length:
        remaining = deadline - time.monotonic()
        if remaining <= 0: raise TimeoutError("body_timeout")
        connection.settimeout(remaining)
        part = stream.read1(min(65536, length - len(raw)))
        if not part: raise ValueError("truncated_body")
        raw.extend(part)
        if len(raw) > MAX_BODY: raise ValueError("payload_too_large")
    if time.monotonic() >= deadline: raise TimeoutError("body_timeout")
    return raw


def transport_input(envelope):
    """Private v2 transport. No user wallet or Supabase credential in worker.

    Only fixed-cost local inference is supported until a provider-specific
    tokenizer/usage/idempotency adapter can prove the quoted paid upper bound.
    """
    import re
    def integer(value, minimum, maximum):
        return type(value) is int and minimum <= value <= maximum
    if not isinstance(envelope, dict) or set(envelope) != {"version", "attempt_id", "provider", "model", "limits", "input"}:
        raise ValueError("invalid_envelope")
    if type(envelope["version"]) is not int or envelope["version"] != 2 or not isinstance(envelope["attempt_id"], str) or not re.fullmatch(r"[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}", envelope["attempt_id"]):
        raise ValueError("invalid_envelope")
    limits = envelope["limits"]
    if not isinstance(limits, dict) or set(limits) != {"max_input_tokens", "max_output_tokens", "max_attempts"} or not integer(limits["max_input_tokens"], 1, 100000) or not integer(limits["max_output_tokens"], 1, 16000) or not integer(limits["max_attempts"], 1, 3):
        raise ValueError("invalid_limits")
    body = envelope["input"]
    if not isinstance(body, dict) or type(body.get("schema_version")) is not int or body["schema_version"] != 1 or not integer(body.get("purge_epoch"), 0, 2**53-1) or body.get("consent_version") != "study-2026-10-13":
        raise ValueError("invalid_payload")
    if body.get("operation") == "ocr":
        if set(body) != {"schema_version", "operation", "kind", "image", "purge_epoch", "consent_version"} or body.get("kind") not in {"text", "math"} or not isinstance(body.get("image"), str) or not 4 <= len(body["image"]) <= 5592408 or not re.fullmatch(r"[A-Za-z0-9+/]+={0,2}", body["image"]):
            raise ValueError("invalid_payload")
    else:
        # Existing solver/CAS remains tested but its paid HTTP adapter has no
        # verified token accounting yet. Never call it under an invented cap.
        raise ValueError("billing_adapter_unconfigured")
    if envelope["provider"] != "local" or not os.environ.get("WORKER_MODEL_ID") or envelope["model"] != os.environ["WORKER_MODEL_ID"]:
        raise ValueError("billing_adapter_unconfigured")
    return body


class Handler(BaseHTTPRequestHandler):
    body_seconds = BODY_SECONDS
    request_seconds = REQUEST_SECONDS
    execute = staticmethod(execute)

    def log_message(self, *_):
        pass

    def do_POST(self):
        self.close_connection = True
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
        deadline = time.monotonic() + self.request_seconds
        release_slot = True
        try:
            raw = read_body(self.rfile, self.connection, length,
                            min(deadline, time.monotonic() + self.body_seconds))
            body = transport_input(json.loads(raw))
            result = json.dumps(self.execute(body, timeout=deadline - time.monotonic(),
                cancelled=self.disconnected), ensure_ascii=False, allow_nan=False).encode()
            if len(result) > MAX_RESPONSE: raise ValueError("result_too_large")
            remaining = deadline - time.monotonic()
            if remaining <= 0 or self.disconnected(): raise TimeoutError("inference_timeout")
            self.connection.settimeout(remaining)
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Cache-Control", "no-store")
            self.send_header("Content-Length", str(len(result)))
            self.end_headers()
            self.connection.settimeout(max(0, deadline - time.monotonic()))
            self.wfile.write(result)
        except ProcessCleanupFailed:
            # A kernel-level failure to reap is not a free slot. A supervisor
            # must restart this unhealthy worker; requests remain rejected.
            release_slot = False
            self.connection.settimeout(0)
            try: self.send_error(503, "inference_unavailable")
            except (ConnectionError, OSError): pass
        except Exception:
            # An unavailable response is best effort, never another blocking
            # socket timeout after the request's deadline/cleanup budget.
            self.connection.settimeout(0)
            try: self.send_error(503, "inference_unavailable")
            except (ConnectionError, OSError): pass
        finally:
            if release_slot: SLOT.release()

    def disconnected(self):
        readable, _, _ = select.select([self.connection], [], [], 0)
        if not readable: return False
        try: return not self.connection.recv(1, socket.MSG_PEEK | socket.MSG_DONTWAIT)
        except BlockingIOError: return False
        except OSError: return True


if __name__ == "__main__":
    if len(os.environ.get("WORKER_SECRET", "")) < 32:
        raise SystemExit("WORKER_SECRET must contain at least 32 characters")
    ThreadingHTTPServer(("0.0.0.0", int(os.environ.get("PORT", "8080"))), Handler).serve_forever()
