// Quotes/status/cancel require a fresh verified caller. No client-supplied owner.
import { z } from "zod";
import { requireUser } from "../_shared/auth.ts";
import { AiJobs } from "../_shared/ai_jobs.ts";
const { rpc } = new AiJobs();
import { envList, envOr } from "../_shared/env.ts";
import { HttpError, json, methodNotAllowed } from "../_shared/http.ts";
import { boundedJson } from "../_shared/study.ts";
import { type JobView } from "../_shared/ai_jobs.ts";
import { StudyDeadline, STUDY_DEADLINE_MS } from "../_shared/study_deadline.ts";
const schema = z.discriminatedUnion("action", [
  z.object({ version: z.literal(2), action: z.literal("quote"), purge_epoch: z.number().int().nonnegative(), operation: z.enum(["ocr_text","ocr_math","solve"]) }).strict(),
  z.object({ version: z.literal(2), action: z.enum(["status","cancel"]), purge_epoch: z.number().int().nonnegative(), request_id: z.string().uuid() }).strict(),
]);
export async function handle(req: Request): Promise<Response> {
  const deadline = new StudyDeadline(req.signal, STUDY_DEADLINE_MS);
  try {
    const mna=methodNotAllowed(req); if(mna) return mna;
    const user=await deadline.run(signal=>requireUser(req,signal));
    const parsed=schema.safeParse(await deadline.run(signal=>boundedJson(req.body,4096,signal)));
    if(!parsed.success) throw new HttpError(400,"invalid_payload");
    const b=parsed.data;
    if(b.action==="quote") {
      if(envOr("STUDY_AI_ENABLED","false")!=="true" || !envList("STUDY_AI_USER_IDS").includes(user.userId)) throw new HttpError(503,"engine_unavailable");
      return json(await deadline.run(signal=>rpc("ai_quote",{p_user:user.userId,p_epoch:b.purge_epoch,p_operation:b.operation},signal)),200,{"cache-control":"no-store"});
    }
    const job=await deadline.run(signal=>rpc<JobView>("ai_status",{p_user:user.userId,p_epoch:b.purge_epoch,p_request:b.request_id},signal));
    const result=b.action==="cancel" ? await deadline.run(signal=>rpc("ai_finish",{p_job:job.job_id,p_outcome:"cancelled",p_result:null},signal)) : job;
    return json(result,200,{"cache-control":"no-store"});
  } finally { deadline.close(); }
}
if(import.meta.main) { const {serve}=await import("../_shared/http.ts"); serve(handle); }
