// reading-cancel — authenticated. {request_id} → final state:
// {outcome:'cancelled'} | {outcome:'already_done', result} | {outcome:'already_failed', status}
// A cancelled request's photos are deleted immediately (queue row → done).
import { requireUser } from "../_shared/auth.ts";
import { rpc } from "../_shared/db.ts";
import { HttpError, json, methodNotAllowed, readJson, requireString } from "../_shared/http.ts";
import { deletePhotosNow, type FinishResult } from "../_shared/reading.ts";

export async function handle(req: Request): Promise<Response> {
  const mna = methodNotAllowed(req);
  if (mna) return mna;
  const caller = await requireUser(req);
  const body = await readJson(req);
  const requestId = requireString(body, "request_id", 36);
  // ownership check through reading_status (404 / 410 propagate)
  const st = await rpc<Record<string, unknown>>("reading_status", { p_user: caller.userId, p_request_id: requestId });
  if (st.outcome === "not_found") throw new HttpError(404, "not_found");
  if (st.outcome === "request_deleted") throw new HttpError(410, "request_deleted");
  const fin = await rpc<FinishResult>("reading_finish", { p_request_id: requestId, p_outcome: "cancelled", p_result: null, p_fail_reason: "user_cancel" });
  if (fin.outcome === "cancelled") {
    await deletePhotosNow(requestId, fin.object_paths);
    return json({ outcome: "cancelled" });
  }
  const status = fin.status ?? (st.status as string);
  if (status === "done_unsaved" || status === "saved") {
    const result = fin.request?.result_json ?? st.result_json ?? null;
    return json({ outcome: "already_done", result, status });
  }
  return json({ outcome: "already_failed", status });
}

if (import.meta.main) {
  const { serve } = await import("../_shared/http.ts");
  serve(handle);
}
