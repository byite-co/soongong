// complete-signup (D6 step 5) — authenticated. {consent_version} → checks
// signup_approvals.age_verified for auth.uid() → profiles (idempotent) + consent ①.
// No approval → 403 not_approved.
import { requireUser } from "../_shared/auth.ts";
import { rpc } from "../_shared/db.ts";
import { json, methodNotAllowed, readJson, requireString } from "../_shared/http.ts";
import { logger } from "../_shared/log.ts";

export async function handle(req: Request): Promise<Response> {
  const mna = methodNotAllowed(req);
  if (mna) return mna;
  const requestId = req.headers.get("x-request-id") ?? crypto.randomUUID();
  const log = logger(requestId);
  const caller = await requireUser(req);
  const body = await readJson(req);
  const version = requireString(body, "consent_version", 32);
  const profile = await rpc<Record<string, unknown>>("complete_signup", { p_user: caller.userId, p_consent_version: version });
  log.info("complete-signup outcome=ok");
  return json({ profile });
}

if (import.meta.main) {
  const { serve } = await import("../_shared/http.ts");
  serve(handle);
}
