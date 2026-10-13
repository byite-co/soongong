// Selection-only, short private download grant. Upload/download UI is NEXT-05.
import {z} from "zod";
import {requireUser} from "../_shared/auth.ts";
import {AiJobs} from "../_shared/ai_jobs.ts";
import {serviceClient} from "../_shared/db.ts";
import {boundedJson} from "../_shared/study.ts";
import {HttpError,json,methodNotAllowed} from "../_shared/http.ts";
import {StudyDeadline} from "../_shared/study_deadline.ts";
const schema=z.object({version:z.literal(1),purge_epoch:z.number().int().nonnegative(),asset_id:z.string().uuid()}).strict();
type Access={bucket:string;path:string;expires_at:string;ttl_seconds:number};
export function signedExpiry(url:string):number {
  const token=new URL(url).searchParams.get("token");
  if(!token) throw new HttpError(503,"photo_unavailable");
  try {
    // This is the Storage response over the trusted SDK, never a client token.
    const exp=JSON.parse(atob(token.split(".")[1].replaceAll("-","+").replaceAll("_","/"))).exp;
    if(!Number.isSafeInteger(exp)) throw new Error();
    return exp*1000;
  } catch {throw new HttpError(503,"photo_unavailable");}
}
export async function handle(req:Request) {
  const deadline=new StudyDeadline(req.signal,15_000);
  try {
    const mna=methodNotAllowed(req); if(mna) return mna;
    const caller=await deadline.run(signal=>requireUser(req,signal));
    const parsed=schema.safeParse(await deadline.run(signal=>boundedJson(req.body,2048,signal)));
    if(!parsed.success) throw new HttpError(400,"invalid_payload");
    const b=parsed.data, jobs=new AiJobs();
    const access=()=>deadline.run(signal=>jobs.rpc<Access>("study_photo_access",{p_user:caller.userId,p_epoch:b.purge_epoch,p_asset:b.asset_id},signal));
    const asset=await access();
    const ttl=Math.min(60,asset.ttl_seconds,Math.floor((Date.parse(asset.expires_at)-Date.now())/1000)-2);
    if(ttl<1) throw new HttpError(410,"photo_expired");
    const {data,error}=await deadline.run(()=>serviceClient().storage.from(asset.bucket).createSignedUrl(asset.path,ttl));
    if(error || !data) throw new HttpError(503,"photo_unavailable");
    if(signedExpiry(data.signedUrl)>Date.parse(asset.expires_at)) throw new HttpError(503,"photo_unavailable");
    const current=await access(); // purge/deletion/expiry while signing
    if(current.path!==asset.path) throw new HttpError(410,"photo_expired");
    return json({version:1,asset_id:b.asset_id,url:data.signedUrl,expires_at:new Date(signedExpiry(data.signedUrl)).toISOString()},200,{"cache-control":"no-store"});
  } finally {deadline.close();}
}
if(import.meta.main) {const {serve}=await import("../_shared/http.ts"); serve(handle);}
