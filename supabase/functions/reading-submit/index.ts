// reading-submit (D16) — authenticated. Body: {request_id, subject_id, range_text,
// origin, session_id?, planner_item_id?, object_paths:[...], created_at?, client_updated_at?}
// Photos are uploaded by the app to `reading-photos/<uid>/<request_id>/pN.jpg` first.
// Outcomes (docs/reading-api.md): accepted · request_deleted(410) · payload_mismatch(409)
// · invalid_state(409) · active_exists(409) · quota_exhausted(409) · not_entitled(403)
// · consent_required(403) · invalid_payload(400)
import { requireUser } from "../_shared/auth.ts";
import { outcomeResponse, rpc } from "../_shared/db.ts";
import { HttpError, json, methodNotAllowed, readJson, requireString } from "../_shared/http.ts";

export async function handle(req: Request): Promise<Response> {
  const mna = methodNotAllowed(req);
  if (mna) return mna;
  const caller = await requireUser(req);
  const body = await readJson(req);
  const requestId = requireString(body, "request_id", 36);
  const paths = body.object_paths;
  if (!Array.isArray(paths) || paths.length === 0 || paths.length > 20 || !paths.every((p) => typeof p === "string" && p.length <= 512)) {
    throw new HttpError(400, "invalid_payload", "object_paths");
  }
  const payload = {
    subject_id: body.subject_id,
    range_text: body.range_text,
    origin: body.origin,
    session_id: body.session_id ?? null,
    planner_item_id: body.planner_item_id ?? null,
    object_paths: paths,
    created_at: body.created_at ?? null,
    client_updated_at: body.client_updated_at ?? null,
  };
  const out = await rpc<Record<string, unknown>>("reading_submit", {
    p_user: caller.userId,
    p_request_id: requestId,
    p_payload: payload,
    p_device_id: caller.deviceId,
  });
  const { status, body: res } = outcomeResponse(out);
  return json(res, status);
}

if (import.meta.main) {
  const { serve } = await import("../_shared/http.ts");
  serve(handle);
}
