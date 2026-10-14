// Disposable PostgreSQL 16 only. No hosted Supabase, provider or payment call.
import {assert,assertEquals,assertRejects} from "@std/assert";
import {AiJobs,type JobRpc,type JobView} from "../_shared/ai_jobs.ts";
import {HttpError} from "../_shared/http.ts";
import {handle} from "../study-infer/index.ts";
import {runMaintenance} from "../study-maintenance/index.ts";
if(Deno.env.get("PGDATABASE")!=="soongong_test" || Deno.env.get("GITHUB_ACTIONS")!=="true") throw new Error("disposable_ci_database_required");
const A="aaaaaaaa-1111-4111-8111-111111111111",B="bbbbbbbb-1111-4111-8111-111111111111";
const Q="22222222-2222-4222-8222-222222222222", QS="22222222-2222-4222-8222-222222222223";
const D="dddddddd-1111-4111-8111-111111111111";
const tr={schema_version:1,kind:"text",engine:"synthetic",blocks:[]};
const literal=(v:unknown):string=>Array.isArray(v) ? `ARRAY[${v.map(literal).join(",")}]::uuid[]` : v===null ? "null" : typeof v==="number" ? String(v) : "'"+(typeof v==="string"?v:JSON.stringify(v)).replaceAll("'","''")+"'"+(typeof v==="object"?"::jsonb":"");
async function sql(source:string,signal?:AbortSignal,label="fd_query"):Promise<string> {
  const child=new Deno.Command("psql",{args:["-XAtq","-v","ON_ERROR_STOP=1"],env:{PGAPPNAME:label},stdin:"piped",stdout:"piped",stderr:"piped",signal}).spawn();
  const writer=child.stdin.getWriter();await writer.write(new TextEncoder().encode("SET statement_timeout='12s'; SET lock_timeout='10s';\n"+source));await writer.close();
  const out=await child.output();
  if(!out.success) {
    const message=new TextDecoder().decode(out.stderr).match(/ERROR:\s+([a-z_]+)\b/)?.[1] ?? "database_test_error";
    throw new HttpError(409,message);
  }
  return new TextDecoder().decode(out.stdout).trim();
}
async function value(source:string):Promise<unknown> {return JSON.parse(await sql(`select coalesce(to_jsonb((${source})),'null'::jsonb);`));}
function statement(name:string,args:Record<string,unknown>) {
  if(!/^(ai_|study_|reading_)[a-z0-9_]+$/.test(name) || Object.keys(args).some(k=>!/^p_[a-z_]+$/.test(k))) throw new Error("invalid_test_rpc");
  return `public.${name}(${Object.entries(args).map(([k,v])=>`${k}=>${literal(v)}`).join(",")})`;
}
const transport:JobRpc=async<T>(name:string,args:Record<string,unknown>,signal:AbortSignal)=>JSON.parse(await sql(name === "study_object_claim"
  ? `select coalesce(jsonb_agg(to_jsonb(r)),'[]'::jsonb) from ${statement(name,args)} r;`
  : `select coalesce(to_jsonb(${statement(name,args)}),'null'::jsonb);`,signal)) as T;
