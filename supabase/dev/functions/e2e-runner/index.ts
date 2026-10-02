// DEV PROJECT ONLY — S03b execution harness. Not listed in config.toml, never
// deployed to prod. Runs the real Auth API (GoTrue over Kong, with the
// platform-injected anon key) and the S03 Edge Functions from inside the
// project, so the signup gate (hook → trigger) is exercised exactly as the app
// would, and returns a REDACTED report: statuses, outcome codes, row counts,
// hook payload *shape* — never tokens, emails or secrets.
//
// Auth: `x-e2e-token` must equal server_config('e2e_token') (generated in the
// DB with gen_random_uuid(); invoked via pg_net from SQL so the token never
// leaves the project).
import { createClient } from "@supabase/supabase-js";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const ANON = Deno.env.get("SUPABASE_ANON_KEY")!;
const SERVICE = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const svc = createClient(SUPABASE_URL, SERVICE, { auth: { persistSession: false, autoRefreshToken: false } });

type Step = { step: string; status?: number; ok: boolean; code?: string; message?: string; data?: Record<string, unknown> };

function redactMessage(m: unknown): string {
  return String(m ?? "")
    .replace(/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}/g, "[email]")
    .replace(/\b[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\b/g, "[jwt]")
    .slice(0, 200);
}

async function authFetch(path: string, body: unknown, jwt?: string): Promise<{ status: number; json: Record<string, unknown> }> {
  const res = await fetch(`${SUPABASE_URL}/auth/v1${path}`, {
    method: "POST",
    headers: { "content-type": "application/json", apikey: ANON, Authorization: `Bearer ${jwt ?? ANON}` },
    body: JSON.stringify(body),
  });
  const text = await res.text();
  let json: Record<string, unknown> = {};
  try { json = JSON.parse(text); } catch { json = { raw: redactMessage(text) }; }
  return { status: res.status, json };
}

async function fnFetch(name: string, body: unknown, jwt?: string, extra: Record<string, string> = {}): Promise<{ status: number; json: Record<string, unknown> }> {
  const res = await fetch(`${SUPABASE_URL}/functions/v1/${name}`, {
    method: "POST",
    headers: { "content-type": "application/json", apikey: ANON, Authorization: `Bearer ${jwt ?? ANON}`, "x-device-id": "e2e", ...extra },
    body: JSON.stringify(body),
  });
  const text = await res.text();
  let json: Record<string, unknown> = {};
  try { json = JSON.parse(text); } catch { json = { raw: redactMessage(text) }; }
  return { status: res.status, json };
}

async function count(table: string, filter: Record<string, string> = {}): Promise<number> {
  let q = svc.from(table).select("*", { count: "exact", head: true });
  for (const [k, v] of Object.entries(filter)) q = q.eq(k, v);
  const { count: c, error } = await q;
  if (error) return -1;
  return c ?? 0;
}

async function sql<T = unknown>(fn: string, args: Record<string, unknown> = {}): Promise<{ data: T | null; error: string | null }> {
  const { data, error } = await svc.rpc(fn, args);
  return { data: (data as T) ?? null, error: error ? redactMessage(error.message) : null };
}

interface Scenario {
  name: string;
  email: string;        // test address (+tag), never echoed
  password: string;
  birthDate?: string;   // yyyy-MM-dd for age-check (the runner's own test data)
  withPass?: boolean;   // run age-check → issue-pass before signUp
  completeTwice?: boolean;
  deleteAfter?: boolean;
  concurrent?: number;  // N parallel signUps with the same pass
  reissuePass?: boolean;
}

