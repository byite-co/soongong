import { assertEquals, assertRejects } from "@std/assert";
import { exportJWK, generateKeyPair, SignJWT } from "jose";
import { createLocalJWKSet } from "jose";
import { sha256Hex, verifyProviderIdToken } from "../_shared/idtoken.ts";

const { publicKey, privateKey } = await generateKeyPair("RS256");
const jwk = await exportJWK(publicKey);
jwk.kid = "k1";
const resolver = createLocalJWKSet({ keys: [jwk] });

async function token(claims: Record<string, unknown>, iss = "https://appleid.apple.com", aud = "co.byite.soongong") {
  return await new SignJWT(claims)
    .setProtectedHeader({ alg: "RS256", kid: "k1" })
    .setIssuer(iss).setAudience(aud).setIssuedAt().setExpirationTime("5m").setSubject("sub-123")
    .sign(privateKey);
}

Deno.test("apple: valid token + nonce hash → sub", async () => {
  const t = await token({ nonce: await sha256Hex("n-1") });
  const r = await verifyProviderIdToken("apple", t, { nonce: "n-1", keyResolver: resolver, audiences: ["co.byite.soongong"] });
  assertEquals(r.sub, "sub-123");
});

Deno.test("apple: nonce mismatch / missing nonce rejected", async () => {
  const t = await token({ nonce: await sha256Hex("n-1") });
  await assertRejects(() => verifyProviderIdToken("apple", t, { nonce: "other", keyResolver: resolver, audiences: ["co.byite.soongong"] }));
  await assertRejects(() => verifyProviderIdToken("apple", t, { keyResolver: resolver, audiences: ["co.byite.soongong"] }));
});

Deno.test("wrong aud / wrong iss / expired rejected", async () => {
  const badAud = await token({}, "https://accounts.google.com", "someone-else");
  await assertRejects(() => verifyProviderIdToken("google", badAud, { keyResolver: resolver, audiences: ["co.byite.soongong"] }));
  const badIss = await token({}, "https://evil.example", "co.byite.soongong");
  await assertRejects(() => verifyProviderIdToken("google", badIss, { keyResolver: resolver, audiences: ["co.byite.soongong"] }));
  const good = await token({}, "https://accounts.google.com", "co.byite.soongong");
  const r = await verifyProviderIdToken("google", good, { keyResolver: resolver, audiences: ["co.byite.soongong"] });
  assertEquals(r.sub, "sub-123");
  await assertRejects(() => verifyProviderIdToken("google", good, { keyResolver: resolver, audiences: ["co.byite.soongong"], now: new Date(Date.now() + 3600_000) }));
});

Deno.test("no audience configured → provider_not_configured", async () => {
  const t = await token({}, "https://kauth.kakao.com", "kakao-app");
  await assertRejects(() => verifyProviderIdToken("kakao", t, { keyResolver: resolver, audiences: [] }));
});
