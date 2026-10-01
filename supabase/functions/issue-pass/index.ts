// issue-pass (D6 step 2) — input {ticket, provider, id_token?, email?, nonce?}
// → ticket verified → provider token verified (JWKS · iss · aud allow list · exp,
// Apple nonce) → signup_passes upsert (key: social (provider, sha256(sub)),
// email ('email', sha256(lower(email)))). No ticket / bad token → 400, no pass.
import { rpc } from "../_shared/db.ts";
import { env } from "../_shared/env.ts";
import { HttpError, json, methodNotAllowed, optionalString, readJson, requireString } from "../_shared/http.ts";
import { isProvider, verifyProviderIdToken } from "../_shared/idtoken.ts";
import { logger } from "../_shared/log.ts";
import { verifyAgeTicket } from "../_shared/ticket.ts";

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

export async function handle(req: Request): Promise<Response> {
  const mna = methodNotAllowed(req);
  if (mna) return mna;
  const requestId = req.headers.get("x-request-id") ?? crypto.randomUUID();
  const log = logger(requestId);
  const body = await readJson(req);
  const ticket = requireString(body, "ticket", 2048);
  const provider = requireString(body, "provider", 16);
  try {
    await verifyAgeTicket(env("AGE_TICKET_SECRET"), ticket);
  } catch (_e) {
    log.info("issue-pass outcome=ticket_invalid");
    throw new HttpError(400, "ticket_invalid");
  }

  let subject: string;
  if (provider === "email") {
    const email = requireString(body, "email", 320).trim();
    if (!EMAIL_RE.test(email)) throw new HttpError(400, "invalid_field", "email");
    subject = email.toLowerCase();
  } else if (isProvider(provider)) {
    const idToken = requireString(body, "id_token", 8192);
    const nonce = optionalString(body, "nonce", 512);
    const verified = await verifyProviderIdToken(provider, idToken, { nonce });
    subject = verified.sub;
  } else {
    throw new HttpError(400, "invalid_field", "provider");
  }

  const result = await rpc<{ expires_at: string }>("signup_pass_upsert", {
    p_provider: provider,
    p_subject: subject,
    p_ttl_seconds: 600,
  });
  log.info(`issue-pass outcome=issued provider=${provider}`);
  return json({ issued: true, provider, expires_at: result.expires_at });
}

if (import.meta.main) {
  const { serve } = await import("../_shared/http.ts");
  serve(handle);
}
