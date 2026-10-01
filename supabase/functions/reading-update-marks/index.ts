// reading-update-marks (D16, saved only, online) — authenticated.
// {request_id, marks:[ConfirmedMark], entries:[ReviewEntryDraft]} →
// {outcome:'updated', marks, items, entries} | {outcome:'not_saved', status} |
// 400 invalid_payload · 409 id_reused
import { requireUser } from "../_shared/auth.ts";
import { outcomeResponse, rpc } from "../_shared/db.ts";
import { HttpError, json, methodNotAllowed, readJson, requireString } from "../_shared/http.ts";

export async function handle(req: Request): Promise<Response> {
  const mna = methodNotAllowed(req);
  if (mna) return mna;
  const caller = await requireUser(req);
  const body = await readJson(req);
  const requestId = requireString(body, "request_id", 36);
  if (!Array.isArray(body.marks)) throw new HttpError(400, "invalid_payload", "marks");
  const entries = body.entries ?? [];
  if (!Array.isArray(entries)) throw new HttpError(400, "invalid_payload", "entries");
  const out = await rpc<Record<string, unknown>>("reading_update_marks", {
    p_user: caller.userId,
    p_request_id: requestId,
    p_marks: body.marks,
    p_entries: entries,
    p_device_id: caller.deviceId,
  });
  const { status, body: res } = outcomeResponse(out);
  return json(res, status);
}

if (import.meta.main) {
  const { serve } = await import("../_shared/http.ts");
  serve(handle);
}
