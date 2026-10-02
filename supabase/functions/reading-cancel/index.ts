// reading-cancel — authenticated. {request_id} → final state:
// {outcome:'cancelled'} | {outcome:'already_done', result} | {outcome:'already_failed', status}
// Every SQL call is keyed by (caller's user_id, request_id): another account's
// request with the same id is simply not_found (D16, 0010).
// A cancelled request's photos are deleted immediately (queue row → done).
import { requireUser } from "../_shared/auth.ts";
import { rpc } from "../_shared/db.ts";
import { HttpError, json, methodNotAllowed, readJson, requireString } from "../_shared/http.ts";
import { deletePhotosNow, type FinishResult, type RpcCall } from "../_shared/reading.ts";

export async function cancel(
  userId: string,
  requestId: string,
  call: RpcCall = rpc,
  remove?: (paths: string[]) => Promise<string[]>,
): Promise<Record<string, unknown>> {
  // ownership check through reading_status (404 / 410 propagate)
  const st = await call<Record<string, unknown>>("reading_status", { p_user: userId, p_request_id: requestId });
  if (st.outcome === "not_found") throw new HttpError(404, "not_found");
  if (st.outcome === "request_deleted") throw new HttpError(410, "request_deleted");
  const fin = await call<FinishResult>("reading_finish", {
    p_user: userId,
    p_request_id: requestId,
    p_outcome: "cancelled",
    p_result: null,
    p_fail_reason: "user_cancel",
  });
  if (fin.outcome === "cancelled") {
    await deletePhotosNow(userId, requestId, fin.object_paths, call, remove);
    return { outcome: "cancelled" };
  }
  const status = fin.status ?? (st.status as string);
  if (status === "done_unsaved" || status === "saved") {
    const result = fin.request?.result_json ?? st.result_json ?? null;
    return { outcome: "already_done", result, status };
  }
  return { outcome: "already_failed", status };
}

export async function handle(req: Request): Promise<Response> {
  const mna = methodNotAllowed(req);
  if (mna) return mna;
  const caller = await requireUser(req);
  const body = await readJson(req);
  const requestId = requireString(body, "request_id", 36);
  return json(await cancel(caller.userId, requestId));
}

if (import.meta.main) {
  const { serve } = await import("../_shared/http.ts");
  serve(handle);
}
