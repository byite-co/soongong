// Zod is used as a parser at the HTTP boundary, not as a replacement for SQL
// authorization / business validation. Preserve existing error codes, unknown
// keys, null handling and UTF-16 length semantics (no coercion or trimming).
import { z } from "zod";

export const jsonObjectSchema = z.record(z.string(), z.unknown());
// Use String.length explicitly: the legacy API counts UTF-16 code units,
// whereas the library's length policy may count Unicode characters.
export const requiredStringSchema = (max: number) =>
  z.string().refine((v) => v.length > 0 && v.length <= max);
export const optionalStringSchema = (max: number) =>
  z.string().refine((v) => v.length <= max).nullish();

// Preserve the existing Edge contract of 1..20 paths. SQL remains
// authoritative for ownership and path semantics.
export const photoPathsSchema = z.array(z.string().refine((v) => v.length <= 512)).min(1).max(20);
