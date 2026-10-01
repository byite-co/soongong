// photo-delete-runner (D14) — job function (x-job-secret), every 5 minutes via
// pg_cron/pg_net. Claims `pending` queue rows (next_at ≤ now, backoff on
// failure), deletes the objects, marks done. Safety net: objects older than
// 24 h under any user prefix are removed even without a queue row.
import { requireJobSecret } from "../_shared/auth.ts";
import { rpc, serviceClient } from "../_shared/db.ts";
import { json } from "../_shared/http.ts";
import { deleteObjects, PHOTO_BUCKET } from "../_shared/storage.ts";

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

/** 24-hour residue purge: best effort, bounded per run. */
export async function purgeStale(maxUsers = 20): Promise<number> {
  const storage = serviceClient().storage.from(PHOTO_BUCKET);
  const { data: users } = await storage.list("", { limit: maxUsers, sortBy: { column: "created_at", order: "asc" } });
  let removed = 0;
  const cutoff = Date.now() - 24 * 3600 * 1000;
  for (const u of users ?? []) {
    const { data: reqs } = await storage.list(u.name, { limit: 50 });
    for (const r of reqs ?? []) {
      const { data: objs } = await storage.list(`${u.name}/${r.name}`, { limit: 50 });
      const old = (objs ?? []).filter((o) => o.created_at && Date.parse(o.created_at) < cutoff).map((o) => `${u.name}/${r.name}/${o.name}`);
      if (old.length) {
        const left = await deleteObjects(old);
        removed += old.length - left.length;
      }
    }
  }
  return removed;
}

export async function handle(req: Request): Promise<Response> {
  requireJobSecret(req);
  const q = await runQueue();
  let stale = 0;
  try { stale = await purgeStale(); } catch (_e) { stale = -1; }
  return json({ ...q, stale_removed: stale });
}

if (import.meta.main) {
  const { serve } = await import("../_shared/http.ts");
  serve(handle);
}
