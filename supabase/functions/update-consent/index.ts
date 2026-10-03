// update-consent — authenticated. {consent_version, granted:boolean} → consent ②
// (external reading transfer) grant / revoke on profiles.
import { requireUser } from "../_shared/auth.ts";
import { rpc } from "../_shared/db.ts";
import { HttpError, json, methodNotAllowed, optionalString, readJson } from "../_shared/http.ts";

export async function handle(req: Request): Promise<Response> {
  const mna = methodNotAllowed(req);
  if (mna) return mna;
  const caller = await requireUser(req);
  const body = await readJson(req);
  if (typeof body.granted !== "boolean") throw new HttpError(400, "invalid_field", "granted");
  const version = optionalString(body, "consent_version", 32);
  if (body.granted && !version) throw new HttpError(400, "invalid_field", "consent_version");
  const profile = await rpc<Record<string, unknown>>("update_consent", {
    p_user: caller.userId,
    p_version: version,
    p_granted: body.granted,
  });
  return json({ profile });
}

if (import.meta.main) {
  const { serve } = await import("../_shared/http.ts");
  serve(handle);
}
