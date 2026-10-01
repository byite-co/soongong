// reading-status — authenticated. {request_id} → {outcome:'ok', status, server_version,
// completed_at, result_json (done_unsaved·saved), marks_json (saved), fail_reason, quota}
// · 404 not_found · 410 request_deleted. S10 polls this (2 s → 5 s after 60 s).
import { requireUser } from "../_shared/auth.ts";
import { outcomeResponse, rpc } from "../_shared/db.ts";
import { json, methodNotAllowed, readJson, requireString } from "../_shared/http.ts";

export async function handle(req: Request): Promise<Response> {
  const mna = methodNotAllowed(req);
  if (mna) return mna;
  const caller = await requireUser(req);
  const body = await readJson(req);
  const requestId = requireString(body, "request_id", 36);
  const out = await rpc<Record<string, unknown>>("reading_status", { p_user: caller.userId, p_request_id: requestId });
  const { status, body: res } = outcomeResponse(out);
  return json(res, status);
}

if (import.meta.main) {
  const { serve } = await import("../_shared/http.ts");
  serve(handle);
}
