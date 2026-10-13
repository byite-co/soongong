// Private job endpoint; at most 50 single-owner transactions and 100 objects.
// Storage acknowledgement, never SQL metadata deletion, completes an obligation.
import { requireJobSecret } from "../_shared/auth.ts";
import { AiJobs } from "../_shared/ai_jobs.ts";
import { deleteObjects } from "../_shared/storage.ts";
import { json } from "../_shared/http.ts";
import { StudyDeadline } from "../_shared/study_deadline.ts";

export type DeleteStorage = (paths: string[]) => Promise<boolean>;
const remove: DeleteStorage = async paths => (await deleteObjects(paths,"study-restore")).length===0;
export async function runMaintenance(jobs = new AiJobs(), erase: DeleteStorage = remove, signal = new AbortController().signal) {
  let reaped=0;
  for(let i=0;i<50;i++) {
    const n=await jobs.rpc<number>("ai_maintenance",{},signal); reaped+=n;
    if(n===0) break;
  }
  const expired=await jobs.rpc<number>("study_photo_expire",{},signal);
  const rows=await jobs.rpc<{id:string;object_path:string}[]>("study_object_claim",{p_limit:100},signal);
  let done=0;
  if(rows.length && await erase(rows.map(r=>r.object_path))) {
    await jobs.rpc("study_object_done",{p_ids:rows.map(r=>r.id)},signal); done=rows.length;
  }
  return {reaped,expired,done,pending:rows.length-done};
}
export async function handle(req:Request) {
  requireJobSecret(req);
  const deadline=new StudyDeadline(req.signal,50_000);
  try {return json(await deadline.run(signal=>runMaintenance(undefined,undefined,signal)));}
  finally {deadline.close();}
}
if(import.meta.main) {const {serve}=await import("../_shared/http.ts"); serve(handle);}
