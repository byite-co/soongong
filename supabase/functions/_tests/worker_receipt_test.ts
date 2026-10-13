import {assert,assertEquals,assertThrows,assertRejects} from "@std/assert";
import {receipt,readingResult} from "../_shared/worker_receipt.ts";
import {callEngine} from "../reading-worker/index.ts";
const attempt="11111111-1111-4111-8111-111111111111";
const good={worker_version:1,attempt_id:attempt,provider:"local",model:"fixture",result:{schema_version:1,kind:"text",engine:"fixture",blocks:[]},usage:{requests:1,images:1,pages:1,crops:0,elapsed_ms:1},billing:"local_no_external_api"};
Deno.test("A02/A18 authenticated receipt identity and explicit units cannot be forged or omitted",()=>{
  assertEquals(receipt(good,attempt,"local","fixture").result,good.result);
  for(const bad of [{...good,usage:null},{...good,worker_version:2},{...good,model:"other"},{...good,usage:{...good.usage,amount:0}},{...good,usage:{...good.usage,images:0}},{...good,billing:"unknown"}])assertThrows(()=>receipt(bad,attempt,"local","fixture"));
});
Deno.test("A15 reading uncertainty stays null; duplicate and invalid boxes are refused",()=>{
  const item={number:1,mark:null,confidence:null,box:[0,0,1,1],needs_review:true};
  const result={schema_version:2,pages:[{index:0,items:[item]}]};assert(readingResult.safeParse(result).success);
  for(const invalid of [{...item,box:[1,0,0,1]},{...item,number:1.5},{...item,mark:"automatic"},{...item,confidence:NaN},{...item,needs_review:false}])assert(!readingResult.safeParse({schema_version:2,pages:[{index:0,items:[invalid]}]}).success);
  assert(!readingResult.safeParse({schema_version:2,pages:[{index:0,items:[item,item]}]}).success);
});
Deno.test("A17/A18 existing reading receipt reservation prevents unknown attempt re-execution",async()=>{
  const keys={READING_AI_ENABLED:"true",READING_AI_USER_IDS:attempt,READING_WORKER_URL:"https://fixture.invalid",STUDY_WORKER_SECRET:"synthetic-test-only-0000000000000000"};
  const before=Object.fromEntries(Object.keys(keys).map(k=>[k,Deno.env.get(k)]));
  try{
    for(const[k,v]of Object.entries(keys))Deno.env.set(k,v);
    let called=0;
    const job={user_id:attempt,request_id:attempt,attempts:1,object_paths:[`${attempt}/${attempt}/p0.jpg`],subject_id:null,range_text:null};
    const out=await callEngine(job,<T>(name:string)=>{assertEquals(name,"reading_ai_begin");return Promise.resolve({claimed:false} as T);},(()=>{called++;throw new Error("unexpected fetch");}) as typeof fetch);
    assertEquals(out.reason,"reconciliation_required");assertEquals(called,0);
    await assertRejects(()=>callEngine({...job,object_paths:["other/private.jpg"]}));
  }finally{for(const[k,v]of Object.entries(before)){if(v===undefined)Deno.env.delete(k);else Deno.env.set(k,v);}}
});