async function run(s: Scenario): Promise<Step[]> {
  const steps: Step[] = [];
  let ticket: string | undefined;
  if (s.withPass) {
    const age = await fnFetch("age-check", { birth_date: s.birthDate ?? "2005-01-01" });
    steps.push({ step: "age-check", status: age.status, ok: age.status === 200, data: { allowed: age.json.allowed, has_ticket: typeof age.json.ticket === "string" } });
    if (age.json.allowed === true) ticket = age.json.ticket as string;
    if (ticket) {
      const pass = await fnFetch("issue-pass", { ticket, provider: "email", email: s.email });
      steps.push({ step: "issue-pass", status: pass.status, ok: pass.status === 200, code: pass.json.error as string | undefined, data: { issued: pass.json.issued } });
      if (s.reissuePass) {
        const again = await fnFetch("issue-pass", { ticket, provider: "email", email: s.email.toUpperCase() });
        const passRows = await sql<number>("e2e_pass_count", { p_email: s.email });
        steps.push({ step: "issue-pass again", status: again.status, ok: again.status === 200 && passRows.data === 1, data: { pass_rows: passRows.data } });
      }
    }
  }
  const signups = Math.max(1, s.concurrent ?? 1);
  const results = await Promise.all(Array.from({ length: signups }, () => authFetch("/signup", { email: s.email, password: s.password })));
  const okCount = results.filter((r) => r.status === 200 && typeof (r.json.access_token ?? (r.json as { session?: unknown }).session) !== "undefined" || (r.status === 200 && r.json.id)).length;
  for (const r of results) {
    steps.push({ step: "signUp", status: r.status, ok: r.status === 200, code: (r.json.error_code ?? r.json.code) as string | undefined, message: redactMessage(r.json.msg ?? r.json.message ?? r.json.error_description ?? "") });
  }
  const userId = results.find((r) => r.status === 200)?.json ? ((results.find((r) => r.status === 200)!.json.user as Record<string, unknown> | undefined)?.id as string | undefined) ?? (results.find((r) => r.status === 200)!.json.id as string | undefined) : undefined;
  const jwt = results.find((r) => r.status === 200)?.json.access_token as string | undefined;
  const counts = await sql<Record<string, number>>("e2e_counts", { p_email: s.email });
  steps.push({ step: "db-counts", ok: counts.error === null, data: { ...(counts.data ?? {}), signups_ok: okCount } });
  if (jwt) {
    const c1 = await fnFetch("complete-signup", { consent_version: "e2e" }, jwt);
    steps.push({ step: "complete-signup", status: c1.status, ok: c1.status === 200, code: c1.json.error as string | undefined, data: { approval_match: (c1.json.profile as Record<string, unknown> | undefined)?.user_id === userId } });
    if (s.completeTwice) {
      const c2 = await fnFetch("complete-signup", { consent_version: "e2e" }, jwt);
      const profiles = userId ? await count("profiles", { user_id: userId }) : -1;
      steps.push({ step: "complete-signup again", status: c2.status, ok: c2.status === 200 && profiles === 1, data: { profiles } });
    }
    if (s.deleteAfter) {
      const d = await fnFetch("delete-account", {}, jwt);
      const after = await sql<Record<string, number>>("e2e_counts", { p_email: s.email });
      steps.push({ step: "delete-account", status: d.status, ok: d.status === 200, data: after.data ?? {} });
    }
  }
  return steps;
}

Deno.serve(async (req) => {
  const { data: token } = await svc.from("server_config").select("value").eq("key", "e2e_token").maybeSingle();
  if (!token?.value || req.headers.get("x-e2e-token") !== token.value) {
    return new Response(JSON.stringify({ error: "unauthorized" }), { status: 401 });
  }
  const body = await req.json().catch(() => ({}));
  if (body.action === "health") {
    const h = await fetch(`${SUPABASE_URL}/auth/v1/health`, { headers: { apikey: ANON } });
    return new Response(JSON.stringify({ auth_health: await h.json() }), { headers: { "content-type": "application/json" } });
  }
  const steps = await run(body as Scenario);
  return new Response(JSON.stringify({ scenario: (body as Scenario).name, steps }), { headers: { "content-type": "application/json" } });
});
