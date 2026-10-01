// age-check (D6 step 1) — input {birth_date: "yyyy-MM-dd"} → {allowed:true, ticket, expires_in}
// or {allowed:false}. The birth date is evaluated (만 14세, KST server clock) and
// discarded: never stored, never logged, never in error reports.
import { env } from "../_shared/env.ts";
import { error, HttpError, json, methodNotAllowed, readJson } from "../_shared/http.ts";
import { logger } from "../_shared/log.ts";
import { isAtLeast14, signAgeTicket, TICKET_TTL_SECONDS } from "../_shared/ticket.ts";

export async function handle(req: Request, now: Date = new Date()): Promise<Response> {
  const mna = methodNotAllowed(req);
  if (mna) return mna;
  const requestId = req.headers.get("x-request-id") ?? crypto.randomUUID();
  const log = logger(requestId);
  const body = await readJson(req);
  const birth = body.birth_date;
  if (typeof birth !== "string") throw new HttpError(400, "invalid_field", "birth_date");
  const ok = isAtLeast14(birth, now);
  if (ok === null) {
    log.info("age-check outcome=invalid");
    return error(400, "invalid_field", "birth_date");
  }
  if (!ok) {
    log.info("age-check outcome=blocked");
    return json({ allowed: false });
  }
  const ticket = await signAgeTicket(env("AGE_TICKET_SECRET"), now);
  log.info("age-check outcome=allowed");
  return json({ allowed: true, ticket, expires_in: TICKET_TTL_SECONDS });
}

if (import.meta.main) {
  const { serve } = await import("../_shared/http.ts");
  serve(handle);
}
