// photo-delete-runner (D14) — job function (x-job-secret), every 5 minutes via
// pg_cron/pg_net while the queue has due rows. Claims `pending` queue rows
// (next_at ≤ now, backoff on failure), deletes the objects, marks done.
// The 24-hour residue safety net is NOT here any more: photo_residue_run()
// (0009, daily cron) scans storage.objects in SQL and feeds this same queue.
import { requireJobSecret } from "../_shared/auth.ts";
import { rpc } from "../_shared/db.ts";
import { json } from "../_shared/http.ts";
import { deleteObjects } from "../_shared/storage.ts";

interface QueueRow { id: number; request_id: string | null; bucket_path: string; attempts: number }

export async function runQueue(limit = 100): Promise<{ done: number; failed: number }> {
  const rows = await rpc<QueueRow[]>("photo_delete_claim", { p_limit: limit });
  if (rows.length === 0) return { done: 0, failed: 0 };
  const stillThere = new Set(await deleteObjects(rows.map((r) => r.bucket_path)));
  const okIds = rows.filter((r) => !stillThere.has(r.bucket_path)).map((r) => r.id);
  const failIds = rows.filter((r) => stillThere.has(r.bucket_path)).map((r) => r.id);
  if (okIds.length) await rpc("photo_delete_mark", { p_ids: okIds, p_ok: true });
  if (failIds.length) await rpc("photo_delete_mark", { p_ids: failIds, p_ok: false });
  return { done: okIds.length, failed: failIds.length };
}

export async function handle(req: Request): Promise<Response> {
  requireJobSecret(req);
  return json(await runQueue());
}

if (import.meta.main) {
  const { serve } = await import("../_shared/http.ts");
  serve(handle);
}
