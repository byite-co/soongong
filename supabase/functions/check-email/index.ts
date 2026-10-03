// check-email — existence only. Unauthenticated (pre-login), protected by the
// app key header + a per-IP sliding window (in-memory per isolate; the DB
// never sees the address). {email} → {exists: boolean}
import { timingSafeEqual } from "../_shared/auth.ts";
import { rpc } from "../_shared/db.ts";
import { env } from "../_shared/env.ts";
import { HttpError, json, methodNotAllowed, readJson, requireString } from "../_shared/http.ts";

const WINDOW_MS = 60_000;
const LIMIT = 20;
const hits = new Map<string, number[]>();

export function rateLimited(key: string, now = Date.now()): boolean {
  const arr = (hits.get(key) ?? []).filter((t) => now - t < WINDOW_MS);
  if (arr.length >= LIMIT) {
    hits.set(key, arr);
    return true;
  }
  arr.push(now);
  hits.set(key, arr);
  return false;
}

export async function handle(req: Request): Promise<Response> {
  const mna = methodNotAllowed(req);
  if (mna) return mna;
  const appKey = req.headers.get("x-app-key") ?? "";
  if (!timingSafeEqual(env("CHECK_EMAIL_APP_KEY"), appKey)) throw new HttpError(401, "unauthorized");
  const ip = req.headers.get("x-forwarded-for")?.split(",")[0].trim() || "unknown";
  if (rateLimited(ip)) throw new HttpError(429, "rate_limited");
  const body = await readJson(req);
  const email = requireString(body, "email", 320).trim();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) throw new HttpError(400, "invalid_field", "email");
  const exists = await rpc<boolean>("auth_email_exists", { p_email: email });
  return json({ exists });
}

if (import.meta.main) {
  const { serve } = await import("../_shared/http.ts");
  serve(handle);
}
