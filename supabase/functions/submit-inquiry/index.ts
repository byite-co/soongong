// submit-inquiry — authenticated. {body (≤ 2000), reply_email?} → {id, created_at}.
// 10 per day per user (SQL). Users cannot read inquiries back (D24).
import { requireUser } from "../_shared/auth.ts";
import { rpc } from "../_shared/db.ts";
import { json, methodNotAllowed, optionalString, readJson, requireString } from "../_shared/http.ts";

export async function handle(req: Request): Promise<Response> {
  const mna = methodNotAllowed(req);
  if (mna) return mna;
  const caller = await requireUser(req);
  const body = await readJson(req);
  const text = requireString(body, "body", 2000);
  const replyEmail = optionalString(body, "reply_email", 320);
  const result = await rpc<Record<string, unknown>>("submit_inquiry", {
    p_user: caller.userId,
    p_body: text,
    p_reply_email: replyEmail,
  });
  return json(result, 201);
}

if (import.meta.main) {
  const { serve } = await import("../_shared/http.ts");
  serve(handle);
}
