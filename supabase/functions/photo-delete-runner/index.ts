// photo-delete-runner (D14) — job function (x-job-secret), every 5 minutes via
// pg_cron/pg_net while the queue has due rows. Claims `pending` queue rows
// (next_at ≤ now, backoff on failure) 500 at a time, deletes the objects, marks
// done, and repeats within the same run (≤ 10 rounds) while the queue keeps
// returning full batches — a backlog drains within the hour.
// The 24-hour residue safety net is NOT here: photo_residue_run() (0010, hourly
// cron, 22 h candidates) scans storage.objects in SQL and feeds this same queue.
import { requireJobSecret } from "../_shared/auth.ts";
import { rpc } from "../_shared/db.ts";
import { json } from "../_shared/http.ts";
import { type RpcCall } from "../_shared/reading.ts";
import { deleteObjects } from "../_shared/storage.ts";

interface QueueRow { id: number; user_id: string | null; request_id: string | null; bucket_path: string; attempts: number }

export const BATCH = 500;
export const MAX_ROUNDS = 10;

export async function runQueue(
  limit = BATCH,
  maxRounds = MAX_ROUNDS,
  call: RpcCall = rpc,
  remove: (paths: string[]) => Promise<string[]> = deleteObjects,
): Promise<{ done: number; failed: number; rounds: number }> {
  let done = 0, failed = 0, rounds = 0;
  for (let i = 0; i < maxRounds; i++) {
    const rows = await call<QueueRow[]>("photo_delete_claim", { p_limit: limit });
    if (rows.length === 0) break;
    rounds++;
    const stillThere = new Set(await remove(rows.map((r) => r.bucket_path)));
    const okIds = rows.filter((r) => !stillThere.has(r.bucket_path)).map((r) => r.id);
    const failIds = rows.filter((r) => stillThere.has(r.bucket_path)).map((r) => r.id);
    if (okIds.length) await call("photo_delete_mark", { p_ids: okIds, p_ok: true });
    if (failIds.length) await call("photo_delete_mark", { p_ids: failIds, p_ok: false });
    done += okIds.length;
    failed += failIds.length;
    if (rows.length < limit) break;
  }
  return { done, failed, rounds };
}

export async function handle(req: Request): Promise<Response> {
  requireJobSecret(req);
  return json(await runQueue());
}

if (import.meta.main) {
  const { serve } = await import("../_shared/http.ts");
  serve(handle);
}
