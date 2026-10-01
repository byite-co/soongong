// reading-worker (D16) — job function (x-job-secret). Loops: claim (atomic SQL:
// lease 3 min, attempts+1, FOR UPDATE SKIP LOCKED) → engine → reading_finish →
// delete photos now. The engine call is a STUB returning 501 until S16 wires the
// vendor; every claimed job therefore ends as failed/engine_unavailable.
// Started by pg_net from reading_submit and by the 1-minute cron sweep.
import { requireJobSecret } from "../_shared/auth.ts";
import { rpc } from "../_shared/db.ts";
import { json } from "../_shared/http.ts";
import { deletePhotosNow, type FinishResult } from "../_shared/reading.ts";

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

export async function runOnce(engine: (j: ClaimedJob) => Promise<EngineResult> = callEngine, maxJobs = 20): Promise<{ processed: string[] }> {
  const processed: string[] = [];
  for (let i = 0; i < maxJobs; i++) {
    const job = await rpc<ClaimedJob | null>("reading_claim_job", {});
    if (!job) break;
    let fin: FinishResult;
    try {
      const r = await engine(job);
      fin = r.ok
        ? await rpc<FinishResult>("reading_finish", { p_request_id: job.request_id, p_outcome: "done", p_result: r.result ?? null, p_fail_reason: null })
        : await rpc<FinishResult>("reading_finish", { p_request_id: job.request_id, p_outcome: "failed", p_result: null, p_fail_reason: r.reason ?? `engine_${r.status}` });
    } catch (_e) {
      fin = await rpc<FinishResult>("reading_finish", { p_request_id: job.request_id, p_outcome: "failed", p_result: null, p_fail_reason: "engine_error" });
    }
    if (fin.outcome !== "noop") await deletePhotosNow(job.request_id, fin.object_paths);
    processed.push(job.request_id);
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
