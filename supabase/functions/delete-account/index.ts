// delete-account (D5) — authenticated. Server data (incl. tombstones, receipts,
// profile, approvals, subscription_*, reading_quota, activity_days) → photos →
// auth.admin.deleteUser. metrics_weekly (anonymous) stays. → {deleted:true}
import { requireUser } from "../_shared/auth.ts";
import { rpc, serviceClient } from "../_shared/db.ts";
import { HttpError, json, methodNotAllowed } from "../_shared/http.ts";
import { deleteObjects, PHOTO_BUCKET } from "../_shared/storage.ts";

export async function handle(req: Request): Promise<Response> {
  const mna = methodNotAllowed(req);
  if (mna) return mna;
  const caller = await requireUser(req);
  const out = await rpc<{ object_paths: string[] }>("delete_account_data", { p_user: caller.userId });
  if (out.object_paths?.length) await deleteObjects(out.object_paths);
  // whole user prefix, best effort
  try {
    const storage = serviceClient().storage.from(PHOTO_BUCKET);
    const { data: reqs } = await storage.list(caller.userId, { limit: 100 });
    for (const r of reqs ?? []) {
      const { data: objs } = await storage.list(`${caller.userId}/${r.name}`, { limit: 100 });
      const paths = (objs ?? []).map((o) => `${caller.userId}/${r.name}/${o.name}`);
      if (paths.length) await deleteObjects(paths);
    }
  } catch (_e) { /* runner + 24 h purge cover leftovers */ }
  const { error } = await serviceClient().auth.admin.deleteUser(caller.userId);
  if (error) throw new HttpError(500, "auth_delete_failed");
  return json({ deleted: true });
}

if (import.meta.main) {
  const { serve } = await import("../_shared/http.ts");
  serve(handle);
}
