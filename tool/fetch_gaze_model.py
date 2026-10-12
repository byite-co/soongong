"""Fetch the versioned Google model and verify before adding it to app assets.

Build-time network only. The on-device gaze path never downloads or uploads
camera data. The large generated asset is intentionally not committed.
"""
from pathlib import Path
import hashlib
import urllib.request

URL = "https://storage.googleapis.com/mediapipe-models/face_landmarker/face_landmarker/float16/1/face_landmarker.task"
SHA256 = "64184e229b263107bc2b804c6625db1341ff2bb731874b0bcc2fe6544e0bc9ff"


def main():
    path = Path(__file__).resolve().parent.parent / "assets/models/face_landmarker.task"
    if path.exists() and hashlib.sha256(path.read_bytes()).hexdigest() == SHA256:
        return
    with urllib.request.urlopen(URL, timeout=45) as response:
        content = response.read(4_000_001)
    if len(content) > 4_000_000 or hashlib.sha256(content).hexdigest() != SHA256:
        raise SystemExit("Gaze model integrity mismatch")
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_suffix(".part")
    temporary.write_bytes(content)
    temporary.replace(path)


if __name__ == "__main__": main()
