# Study worker (EXT-01)

Private, bounded inference worker for `study-infer`. No images or problem
text are written to disk. This is an allowlisted pilot, disabled by default;
it does not charge the existing reading quota. Production usage accounting
and held-out Korean handwriting/CSAT evaluations remain release gates.

Run the OCR deployment on Linux with Python 3.11+, a separately provisioned environment
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

## Request lifetime and calculation failures (EXT-FIX-01)

Edge has one 55-second budget beginning at handler entry, including Auth,
body reception, profile reads, worker response and the final Auth/epoch check.
Its abort signal reaches the pinned Auth SDK's fetch, PostgREST and worker
fetch. A pre-aborted request performs no external call. Timeout/cancellation
uses the existing `503 engine_unavailable` contract. Stream cancellation is
requested and the reader lock is released; an uncooperative custom stream's
pending `cancel()` promise is not awaited forever. This cannot forcibly finish
arbitrary third-party cleanup hooks; the production I/O owners receive abort.

The worker allows at most 10 seconds for the whole body, even if bytes keep
arriving. The 50-second request budget begins with slot acquisition and covers
body reception, inference and process cleanup. Inference receives only the
remaining budget, reserving up to one second of it for cleanup. Peer EOF or
timeout cancels that request. The worker first interrupts its Python wait so
CAS can be killed and reaped, then kills its own process group as a fallback.
CAS stays in that group, rather than creating an escaping session. No process
group belonging to another request is targeted. The Linux server is a child
subreaper and reaps adopted descendants only from that request's group after
a hard kill; this does not depend on the container's PID 1 reaping orphans.
Pipe responses use bounded JSON reads in an owned reader thread, so a partial
pipe frame cannot block deadline/cancellation monitoring. The reader must also
finish before the slot is released. A kernel failure to reap a killed worker
or finish its reader keeps admission closed until a supervisor restart; it is never
reported as a reusable slot or successful inference.

The body deadline starts after HTTP headers and authorization have been read.
Absolute header/connection limits, TLS and connection-count limits remain the
private ingress/server deployment's responsibility; no such deployment has
been verified by these tests. Worker egress must deny OCR model downloads;
the solver deployment separately allows only its configured model endpoint.

CAS outcomes internally distinguish values from timeout/unavailable failures.
Any requested calculation failure stops remaining tools, a second model call
and answer verification, returning the existing non-success worker/Edge path
(`503`). A failure of the independent numeric verification itself remains
`inconclusive`. Successful numeric-reference meanings, two-model/two-tool
limits and the public response schema are unchanged. CPU 4 seconds, address
space 768 MiB, wall wait 6 seconds, no core dumps and cleared CAS environment
remain enforced. Tests call the actual handler/executor/CAS with synthetic
inputs; short injected clocks/deadlines are not deployment ingress evidence.
