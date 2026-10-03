// revenuecat-webhook (D18) — RevenueCat → Supabase. RevenueCat does not sign
// payloads; it sends the Authorization header value configured in its dashboard,
// compared here in constant time (REVENUECAT_WEBHOOK_AUTH). Then
// revenuecat_apply_event(): event_id dedupe · stale (older event_timestamp) skip ·
// state update · status by entitlement_status(). Always 200 once stored so
// RevenueCat does not retry forever; 401 on a bad header.
import { timingSafeEqual } from "../_shared/auth.ts";
import { rpc } from "../_shared/db.ts";
import { env } from "../_shared/env.ts";
import { HttpError, json, methodNotAllowed, readJson } from "../_shared/http.ts";

export async function handle(req: Request): Promise<Response> {
  const mna = methodNotAllowed(req);
  if (mna) return mna;
  const auth = req.headers.get("authorization") ?? "";
  const expected = env("REVENUECAT_WEBHOOK_AUTH");
  if (!timingSafeEqual(auth, expected) && !timingSafeEqual(auth, `Bearer ${expected}`)) throw new HttpError(401, "unauthorized");
  const body = await readJson(req);
  const event = body.event;
  if (!event || typeof event !== "object") throw new HttpError(400, "invalid_event");
  const out = await rpc<Record<string, unknown>>("revenuecat_apply_event", { p_event: body });
  return json(out);
}

if (import.meta.main) {
  const { serve } = await import("../_shared/http.ts");
  serve(handle);
}
