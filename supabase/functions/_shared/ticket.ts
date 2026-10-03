// Age ticket (D6 step 1): HS256 JWT, 10 minutes, claims {age_ok:true, jti}.
// Nothing about the birth date is inside — only the fact that the check passed.
import { jwtVerify, SignJWT } from "jose";

export const TICKET_TTL_SECONDS = 600;
const ISSUER = "soongong/age-check";
const AUDIENCE = "soongong/issue-pass";

function key(secret: string): Uint8Array {
  if (secret.length < 32) throw new Error("AGE_TICKET_SECRET must be at least 32 characters");
  return new TextEncoder().encode(secret);
}

export async function signAgeTicket(secret: string, now: Date = new Date()): Promise<string> {
  const iat = Math.floor(now.getTime() / 1000);
  return await new SignJWT({ age_ok: true })
    .setProtectedHeader({ alg: "HS256", typ: "JWT" })
    .setJti(crypto.randomUUID())
    .setIssuer(ISSUER)
    .setAudience(AUDIENCE)
    .setIssuedAt(iat)
    .setExpirationTime(iat + TICKET_TTL_SECONDS)
    .sign(key(secret));
}

export async function verifyAgeTicket(secret: string, ticket: string, now: Date = new Date()): Promise<{ jti: string }> {
  const { payload } = await jwtVerify(ticket, key(secret), {
    algorithms: ["HS256"],
    issuer: ISSUER,
    audience: AUDIENCE,
    currentDate: now,
  });
  if (payload.age_ok !== true || typeof payload.jti !== "string") throw new Error("ticket_invalid");
  return { jti: payload.jti };
}

/**
 * Age gate (D6): 만 14세 이상, evaluated on the server clock in KST.
 * `birthDate` is `yyyy-MM-dd`. Returns null for malformed / future dates.
 */
export function isAtLeast14(birthDate: string, now: Date = new Date()): boolean | null {
  const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(birthDate);
  if (!m) return null;
  const y = Number(m[1]), mo = Number(m[2]), d = Number(m[3]);
  if (mo < 1 || mo > 12 || d < 1 || d > 31) return null;
  const birth = new Date(Date.UTC(y, mo - 1, d));
  if (birth.getUTCFullYear() !== y || birth.getUTCMonth() !== mo - 1 || birth.getUTCDate() !== d) return null;
  // today in KST
  const kst = new Date(now.getTime() + 9 * 3600 * 1000);
  const ty = kst.getUTCFullYear(), tm = kst.getUTCMonth(), td = kst.getUTCDate();
  if (Date.UTC(ty, tm, td) < Date.UTC(y, mo - 1, d)) return null;
  let age = ty - y;
  if (tm < mo - 1 || (tm === mo - 1 && td < d)) age -= 1;
  return age >= 14;
}
