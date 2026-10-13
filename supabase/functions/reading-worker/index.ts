// reading-worker (D16) — job function (x-job-secret). Loops: claim (atomic SQL:
// lease 3 min, attempts+1, FOR UPDATE SKIP LOCKED, keyed by (user_id, request_id))
// → bounded private engine → fenced finish → delete photos now.
// Started by pg_net from reading_submit and by the 1-minute cron sweep.
import { requireJobSecret } from "../_shared/auth.ts";
import { rpc } from "../_shared/db.ts";
import { json } from "../_shared/http.ts";
import { deletePhotosNow, type FinishResult, type RpcCall } from "../_shared/reading.ts";
import { env, envOr, envList } from "../_shared/env.ts";
import { boundedJson } from "../_shared/study.ts";
import { StudyDeadline } from "../_shared/study_deadline.ts";
import { receipt, readingResult } from "../_shared/worker_receipt.ts";
import { HttpError } from "../_shared/http.ts";

export interface ClaimedJob {
  request_id: string;
  user_id: string;
  attempts: number;
  object_paths: string[];
  subject_id: string | null;
  range_text: string | null;
}

export interface EngineResult {
  ok: boolean;
  status: number;
  result?: Record<string, unknown>;
  reason?: string;
}

/** Owner paths come only from the atomic claim, never from a user URL. */
export async function callEngine(job: ClaimedJob, call: RpcCall = rpc, fetcher: typeof fetch = fetch): Promise<EngineResult> {
  if (envOr("READING_AI_ENABLED", "false") !== "true" || !envList("READING_AI_USER_IDS").includes(job.user_id)) {
    return {ok:false, status:503, reason:"engine_unavailable"};
  }
  const deadline = new StudyDeadline(new AbortController().signal, 55000);
  try {
    const endpoint = new URL(env("READING_WORKER_URL"));
    const secret = env("STUDY_WORKER_SECRET");
    if (endpoint.protocol !== "https:" || endpoint.username || endpoint.password || endpoint.search || endpoint.hash || secret.length < 32) throw new Error("engine_unavailable");
    if (!job.object_paths.length || job.object_paths.length > 20 || job.object_paths.some((p, i) => p !== `${job.user_id}/${job.request_id}/p${i}.jpg`)) throw new Error("invalid_object_path");
    const reservation = await deadline.run(() => call<{claimed:boolean;cost_id:string;attempt_id:string;provider:string;model:string;epoch:number}>("reading_ai_begin", {
      p_user:job.user_id, p_request:job.request_id, p_attempt:job.attempts,
    }));
    // Existing reservation might have reached the engine. Never replay it.
    if (!reservation.claimed) return {ok:false,status:409,reason:"reconciliation_required"};
    const pages = [];
    const usage = {requests:0,images:0,pages:0,crops:0,elapsed_ms:0};
    for (let index = 0; index < job.object_paths.length; index++) {
      const image = await deadline.run(async signal => {
        const url = new URL(`/storage/v1/object/authenticated/reading-photos/${job.object_paths[index].split("/").map(encodeURIComponent).join("/")}`, env("SUPABASE_URL"));
        const response = await fetcher(url, {signal,redirect:"error",headers:{authorization:`Bearer ${env("SUPABASE_SERVICE_ROLE_KEY")}`,apikey:env("SUPABASE_SERVICE_ROLE_KEY")}});
        if (!response.ok || Number(response.headers.get("content-length") ?? 0) > 4194304) throw new Error("image_unavailable");
        const reader = response.body?.getReader();
        if (!reader) throw new Error("image_unavailable");
        const chunks:Uint8Array[]=[]; let size=0;
        try { while(true) { const {done,value}=await reader.read(); if(done) break; size+=value.length; if(size>4194304) throw new Error("image_too_large"); chunks.push(value); } }
        finally { void reader.cancel().catch(()=>{}); reader.releaseLock(); }
        const bytes=new Uint8Array(size);let offset=0;for(const part of chunks){bytes.set(part,offset);offset+=part.length;}
        let binary="";for(let start=0;start<bytes.length;start+=8192) binary+=String.fromCharCode(...bytes.subarray(start,start+8192));
        return btoa(binary);
      });
      const response=await deadline.run(signal=>fetcher(endpoint,{method:"POST",redirect:"error",signal,
        headers:{authorization:`Bearer ${secret}`,"content-type":"application/json"},
        body:JSON.stringify({version:2,attempt_id:reservation.attempt_id,provider:reservation.provider,model:reservation.model,
          limits:{max_input_tokens:0,max_output_tokens:0,max_attempts:1},
          input:{schema_version:1,operation:"reading",page_index:index,image,purge_epoch:reservation.epoch,consent_version:"study-2026-10-13"}})}));
      if(!response.ok) throw new Error("engine_unavailable");
      const evidence=receipt(await deadline.run(signal=>boundedJson(response.body,256000,signal)),reservation.attempt_id,reservation.provider,reservation.model);
      for(const key of Object.keys(usage) as (keyof typeof usage)[]) usage[key]+=evidence.usage[key];
      // Keep the receipt even when the inner result is invalid. All page calls
      // must finish before zero API cost is proven; partial calls stay unknown.
      pages.push(evidence.result);
    }
    await deadline.run(()=>call("ai_record_evidence",{p_job:null,p_reading_cost:reservation.cost_id,p_attempt:reservation.attempt_id,
      p_provider:reservation.provider,p_model:reservation.model,p_usage:usage}));
    const normalized=pages.map((p,index)=>{
      const parsed=readingResult.safeParse(p);
      if(!parsed.success || parsed.data.pages.length!==1 || parsed.data.pages[0].index!==index) throw new HttpError(502,"invalid_engine_result");
      return parsed.data.pages[0];
    });
    return {ok:true,status:200,result:{schema_version:2,pages:normalized}};
  } finally { deadline.close(); }
}

export async function runOnce(
  engine: (j: ClaimedJob) => Promise<EngineResult> = callEngine,
  maxJobs = 1,
  call: RpcCall = rpc,
  remove?: (paths: string[]) => Promise<string[]>,
): Promise<{ processed: { user_id: string; request_id: string }[] }> {
  const processed: { user_id: string; request_id: string }[] = [];
  for (let i = 0; i < maxJobs; i++) {
    const job = await call<ClaimedJob | null>("reading_claim_job", {});
    if (!job) break;
    const finish = (outcome: "done" | "failed", result: Record<string, unknown> | null, reason: string | null) =>
      call<FinishResult>("reading_finish_attempt", {
        p_user: job.user_id,
        p_request_id: job.request_id,
        p_attempt: job.attempts,
        p_outcome: outcome,
        p_result: result,
        p_fail_reason: reason,
      });
    let fin: FinishResult;
    try {
      const r = await engine(job);
      fin = r.ok ? await finish("done", r.result ?? null, null) : await finish("failed", null, r.reason ?? `engine_${r.status}`);
    } catch (_e) {
      fin = await finish("failed", null, "engine_error");
    }
    if (fin.outcome !== "noop") await deletePhotosNow(job.user_id, job.request_id, fin.object_paths, call, remove);
    processed.push({ user_id: job.user_id, request_id: job.request_id });
  }
  return { processed };
}

export async function handle(req: Request): Promise<Response> {
  requireJobSecret(req);
  const out = await runOnce();
  return json(out);
}

if (import.meta.main) {
  const { serve } = await import("../_shared/http.ts");
  serve(handle);
}
