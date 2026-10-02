// reading-worker (D16) — job function (x-job-secret). Loops: claim (atomic SQL:
// lease 3 min, attempts+1, FOR UPDATE SKIP LOCKED, keyed by (user_id, request_id))
// → engine → reading_finish(user_id, request_id, …) → delete photos now. The engine
// call is a STUB returning 501 until S16 wires the vendor; every claimed job
// therefore ends as failed/engine_unavailable.
// Started by pg_net from reading_submit and by the 1-minute cron sweep.
import { requireJobSecret } from "../_shared/auth.ts";
import { rpc } from "../_shared/db.ts";
import { json } from "../_shared/http.ts";
import { deletePhotosNow, type FinishResult, type RpcCall } from "../_shared/reading.ts";

export interface ClaimedJob {
  request_id: string;
  user_id: string;
  attempts: number;
  object_paths: string[];
  subject_id: string | null;
  range_text: string | null;
}

export interface EngineResult {
  ok: boolean;
  status: number;
  result?: Record<string, unknown>;
  reason?: string;
}

/** S16 replaces this: call the reading vendor with the photo objects and return result_json. */
export function callEngine(_job: ClaimedJob): Promise<EngineResult> {
  return Promise.resolve({ ok: false, status: 501, reason: "engine_unavailable" });
}

export async function runOnce(
  engine: (j: ClaimedJob) => Promise<EngineResult> = callEngine,
  maxJobs = 20,
  call: RpcCall = rpc,
  remove?: (paths: string[]) => Promise<string[]>,
): Promise<{ processed: { user_id: string; request_id: string }[] }> {
  const processed: { user_id: string; request_id: string }[] = [];
  for (let i = 0; i < maxJobs; i++) {
    const job = await call<ClaimedJob | null>("reading_claim_job", {});
    if (!job) break;
    const finish = (outcome: "done" | "failed", result: Record<string, unknown> | null, reason: string | null) =>
      call<FinishResult>("reading_finish", {
        p_user: job.user_id,
        p_request_id: job.request_id,
        p_outcome: outcome,
        p_result: result,
        p_fail_reason: reason,
      });
    let fin: FinishResult;
    try {
      const r = await engine(job);
      fin = r.ok ? await finish("done", r.result ?? null, null) : await finish("failed", null, r.reason ?? `engine_${r.status}`);
    } catch (_e) {
      fin = await finish("failed", null, "engine_error");
    }
    if (fin.outcome !== "noop") await deletePhotosNow(job.user_id, job.request_id, fin.object_paths, call, remove);
    processed.push({ user_id: job.user_id, request_id: job.request_id });
  }
  return { processed };
}

export async function handle(req: Request): Promise<Response> {
  requireJobSecret(req);
  const out = await runOnce();
  return json(out);
}

if (import.meta.main) {
  const { serve } = await import("../_shared/http.ts");
  serve(handle);
}
