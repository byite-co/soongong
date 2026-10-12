// Bounded, stateless pilot. Images never enter Storage/SQL or logs. No
// reading-quota mutation and no unconfigured/Fake success. Broader release
// requires a durable usage policy and the held-out model evaluation.
import { requireUser } from "../_shared/auth.ts";
import { serviceClient } from "../_shared/db.ts";
import { env, envList, envOr } from "../_shared/env.ts";
import { HttpError, json, methodNotAllowed } from "../_shared/http.ts";
import { boundedJson, requireStudyProfile, studyRequest, transcriptionResponse } from "../_shared/study.ts";

export async function handle(req: Request): Promise<Response> {
  const mna = methodNotAllowed(req); if (mna) return mna;
  const caller = await requireUser(req);
  if (envOr("STUDY_AI_ENABLED", "false") !== "true" || !envList("STUDY_AI_USER_IDS").includes(caller.userId)) {
    throw new HttpError(503, "engine_unavailable");
  }
  const parsed = studyRequest.safeParse(await boundedJson(req.body, 5600000));
  if (!parsed.success) throw new HttpError(400, "invalid_payload");
  const body = parsed.data;
  const profile = async (): Promise<Record<string, unknown> | null> => {
    const { data, error } = await serviceClient().from("profiles")
      .select("consent_account_at,consent_reading_at,consent_reading_revoked_at,purge_epoch")
      .eq("user_id", caller.userId).maybeSingle();
    if (error) throw new HttpError(503, "profile_unavailable");
    return data;
  };
  requireStudyProfile(await profile(), body.purge_epoch);
  const endpoint = new URL(env(body.kind === "math" ? "STUDY_MATH_OCR_WORKER_URL" : "STUDY_WORKER_URL"));
  if (endpoint.protocol !== "https:" || endpoint.username || endpoint.password || endpoint.search || endpoint.hash) {
    throw new HttpError(503, "engine_unavailable");
  }
  const abort = new AbortController();
  const timer = setTimeout(() => abort.abort(), 55000);
  const cancel = () => abort.abort();
  req.signal.addEventListener("abort", cancel, { once: true });
  try {
    const response = await fetch(endpoint, {
      method: "POST", redirect: "error", signal: abort.signal,
      headers: { "content-type": "application/json", "authorization": `Bearer ${env("STUDY_WORKER_SECRET")}` },
      body: JSON.stringify(body),
    });
    if (!response.ok) throw new HttpError(response.status === 429 ? 429 : 503, "engine_unavailable");
    const result = transcriptionResponse.safeParse(await boundedJson(response.body, 256000));
    if (!result.success || result.data.kind !== body.kind) throw new HttpError(502, "invalid_engine_result");
    // Deletion/revocation/account removal during inference invalidates it.
    await requireUser(req);
    requireStudyProfile(await profile(), body.purge_epoch);
    return json(result.data, 200, { "cache-control": "no-store" });
  } catch (error) {
    if (error instanceof HttpError) throw error;
    throw new HttpError(503, "engine_unavailable");
  } finally {
    clearTimeout(timer);
    req.signal.removeEventListener("abort", cancel);
  }
}

if (import.meta.main) {
  const { serve } = await import("../_shared/http.ts");
  serve(handle);
}
