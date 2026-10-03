// reading-save (D16) — authenticated. {request_id, marks:[ConfirmedMark], items:[WrongItemDraft]}
// → {outcome:'saved', marks, items, entries} | {outcome:'already_saved', marks, items, entries}
// | {outcome:'not_unsaved', status} | 404 · 410 · 400 invalid_payload · 409 id_reused
import { requireUser } from "../_shared/auth.ts";
import { outcomeResponse, rpc } from "../_shared/db.ts";
import { HttpError, json, methodNotAllowed, readJson, requireString } from "../_shared/http.ts";

export async function handle(req: Request): Promise<Response> {
  const mna = methodNotAllowed(req);
  if (mna) return mna;
  const caller = await requireUser(req);
  const body = await readJson(req);
  const requestId = requireString(body, "request_id", 36);
  if (!Array.isArray(body.marks) || !Array.isArray(body.items)) throw new HttpError(400, "invalid_payload", "marks/items");
  if (body.marks.length > 2000 || body.items.length > 2000) throw new HttpError(400, "invalid_payload", "too_many");
  const out = await rpc<Record<string, unknown>>("reading_save", {
    p_user: caller.userId,
    p_request_id: requestId,
    p_marks: body.marks,
    p_items: body.items,
    p_device_id: caller.deviceId,
  });
  const { status, body: res } = outcomeResponse(out);
  return json(res, status);
}

if (import.meta.main) {
  const { serve } = await import("../_shared/http.ts");
  serve(handle);
}