const jobs=new AiJobs(transport), signal=()=>new AbortController().signal;
const reserve=(user=A,request=crypto.randomUUID())=>({p_user:user,p_epoch:0,p_request:request,p_quote:Q,p_operation:"ocr_text",p_digest:"a".repeat(64),p_document:null,p_revision:null});
async function setup(points=10,limit=300000,infra=100000) {
  await sql(`TRUNCATE public.reading_requests,public.reading_ai_policies,public.reading_quota,public.study_documents,public.study_object_deletions,public.ai_jobs,public.ai_policies,public.ai_point_lots,public.ai_budgets RESTART IDENTITY CASCADE;
    CREATE OR REPLACE FUNCTION public.study_now() RETURNS timestamptz LANGUAGE sql VOLATILE SET search_path='' AS $$ SELECT '2026-10-13T00:00:00Z'::timestamptz $$;
    INSERT INTO auth.users(id) VALUES('${A}'),('${B}') ON CONFLICT DO NOTHING;
    INSERT INTO public.profiles(user_id,consent_account_at,consent_reading_at) VALUES('${A}',now(),now()),('${B}',now(),now()) ON CONFLICT(user_id) DO UPDATE SET purge_epoch=0,consent_reading_revoked_at=null,consent_account_at=now(),consent_reading_at=now();
    INSERT INTO public.ai_policies(id,operation,enabled,provider,model,points,terms_version,charge_order,result_ttl_seconds,max_input_tokens,max_output_tokens,max_attempts,input_price,output_price,fixed_price,currency,price_version,fx_version,fx_at,krw_per_currency,lease_seconds)
    VALUES('${Q}','ocr_text',true,'local','fixture',3,'test-terms','earliest_expiry',60,100,50,1,.001,.002,0,'USD','test-price','test-fx',now(),1000,60),
    ('${QS}','solve',true,'local','fixture',7,'test-terms','earliest_expiry',60,100,50,1,.001,.002,0,'USD','test-price','test-fx',now(),1000,60);
    SELECT public.ai_budget_set('2026-10-01',${limit},${infra},.8);
    SELECT public.ai_grant('${A}','purchase','synthetic-purchase',${points},null);
    SELECT public.ai_grant('${B}','subscription','synthetic-period',${points},null);`);
}
async function stats() {return await value(`select jsonb_build_object('remaining',sum(remaining),'reserved',sum(reserved)) from public.ai_point_lots where user_id='${A}'`);}
async function advance() {await sql(`CREATE OR REPLACE FUNCTION public.study_now() RETURNS timestamptz LANGUAGE sql VOLATILE SET search_path='' AS $$ SELECT '2026-10-13T00:02:00Z'::timestamptz $$;`);}
const request=(id:string,input:unknown={schema_version:1,operation:"ocr",kind:"text",image:"YQ==",purge_epoch:0,consent_version:"study-2026-10-13"})=>new Request("https://fixture.invalid/study-infer",{method:"POST",body:JSON.stringify({version:2,request_id:id,quote_id:Q,input})});
function edge() {
  let calls=0;
  const io={jobs,user:async()=>({userId:A,deviceId:null}),profile:async()=>await value(`select jsonb_build_object('purge_epoch',purge_epoch,'consent_account_at',consent_account_at,'consent_reading_at',consent_reading_at,'consent_reading_revoked_at',consent_reading_revoked_at) from public.profiles where user_id='${A}'`) as Record<string,unknown>,fetch:(async(_url,init)=>{
    calls++;const b=JSON.parse(String(init?.body));assertEquals(b.version,2);assertEquals(b.limits.max_attempts,1);assert(b.attempt_id);return Response.json({worker_version:1,attempt_id:b.attempt_id,provider:b.provider,model:b.model,result:tr,usage:{requests:1,images:1,pages:1,crops:0,elapsed_ms:1},billing:"local_no_external_api"});
  }) as typeof fetch};
  return {io,calls:()=>calls};
}
Deno.env.set("STUDY_AI_ENABLED","true");Deno.env.set("STUDY_AI_USER_IDS",A);Deno.env.set("STUDY_WORKER_URL","https://fixture.invalid/infer");Deno.env.set("STUDY_WORKER_SECRET","synthetic-test-only-0000000000000000");
Deno.test("FD-01/02/12 actual DB Edge pipeline, replay, input conflict and closed flags",async()=>{
  await setup();const f=edge(), id=crypto.randomUUID();
  Deno.env.set("STUDY_AI_ENABLED","false");await assertRejects(()=>handle(request(id),f.io),HttpError,"engine_unavailable");
  assertEquals(await value("select count(*) from public.ai_jobs"),0);assertEquals(f.calls(),0);Deno.env.set("STUDY_AI_ENABLED","true");
  const old=new Request("https://fixture.invalid",{method:"POST",body:JSON.stringify({schema_version:1,operation:"ocr"})});
  await assertRejects(()=>handle(old,f.io),HttpError,"invalid_payload");
  const first=await (await handle(request(id),f.io)).json();const second=await (await handle(request(id),f.io)).json();
  assertEquals(first.job_id,second.job_id);assertEquals(first.state,"succeeded");assertEquals(f.calls(),1);assertEquals(await stats(),{remaining:7,reserved:0});
  await assertRejects(()=>handle(request(id,{schema_version:1,operation:"ocr",kind:"text",image:"Yg==",purge_epoch:0,consent_version:"study-2026-10-13"}),f.io),HttpError,"request_conflict");assertEquals(f.calls(),1);
  assertEquals(await value("select count(*) from public.reading_quota"),0);
  const other=await jobs.reserve({...reserve(B,id)},signal());assert(other.job_id!==first.job_id);assertEquals(other.state,"reserved");
});
async function waitFor(label:string,type:string) {
  for(let i=0;i<80;i++) {
    if(await value(`select exists(select from pg_stat_activity where application_name='${label}' and wait_event_type='${type}')`)) return;
    await new Promise(r=>setTimeout(r,20));
  }
  throw new Error(`missing_${label}_${type}_barrier`);
}
async function race(first:string,second:string) {
  const one=sql(`BEGIN;SELECT ${first};SELECT pg_sleep(3);COMMIT;`,undefined,"fd_first");
  await waitFor("fd_first","Timeout");
  const two=sql(`SELECT ${second};`,undefined,"fd_second");
  // Observe the actual PostgreSQL lock waiter, not just simultaneous JS tasks.
  const settledTwo=two.then(v=>({ok:true,value:v}),e=>({ok:false,value:e.message}));
  await waitFor("fd_second","Lock");await one;return await settledTwo;
}
Deno.test("FD-13 real parallel requests serialize on remaining points",async()=>{
  await setup(3);const first=statement("ai_reserve",reserve()),second=statement("ai_reserve",reserve());
  assertEquals(await race(first,second),{ok:false,value:"points_insufficient"});
  assertEquals(await stats(),{remaining:3,reserved:3});assertEquals(await value("select count(*) from public.ai_jobs"),1);
});
Deno.test("FD-19 different users serialize on global budget including infrastructure",async()=>{
  await setup(10,300,100);assertEquals(await race(statement("ai_reserve",reserve()),statement("ai_reserve",reserve(B))),{ok:false,value:"budget_exceeded"});
  assertEquals(await value("select reserved_krw+infrastructure_krw+spent_krw from public.ai_budgets"),300);
  assertEquals(await value("select sum(reserved) from public.ai_point_lots"),3);
});
Deno.test("A20 actual reading versus OCR lock race shares one global budget and refunds quota on denial",async()=>{
  await setup(10,300,100);
  const rid=crypto.randomUUID();
  await sql(`INSERT INTO public.subscription_state(user_id,expires_at,will_renew,period_type,has_history) VALUES('${B}',now()+interval '1 day',true,'NORMAL',true) ON CONFLICT(user_id) DO UPDATE SET expires_at=excluded.expires_at;
    INSERT INTO public.reading_ai_policies(enabled,provider,model,fixed_price,currency,krw_per_currency,price_version,fx_version,fx_at) VALUES(true,'local','fixture',200,'KRW',1,'test','test',now());
    SELECT public.reading_submit('${B}','${rid}',${literal({subject_id:crypto.randomUUID(),range_text:'synthetic',origin:'home',object_paths:[`${B}/${rid}/p0.jpg`]})});
    SELECT public.reading_claim_job();`);
  assertEquals(await race(statement('ai_reserve',reserve(A)),statement('reading_ai_begin',{p_user:B,p_request:rid,p_attempt:1})),{ok:false,value:'budget_exceeded'});
  await sql(`SELECT public.reading_finish_attempt('${B}','${rid}',1,'failed',null,'budget_exceeded');`);
  assertEquals(await value('select spent_krw+reserved_krw+infrastructure_krw from public.ai_budgets'),300);
  assertEquals(await value(`select reserved from public.reading_quota where user_id='${B}'`),0);
  assertEquals(await value('select count(*) from public.reading_ai_costs'),0);
  assertEquals(await value(`select reserved from public.ai_point_lots where user_id='${B}'`),0);
});
Deno.test("FD-16 injected settlement failure rolls back result and point charge",async()=>{
  await setup();const job=await jobs.reserve(reserve(),signal());await jobs.dispatch(A,0,job.job_id,signal());
  await sql(`CREATE FUNCTION public.fd_fail_settle() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN IF NEW.kind='settle' THEN RAISE EXCEPTION 'injected_settle'; END IF; RETURN NEW; END $$;CREATE TRIGGER fd_fail BEFORE INSERT ON public.ai_point_ledger FOR EACH ROW EXECUTE FUNCTION public.fd_fail_settle();`);
  try {await assertRejects(()=>jobs.finish(job.job_id,"succeeded",tr,signal()),HttpError,"injected_settle");assertEquals(await stats(),{remaining:10,reserved:3});assertEquals(await value(`select result from public.ai_jobs where id='${job.job_id}'`),null);}
  finally {await sql("DROP TRIGGER fd_fail ON public.ai_point_ledger;DROP FUNCTION public.fd_fail_settle();");}
  await sql(`CREATE FUNCTION public.fd_fail_result() RETURNS trigger LANGUAGE plpgsql AS $$ BEGIN IF NEW.result IS NOT NULL THEN RAISE EXCEPTION 'injected_result'; END IF; RETURN NEW; END $$;CREATE TRIGGER fd_fail_result BEFORE UPDATE ON public.ai_jobs FOR EACH ROW EXECUTE FUNCTION public.fd_fail_result();`);
  try {await assertRejects(()=>jobs.finish(job.job_id,"succeeded",tr,signal()),HttpError,"injected_result");assertEquals(await stats(),{remaining:10,reserved:3});assertEquals(await value("select count(*) from public.ai_point_ledger where kind='settle'"),0);}
  finally {await sql("DROP TRIGGER fd_fail_result ON public.ai_jobs;DROP FUNCTION public.fd_fail_result();");}
  await jobs.finish(job.job_id,"succeeded",tr,signal());await jobs.finish(job.job_id,"succeeded",tr,signal());assertEquals(await stats(),{remaining:7,reserved:0});
});
Deno.test("FD-17/18 dispatch interruption retains unknown cost, lease recovery never recalls provider",async()=>{
  await setup();const args=reserve(), job=await jobs.reserve(args,signal());await jobs.dispatch(A,0,job.job_id,signal());await advance();
  await jobs.rpc("ai_maintenance",{},signal());const retry=await jobs.reserve(args,signal());assertEquals(retry.state,"reconciliation_required");
  assertEquals((await jobs.dispatch(A,0,job.job_id,signal())).claimed,false);assertEquals(await stats(),{remaining:10,reserved:3});
  await jobs.finish(job.job_id,"failed",null,signal());await jobs.finish(job.job_id,"failed",null,signal());assertEquals(await stats(),{remaining:10,reserved:0});
  assertEquals(await value("select jsonb_build_object('status',status,'actual',actual_krw) from public.ai_costs"),{status:"unknown",actual:null});assertEquals(await value("select reserved_krw from public.ai_budgets"),200);
  await jobs.rpc("ai_reconcile",{p_job:job.job_id,p_settlement:crypto.randomUUID(),p_actual:.17,p_usage:{input_tokens:100,output_tokens:35}},signal());assertEquals(await value("select spent_krw from public.ai_budgets"),170);
});
Deno.test("FD-18 never-dispatched lease releases points/cost; temporary result expires",async()=>{
  await setup();const job=await jobs.reserve(reserve(),signal());await advance();await jobs.rpc("ai_maintenance",{},signal());assertEquals(await stats(),{remaining:10,reserved:0});assertEquals(await value("select status from public.ai_costs"),"not_dispatched");
  await setup();const f=edge(),id=crypto.randomUUID();await handle(request(id),f.io);await advance();await jobs.rpc("ai_maintenance",{},signal());
  const status=await jobs.rpc<JobView>("ai_status",{p_user:A,p_epoch:0,p_request:id},signal());assertEquals(status.result,null);assertEquals(status.result_expired,true);
  await handle(request(id),f.io);assertEquals(f.calls(),1);
});
Deno.test("FD-07/24 purge in flight releases user reservation but keeps cost obligation and grant receipt",async()=>{
  await setup();const job=await jobs.reserve(reserve(),signal());await jobs.dispatch(A,0,job.job_id,signal());
  await sql(`SELECT public.purge_all('${A}','${crypto.randomUUID()}',0);`);
  assertEquals((await jobs.finish(job.job_id,"succeeded",tr,signal())).state,"cancelled");assertEquals(await stats(),{remaining:10,reserved:0});
  assertEquals(await value("select reserved_krw from public.ai_budgets"),200);assertEquals(await value(`select input_digest from public.ai_jobs where id='${job.job_id}'`),null);
  await jobs.rpc("ai_grant",{p_user:A,p_source:"purchase",p_source_id:"synthetic-purchase",p_points:10,p_expires_at:null},signal());assertEquals(await stats(),{remaining:10,reserved:0});
  await assertRejects(()=>jobs.rpc("ai_status",{p_user:A,p_epoch:0,p_request:job.request_id},signal()),HttpError,"study_access_denied");
});
Deno.test("FD-25 deleted account callback cannot resurrect content; anonymous cost still settles",async()=>{
  await setup();const job=await jobs.reserve(reserve(),signal());await jobs.dispatch(A,0,job.job_id,signal());await sql(`SELECT public.delete_account_data('${A}');`);
  const late=await jobs.finish(job.job_id,"succeeded",tr,signal());assertEquals(late.state,"cancelled");assertEquals(late.result,null);
  await jobs.rpc("ai_reconcile",{p_job:job.job_id,p_settlement:crypto.randomUUID(),p_actual:.1,p_usage:{}},signal());
  assertEquals(await value(`select count(*) from public.profiles where user_id='${A}'`),0);assertEquals(await value(`select count(*) from public.ai_point_lots where user_id='${A}'`),0);assertEquals(await value("select spent_krw from public.ai_budgets"),100);
});
const saveSql=(id=D)=>`public.study_save_v1(0,'${id}',null,'text','title','full private content',${literal(tr)})`;
Deno.test("FD-04/08 metadata paging and commit-order cursor block on the owner lock",async()=>{
  await setup();await sql(`SET request.jwt.claim.sub='${A}';SELECT ${saveSql()};`);
  const doc2=crypto.randomUUID();const first=`set_config('request.jwt.claim.sub','${A}',true);SELECT ${saveSql(doc2)}`;
  const result=await race(first,`set_config('request.jwt.claim.sub','${A}',false);SELECT public.study_metadata_v1(0,0,100)`);
  assert(result.ok);const page=JSON.parse(result.value.split("\n").at(-1)!);assertEquals(page.rows.length,2);assert(!JSON.stringify(page).includes("full private content"));
  const p1=JSON.parse((await sql(`SET request.jwt.claim.sub='${A}';SELECT public.study_metadata_v1(0,0,1);`)));const p2=JSON.parse(await sql(`SET request.jwt.claim.sub='${A}';SELECT public.study_metadata_v1(0,${p1.next_seq},1);`));
  assertEquals(new Set([p1.rows[0].id,p2.rows[0].id]).size,2);assert(p2.next_seq>p1.next_seq);
});
Deno.test("FD-22 real deletion obligations survive document removal; Storage failure then retry acknowledges only bytes deletion",async()=>{
  await setup();const asset=crypto.randomUUID();await sql(`SET request.jwt.claim.sub='${A}';SELECT ${saveSql()};SELECT public.study_photo_register_v1(0,'${D}','${asset}');SELECT public.study_delete_v1(0,'${D}');`);
  // Clock-controlled jobs created with default now() must be made due for this fixture.
  await sql("UPDATE public.study_object_deletions SET next_at=public.study_now();");
  let removed=0;const first=await runMaintenance(jobs,async()=>false);assertEquals(first.pending,1);assertEquals(first.done,0);assertEquals(await value("select status from public.study_object_deletions"),"pending");
  await sql("UPDATE public.study_object_deletions SET next_at=public.study_now();");
  const second=await runMaintenance(jobs,async paths=>{removed+=paths.length;return true;});assertEquals(second.done,1);assertEquals(removed,1);assertEquals(await value("select status from public.study_object_deletions"),"done");
});

