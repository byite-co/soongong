// User verification for app-facing functions: the Authorization bearer JWT is
// validated by Auth (`getUser`) — works with symmetric and asymmetric signing keys.
import { createClient } from "@supabase/supabase-js";
import { env } from "./env.ts";
import { HttpError } from "./http.ts";

export interface Caller {
  userId: string;
  deviceId: string | null;
}

export async function requireUser(req: Request): Promise<Caller> {
  const header = req.headers.get("authorization") ?? "";
  const m = /^Bearer\s+(.+)$/i.exec(header);
  if (!m) throw new HttpError(401, "not_authenticated");
  const client = createClient(env("SUPABASE_URL"), env("SUPABASE_ANON_KEY"), {
    auth: { persistSession: false, autoRefreshToken: false },
    global: { headers: { Authorization: header } },
  });
  const { data, error } = await client.auth.getUser(m[1]);
  if (error || !data?.user) throw new HttpError(401, "not_authenticated");
  const deviceId = req.headers.get("x-device-id");
  return { userId: data.user.id, deviceId: deviceId && deviceId.length <= 64 ? deviceId : null };
}

/** Job functions (worker · reaper · photo runner) are reached by pg_net / cron with a shared secret. */
export function requireJobSecret(req: Request): void {
  const expected = env("JOB_SECRET");
  const got = req.headers.get("x-job-secret") ?? "";
  if (!timingSafeEqual(expected, got)) throw new HttpError(401, "unauthorized");
}

export function timingSafeEqual(a: string, b: string): boolean {
  const ea = new TextEncoder().encode(a);
  const eb = new TextEncoder().encode(b);
  if (ea.length !== eb.length) return false;
  let diff = 0;
  for (let i = 0; i < ea.length; i++) diff |= ea[i] ^ eb[i];
  return diff === 0;
}
