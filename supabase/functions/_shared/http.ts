// JSON responses + the error contract shared by every function:
// { error: <code>, detail?: <string> } with the HTTP status that the code maps to.
import { jsonObjectSchema, optionalStringSchema, requiredStringSchema } from "./validation.ts";

export class HttpError extends Error {
  constructor(
    public readonly status: number,
    public readonly code: string,
    public readonly detail?: string,
  ) {
    super(code);
  }
}

export function json(body: unknown, status = 200, headers: Record<string, string> = {}): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json; charset=utf-8", ...headers },
  });
}

export function error(status: number, code: string, detail?: string): Response {
  return json(detail ? { error: code, detail } : { error: code }, status);
}

export async function readJson(req: Request): Promise<Record<string, unknown>> {
  try {
    const body = await req.json();
    const parsed = jsonObjectSchema.safeParse(body);
    if (!parsed.success) {
      throw new HttpError(400, "invalid_json");
    }
    // Validation must not rewrite unknown keys (including an own __proto__
    // JSON key); SQL / each endpoint remains responsible for its own fields.
    return body as Record<string, unknown>;
  } catch (e) {
    if (e instanceof HttpError) throw e;
    throw new HttpError(400, "invalid_json");
  }
}

export function requireString(body: Record<string, unknown>, key: string, max = 4096): string {
  const parsed = requiredStringSchema(max).safeParse(body[key]);
  if (!parsed.success) throw new HttpError(400, "invalid_field", key);
  return parsed.data;
}

export function optionalString(
  body: Record<string, unknown>,
  key: string,
  max = 4096,
): string | null {
  const parsed = optionalStringSchema(max).safeParse(body[key]);
  if (!parsed.success) throw new HttpError(400, "invalid_field", key);
  return parsed.data ?? null;
}

export function methodNotAllowed(req: Request, allowed = "POST"): Response | null {
  if (req.method === allowed) return null;
  return error(405, "method_not_allowed");
}

/** Map P0001 RAISE messages from the SQL layer to HTTP statuses. */
const sqlStatus: Record<string, number> = {
  not_authenticated: 401,
  no_profile: 403,
  not_approved: 403,
  consent_required: 400,
  rate_limited: 429,
  invalid_body: 400,
  invalid_pass: 400,
  invalid_event: 400,
  batch_too_large: 413,
  invalid_rows: 400,
  invalid_request: 400,
  invalid_outcome: 400,
  entry_id_reused: 409,
};

export function statusForSqlError(message: string): number {
  return sqlStatus[message] ?? 500;
}

/** Wraps a handler: HttpError → its status; anything else → 500 without leaking details. */
export function serve(
  handler: (req: Request) => Promise<Response>,
  log: (msg: string) => void = console.error,
): void {
  Deno.serve(async (req: Request) => {
    const requestId = req.headers.get("x-request-id") ?? crypto.randomUUID();
    try {
      const res = await handler(req);
      res.headers.set("x-request-id", requestId);
      return res;
    } catch (e) {
      if (e instanceof HttpError) {
        log(`[${requestId}] ${e.status} ${e.code}`);
        const res = error(e.status, e.code, e.detail);
        res.headers.set("x-request-id", requestId);
        return res;
      }
      // Never log request bodies here: they may contain birth dates / emails / tokens.
      log(`[${requestId}] 500 ${e instanceof Error ? e.name : "error"}`);
      const res = error(500, "internal");
      res.headers.set("x-request-id", requestId);
      return res;
    }
  });
}
