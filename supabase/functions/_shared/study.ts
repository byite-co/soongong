import { z } from "zod";
import { HttpError } from "./http.ts";

export const studyRequest = z.object({
  schema_version: z.literal(1), operation: z.literal("ocr"),
  kind: z.enum(["text", "math"]), image: z.string().min(4).max(5592408).regex(/^[A-Za-z0-9+/]+={0,2}$/),
  purge_epoch: z.number().int().nonnegative(), consent_version: z.literal("study-2026-10-13"),
}).strict();

export const transcriptionResponse = z.object({
  schema_version: z.literal(1), kind: z.enum(["text", "math"]), engine: z.string().min(1).max(200),
  blocks: z.array(z.object({
    text: z.string().max(20000), confidence: z.number().min(0).max(1).nullable(),
    box: z.tuple([z.number(), z.number(), z.number(), z.number()]).refine(
      b => b.every(x => Number.isFinite(x) && x >= 0 && x <= 1) && b[0] <= b[2] && b[1] <= b[3]),
  }).strict()).max(500),
}).strict().refine(v => v.blocks.reduce((n, b) => n + b.text.length + 1, 0) <= 20000);

/** Bound both chunked and Content-Length bodies before parsing. */
export async function boundedJson(stream: ReadableStream<Uint8Array> | null, limit: number): Promise<unknown> {
  if (!stream) throw new HttpError(400, "invalid_payload");
  const reader = stream.getReader();
  const chunks: Uint8Array[] = [];
  let length = 0;
  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) break;
      length += value.byteLength;
      if (length > limit) throw new HttpError(413, "payload_too_large");
      chunks.push(value);
    }
  } finally { await reader.cancel(); }
  const bytes = new Uint8Array(length);
  let offset = 0;
  for (const part of chunks) { bytes.set(part, offset); offset += part.length; }
  try { return JSON.parse(new TextDecoder("utf-8", { fatal: true }).decode(bytes)); }
  catch { throw new HttpError(400, "invalid_payload"); }
}

export function requireStudyProfile(profile: Record<string, unknown> | null, epoch: number): void {
  if (!profile || !profile.consent_account_at || !profile.consent_reading_at || profile.consent_reading_revoked_at) {
    throw new HttpError(403, "consent_required");
  }
  if (profile.purge_epoch !== epoch) throw new HttpError(409, "stale_epoch");
}
