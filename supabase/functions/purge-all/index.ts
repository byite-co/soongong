// purge-all (D2 · [S09d] · [S09e]) — authenticated. Cancels active readings,
// physically deletes the user's sync rows + receipts, purge_epoch+1, deletes
// photos now. Body {request_id?: uuid, expected_epoch?: int}: the SQL layer
// keeps a receipt per (account, request id) — the same id is replayed without
// a second purge (whatever ran in between), and a request whose expected
// epoch is no longer the account's epoch is superseded (nothing deleted,
// recorded). → {epoch, replayed, superseded}, where epoch is the account's
// CURRENT epoch (a client converges forward). Quota / subscription /
// approvals / profile stay.
import { requireUser } from "../_shared/auth.ts";
import { rpc } from "../_shared/db.ts";
import { HttpError, json, methodNotAllowed, readJson } from "../_shared/http.ts";
import { deleteObjects } from "../_shared/storage.ts";

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export type PurgeResult = { epoch: number; object_paths: string[]; replayed?: boolean; superseded?: boolean };
export type PurgeAnswer = { epoch: number; replayed: boolean; superseded: boolean };

/** The request id from the body, or null for a body without one (legacy caller). */
export function requestIdOf(body: Record<string, unknown>): string | null {
  const v = body.request_id;
  if (v === undefined || v === null) return null;
  if (typeof v !== "string" || !UUID.test(v)) throw new HttpError(400, "invalid_field", "request_id");
  return v.toLowerCase();
}

/** The epoch the client formed the request against, or null when not given. */
export function expectedEpochOf(body: Record<string, unknown>): number | null {
  const v = body.expected_epoch;
  if (v === undefined || v === null) return null;
  if (typeof v !== "number" || !Number.isInteger(v) || v < 0) throw new HttpError(400, "invalid_field", "expected_epoch");
  return v;
}

export async function purgeAll(
  userId: string,
  requestId: string | null,
  expectedEpoch: number | null,
  call: <T>(name: string, args: Record<string, unknown>) => Promise<T> = rpc,
  del: (paths: string[]) => Promise<string[]> = deleteObjects,
): Promise<PurgeAnswer> {
  const out = await call<PurgeResult>("purge_all", { p_user: userId, p_request_id: requestId, p_expected_epoch: expectedEpoch });
  if (out.object_paths?.length) await del(out.object_paths); // queue rows stay pending until the runner confirms
  return { epoch: out.epoch, replayed: out.replayed === true, superseded: out.superseded === true };
}

export async function handle(req: Request): Promise<Response> {
  const mna = methodNotAllowed(req);
  if (mna) return mna;
  const caller = await requireUser(req);
  const text = await req.clone().text();
  const body = text.trim().length === 0 ? {} : await readJson(req);
  return json(await purgeAll(caller.userId, requestIdOf(body), expectedEpochOf(body)));
}

if (import.meta.main) {
  const { serve } = await import("../_shared/http.ts");
  serve(handle);
}
