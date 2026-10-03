// Environment access for Edge Functions. SUPABASE_URL / SUPABASE_ANON_KEY /
// SUPABASE_SERVICE_ROLE_KEY are injected by the platform; the rest come from
// `supabase secrets set` (values live only in supabase/.env, never in the app).
export function env(name: string): string {
  const v = Deno.env.get(name);
  if (!v) throw new Error(`missing env ${name}`);
  return v;
}

export function envOr(name: string, fallback: string): string {
  return Deno.env.get(name) ?? fallback;
}

/** Comma-separated allow list (trimmed, empty entries dropped). */
export function envList(name: string): string[] {
  return (Deno.env.get(name) ?? "")
    .split(",")
    .map((s) => s.trim())
    .filter((s) => s.length > 0);
}
