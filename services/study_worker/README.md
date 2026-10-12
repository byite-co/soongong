# Study worker (EXT-01)

Private, bounded inference worker for `study-infer`. No images or problem
text are written to disk. This is an allowlisted pilot, disabled by default;
it does not charge the existing reading quota. Production usage accounting
and held-out Korean handwriting/CSAT evaluations remain release gates.

Run the OCR deployment with Python 3.11+, a separately provisioned environment
from `requirements-ocr.txt`, and `python worker.py`. UniMERNet uses its own
`requirements-math-ocr.txt` environment; route each worker kind explicitly at
the gateway/deployment. The application sends one upright page/crop per call.
An incorrect/unavailable model returns an error; it never substitutes example
text. Model inference has a 50-second process deadline, one concurrent slot,
and a 4 MiB decoded image limit. Size and pixel limits are checked again in
the worker. No user-supplied URLs or Python programs are accepted.

Provision `MODEL_ROOT` with `detection/` and `korean/` Paddle models, or a
UniMERNet `unimernet.yaml` whose tokenizer/checkpoint paths are local. Every
file beneath MODEL_ROOT must appear in `models.lock.json`:

```json
{"revision":"reviewed-model-release","files":{"relative/file":"64-character-sha256"}}
```

Do not use placeholder hashes or allow runtime downloads. Audit the config,
weights/model licences and resolved transitive dependency lock before use.
This repository does not contain model weights, a licence approval for those
weights, or a fabricated accuracy benchmark. The package versions were checked
against PyPI on 2026-10-13 KST. The initial requirements files are deployment
inputs, not a claim that all transitive dependencies have been reproducibly
locked or installed. Pin the final container digest and dependency hashes.

Set a random WORKER_SECRET (at least 32 characters). Use a non-root container,
read-only root filesystem/models, bounded memory/CPU/processes, disabled core
dumps, outbound network denied, and TLS/private ingress. The subprocess
deadline is a resource bound, not a general-purpose code sandbox. The worker
has no Supabase/service-role credentials and suppresses model stdout/stderr.
Do not enable request-body/access logging in an ingress proxy.

Edge configuration: `STUDY_AI_ENABLED=true`, `STUDY_AI_USER_IDS` (comma-separated
explicit pilot users), `STUDY_WORKER_URL=https://<private-host>/infer`, and
`STUDY_MATH_OCR_WORKER_URL=https://<math-ocr-host>/infer`, and
`STUDY_WORKER_SECRET`. Missing configuration fails closed. No secrets belong in
the Flutter environment. Deploy Edge and the worker explicitly; committing
this code does not deploy it. Consent and purge epoch are rechecked after
inference. Results remain local-only confirmed drafts, included in JSON export
and local purge/account wipe; S13 synchronization is not implied.

Tests without model downloads: `python -m unittest discover -s services/study_worker`.
Tests exercise image boundaries and manifest integrity, not OCR accuracy.
Reference API: UniMERNet `demo.py` at `5a2c80d96b1d2dba447ff18d873e5fb73ba03c35`;
PaddleOCR API via its pinned package. No upstream assets or datasets copied.

## EXT-02 math solver

The `solve` operation uses a separately deployed worker provisioned with
`requirements-solver.lock` (`pip install --require-hashes -r ...`). Set
`STUDY_SOLVER_WORKER_URL` on Edge, and `MATH_MODEL_URL` (HTTPS chat-completions
endpoint), `MATH_MODEL_ID`, `MATH_MODEL_KEY` on that private worker. Choose and
pin the actual math model/weights and inference container before rollout.
The code uses the structured math-tool loop as a reference from Qwen-Agent;
it does not install or call its general PythonExecutor.

Only a small arithmetic AST reaches SymPy. CAS children have memory/CPU/wall
limits and no inherited API secrets. No generated code is executed. Matching
an optional user-supplied numeric reference through Math-Verify is distinct
from verifying a complete solution or establishing CSAT accuracy. The gold is
withheld from the model request. With no reference the result is inconclusive.
The retained solution is attached to the exact confirmed document revision;
editing that document clears the previous solution. Both transfer and save
require explicit user actions. No automatic grading/wrong-item creation.
