// reading-discard (D8) — authenticated. {request_id} → {outcome:'discarded'} |
// {outcome:'not_unsaved', status} | 404 · 410. result_json is deleted server-side.
import { requireUser } from "../_shared/auth.ts";
import { outcomeResponse, rpc } from "../_shared/db.ts";
import { json, methodNotAllowed, readJson, requireString } from "../_shared/http.ts";

export async function handle(req: Request): Promise<Response> {
  const mna = methodNotAllowed(req);
  if (mna) return mna;
  const caller = await requireUser(req);
  const body = await readJson(req);
  const requestId = requireString(body, "request_id", 36);
  const out = await rpc<Record<string, unknown>>("reading_discard", { p_user: caller.userId, p_request_id: requestId });
  const { status, body: res } = outcomeResponse(out);
  return json(res, status);
}

if (import.meta.main) {
  const { serve } = await import("../_shared/http.ts");
  serve(handle);
}
