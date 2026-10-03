// Service-role client + RPC wrapper. The Edge Function verifies the user and
// hands `p_user` to SQL; SQL functions are EXECUTE-granted to service_role only.
import { createClient, type SupabaseClient } from "@supabase/supabase-js";
import { env } from "./env.ts";
import { HttpError, statusForSqlError } from "./http.ts";

let cached: SupabaseClient | null = null;

export function serviceClient(): SupabaseClient {
  if (cached) return cached;
  cached = createClient(env("SUPABASE_URL"), env("SUPABASE_SERVICE_ROLE_KEY"), {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  return cached;
}

/** Calls a SQL function as service_role; P0001 messages become HttpErrors. */
export async function rpc<T = unknown>(name: string, args: Record<string, unknown>): Promise<T> {
  const { data, error } = await serviceClient().rpc(name, args);
  if (error) {
    const msg = (error.message ?? "").trim();
    const code = /^[a-z_]+$/.test(msg) ? msg : "sql_error";
    throw new HttpError(statusForSqlError(code), code);
  }
  return data as T;
}

/** Outcome objects carry `status_code` for non-2xx outcomes; strip it on the way out. */
export function outcomeResponse(out: Record<string, unknown>): { status: number; body: Record<string, unknown> } {
  const status = typeof out.status_code === "number" ? out.status_code : 200;
  const body = { ...out };
  delete body.status_code;
  return { status, body };
}
