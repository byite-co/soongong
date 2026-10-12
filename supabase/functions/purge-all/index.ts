// purge-all (D2 · [S09d]) — authenticated. Cancels active readings, physically
// deletes the user's sync rows + receipts, purge_epoch+1, deletes photos now.
// Body {request_id?: uuid}: the same id is replayed by the SQL layer without a
// second purge (a client whose connection died re-sends the same id and
// converges; `profiles.purge_request_id` tells it whether the id was served).
// → {epoch, replayed}. Quota / subscription / approvals / profile stay.
import { requireUser } from "../_shared/auth.ts";
import { rpc } from "../_shared/db.ts";
import { HttpError, json, methodNotAllowed, readJson } from "../_shared/http.ts";
import { deleteObjects } from "../_shared/storage.ts";

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export type PurgeResult = { epoch: number; object_paths: string[]; replayed?: boolean };

/** The request id from the body, or null for a body without one (legacy caller). */
export function requestIdOf(body: Record<string, unknown>): string | null {
  const v = body.request_id;
  if (v === undefined || v === null) return null;
  if (typeof v !== "string" || !UUID.test(v)) throw new HttpError(400, "invalid_field", "request_id");
  return v.toLowerCase();
}

export async function purgeAll(
  userId: string,
  requestId: string | null,
  call: <T>(name: string, args: Record<string, unknown>) => Promise<T> = rpc,
  del: (paths: string[]) => Promise<string[]> = deleteObjects,
): Promise<{ epoch: number; replayed: boolean }> {
  const out = await call<PurgeResult>("purge_all", { p_user: userId, p_request_id: requestId });
  if (out.object_paths?.length) await del(out.object_paths); // queue rows stay pending until the runner confirms
  return { epoch: out.epoch, replayed: out.replayed === true };
}

export async function handle(req: Request): Promise<Response> {
  const mna = methodNotAllowed(req);
  if (mna) return mna;
  const caller = await requireUser(req);
  const text = await req.clone().text();
  const body = text.trim().length === 0 ? {} : await readJson(req);
  const requestId = requestIdOf(body);
  return json(await purgeAll(caller.userId, requestId));
}

if (import.meta.main) {
  const { serve } = await import("../_shared/http.ts");
  serve(handle);
}
