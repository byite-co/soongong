import { requireUser } from "../_shared/auth.ts";
import { rpc } from "../_shared/db.ts";
import { json, methodNotAllowed } from "../_shared/http.ts";
export async function handle(req:Request):Promise<Response>{
  const mna=methodNotAllowed(req);if(mna)return mna;
  const caller=await requireUser(req);
  return json(await rpc("reading_quota_snapshot",{p_user:caller.userId}));
}
if(import.meta.main){const {serve}=await import("../_shared/http.ts");serve(handle);}
