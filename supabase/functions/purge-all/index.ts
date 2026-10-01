// purge-all (D2) — authenticated. Cancels active readings, physically deletes
// the user's sync rows + receipts, purge_epoch+1, deletes photos now.
// → {epoch}. Quota / subscription / approvals / profile stay.
import { requireUser } from "../_shared/auth.ts";
import { rpc } from "../_shared/db.ts";
import { json, methodNotAllowed } from "../_shared/http.ts";
import { deleteObjects } from "../_shared/storage.ts";

export async function handle(req: Request): Promise<Response> {
  const mna = methodNotAllowed(req);
  if (mna) return mna;
  const caller = await requireUser(req);
  const out = await rpc<{ epoch: number; object_paths: string[] }>("purge_all", { p_user: caller.userId });
  if (out.object_paths?.length) await deleteObjects(out.object_paths); // queue rows stay pending until the runner confirms
  return json({ epoch: out.epoch });
}

if (import.meta.main) {
  const { serve } = await import("../_shared/http.ts");
  serve(handle);
}