Deno.test("FD-06/15 actual solve points and source revision change invalidate pending result",async()=>{
  await setup();await sql(`SET request.jwt.claim.sub='${A}';SELECT ${saveSql()};`);
  const args={...reserve(),p_quote:QS,p_operation:"solve",p_document:D,p_revision:1};
  const job=await jobs.reserve(args,signal());assertEquals(await stats(),{remaining:10,reserved:7});
  await jobs.dispatch(A,0,job.job_id,signal());
  await sql(`SET request.jwt.claim.sub='${A}';SELECT public.study_save_v1(0,'${D}',1,'text','new title','new confirmed text',${literal(tr)});`);
  const solution={schema_version:1,document_id:D,revision:1,answer:"2",explanation:"synthetic",model:"fixture",verification:"inconclusive",reference_provided:false};
  assertEquals((await jobs.finish(job.job_id,"succeeded",solution,signal())).state,"cancelled");assertEquals(await stats(),{remaining:10,reserved:0});
  assertEquals(await value(`select result from public.ai_jobs where id='${job.job_id}'`),null);assertEquals(await value("select status from public.ai_costs"),"unknown");
  await assertRejects(()=>jobs.reserve(args,signal()),HttpError,"request_conflict");
  const next=await jobs.reserve({...args,p_request:crypto.randomUUID(),p_revision:2},signal());
  await jobs.dispatch(A,0,next.job_id,signal());await jobs.finish(next.job_id,"succeeded",{...solution,revision:2},signal());
  assertEquals(await stats(),{remaining:3,reserved:0}); // Successful solve settles 7, OCR settles 3.
});

