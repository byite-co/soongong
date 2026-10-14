import { z } from "zod";
import { HttpError } from "./http.ts";

const unit = z.number().int().nonnegative().max(Number.MAX_SAFE_INTEGER);
export const workerReceipt = z.object({
  worker_version: z.literal(1), attempt_id: z.string().uuid(),
  provider: z.literal("local"), model: z.string().min(1).max(200),
  result: z.unknown(),
  usage: z.object({requests: z.literal(1), images: z.literal(1), pages: z.literal(1),
    crops: z.number().int().min(0).max(1), elapsed_ms: unit}).strict(),
  billing: z.literal("local_no_external_api"),
}).strict();

export function receipt(raw: unknown, attempt: string | undefined, provider: string | undefined, model: string | undefined) {
  const parsed = workerReceipt.safeParse(raw);
  if (!parsed.success || parsed.data.attempt_id !== attempt || parsed.data.provider !== provider || parsed.data.model !== model) {
    throw new HttpError(502, "invalid_usage_evidence");
  }
  return parsed.data;
}

const box = z.tuple([z.number(), z.number(), z.number(), z.number()]).refine(b =>
  b.every(x => Number.isFinite(x) && x >= 0 && x <= 1) && b[0] <= b[2] && b[1] <= b[3]);
export const readingResult = z.object({schema_version: z.literal(2), pages: z.array(z.object({
  index: z.number().int().min(0).max(19), items: z.array(z.object({
    number: z.number().int().min(0).max(999999),
    mark: z.enum(["correct", "wrong", "partial", "unsolved", "guessed"]).nullable(),
    confidence: z.number().min(0).max(1).nullable(), box, needs_review: z.literal(true),
  }).strict()).max(500),
}).strict().refine(p => new Set(p.items.map(i => i.number)).size === p.items.length)).min(1).max(20)
}).strict().refine(r => new Set(r.pages.map(p => p.index)).size === r.pages.length);
