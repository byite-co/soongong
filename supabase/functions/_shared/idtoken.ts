// Provider id_token verification for issue-pass (D6 step 2):
// JWKS signature · iss · aud ∈ allow list (env) · exp; Apple additionally
// nonce == sha256(nonce). Returns the provider subject (`sub`).
import { createRemoteJWKSet, jwtVerify, type JWTPayload, type JWTVerifyGetKey } from "jose";
import { envList } from "./env.ts";
import { HttpError } from "./http.ts";

export type Provider = "apple" | "google" | "kakao";

interface ProviderSpec {
  jwks: URL;
  issuers: string[];
  audEnv: string;
}

const SPECS: Record<Provider, ProviderSpec> = {
  apple: { jwks: new URL("https://appleid.apple.com/auth/keys"), issuers: ["https://appleid.apple.com"], audEnv: "APPLE_AUD" },
  google: {
    jwks: new URL("https://www.googleapis.com/oauth2/v3/certs"),
    issuers: ["https://accounts.google.com", "accounts.google.com"],
    audEnv: "GOOGLE_AUD",
  },
  kakao: { jwks: new URL("https://kauth.kakao.com/.well-known/jwks.json"), issuers: ["https://kauth.kakao.com"], audEnv: "KAKAO_AUD" },
};

const jwksCache = new Map<Provider, JWTVerifyGetKey>();

export function isProvider(p: unknown): p is Provider {
  return p === "apple" || p === "google" || p === "kakao";
}

export async function sha256Hex(text: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(text));
  return Array.from(new Uint8Array(digest)).map((b) => b.toString(16).padStart(2, "0")).join("");
}

export interface VerifyOptions {
  nonce?: string | null;
  /** test seam: replaces the remote JWKS */
  keyResolver?: JWTVerifyGetKey;
  audiences?: string[];
  now?: Date;
}

export async function verifyProviderIdToken(provider: Provider, idToken: string, opts: VerifyOptions = {}): Promise<{ sub: string; email: string | null }> {
  const spec = SPECS[provider];
  const audiences = opts.audiences ?? envList(spec.audEnv);
  if (audiences.length === 0) throw new HttpError(500, "provider_not_configured", provider);
  let resolver: JWTVerifyGetKey | undefined = opts.keyResolver;
  if (!resolver) {
    resolver = jwksCache.get(provider);
    if (!resolver) {
      resolver = createRemoteJWKSet(spec.jwks) as unknown as JWTVerifyGetKey;
      jwksCache.set(provider, resolver);
    }
  }
  let payload: JWTPayload;
  try {
    ({ payload } = await jwtVerify(idToken, resolver, {
      issuer: spec.issuers,
      audience: audiences,
      currentDate: opts.now,
    }));
  } catch (_e) {
    throw new HttpError(400, "id_token_invalid");
  }
  if (typeof payload.sub !== "string" || payload.sub.length === 0) throw new HttpError(400, "id_token_invalid", "sub");
  if (provider === "apple") {
    if (!opts.nonce) throw new HttpError(400, "nonce_required");
    const expected = await sha256Hex(opts.nonce);
    if (payload.nonce !== expected && payload.nonce !== opts.nonce) throw new HttpError(400, "nonce_mismatch");
  }
  const email = typeof payload.email === "string" ? payload.email : null;
  return { sub: payload.sub, email };
}