Deno.test("FD-01 no key, allowlist mismatch, revoked consent and missing budget reserve nothing",async()=>{
  await setup();const f=edge();
  const savedSecret=Deno.env.get("STUDY_WORKER_SECRET")!;
  Deno.env.set("STUDY_WORKER_SECRET","short");await assertRejects(()=>handle(request(crypto.randomUUID()),f.io),HttpError,"engine_unavailable");Deno.env.set("STUDY_WORKER_SECRET",savedSecret);
  Deno.env.set("STUDY_AI_USER_IDS",B);await assertRejects(()=>handle(request(crypto.randomUUID()),f.io),HttpError,"engine_unavailable");Deno.env.set("STUDY_AI_USER_IDS",A);
  await sql(`UPDATE public.profiles SET consent_reading_revoked_at=now() WHERE user_id='${A}';`);await assertRejects(()=>handle(request(crypto.randomUUID()),f.io),HttpError,"consent_required");
  await sql(`UPDATE public.profiles SET consent_reading_revoked_at=null WHERE user_id='${A}';DELETE FROM public.ai_budgets;`);
  await assertRejects(()=>handle(request(crypto.randomUUID()),f.io),HttpError,"budget_unavailable");assertEquals(f.calls(),0);assertEquals(await value("select count(*) from public.ai_jobs"),0);assertEquals(await stats(),{remaining:10,reserved:0});
});
Deno.test("FD-12 two concurrent Edge requests share one actual DB dispatch and one synthetic execution",async()=>{
  await setup();const f=edge(),id=crypto.randomUUID();let enter!:()=>void,finish!:()=>void;
  const entered=new Promise<void>(r=>enter=r),release=new Promise<void>(r=>finish=r);const original=f.io.fetch;
  f.io.fetch=(async(url,init)=>{enter();await release;return await original(url,init);}) as typeof fetch;
  const first=handle(request(id),f.io);await entered;const second=await(await handle(request(id),f.io)).json();finish();const done=await(await first).json();
  assertEquals(done.job_id,second.job_id);assertEquals(second.state,"dispatching");assertEquals(done.state,"succeeded");assertEquals(f.calls(),1);assertEquals(await stats(),{remaining:7,reserved:0});
});
