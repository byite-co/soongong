import {assert,assertEquals,assertThrows,assertRejects} from "@std/assert";
import {studyEnvelope} from "../_shared/study.ts";
import {signedExpiry} from "../study-photo/index.ts";
import {handle as maintenance} from "../study-maintenance/index.ts";
import {HttpError,statusForSqlError} from "../_shared/http.ts";
const input={schema_version:1,operation:"ocr",kind:"text",image:"YQ==",purge_epoch:0,consent_version:"study-2026-10-13"};
const envelope={version:2,request_id:"11111111-1111-4111-8111-111111111111",quote_id:"22222222-2222-4222-8222-222222222222",input};
Deno.test("FD-02 strict v2 rejects old envelopes, forged ledger fields, oversized input",()=>{
  assert(studyEnvelope.safeParse(envelope).success);
  for(const bad of [input,{...envelope,version:1},{...envelope,paid:true},{...envelope,points:0},{...envelope,owner:"other"},{...envelope,quote_id:"x"},{...envelope,input:{...input,image:"a".repeat(5592409)}},{...envelope,input:{...input,provider_key:"forged"}}]) assertEquals(studyEnvelope.safeParse(bad).success,false);
});
Deno.test("FD-21 Storage token expiry is inspected; missing/invalid tokens fail closed",()=>{
  const token=`e30.${btoa(JSON.stringify({exp:1000}))}.fixture`;
  assertEquals(signedExpiry(`https://fixture.invalid/download?token=${token}`),1000000);
  for(const url of ["https://fixture.invalid/no-token","https://fixture.invalid/?token=x","https://fixture.invalid/?token=e30.e30.x"]) assertThrows(()=>signedExpiry(url));
});
Deno.test("FD-02 ledger errors distinguish conflict, budget rejection and unavailable configuration",()=>{
  assertEquals(statusForSqlError("request_conflict"),409);assertEquals(statusForSqlError("budget_exceeded"),429);assertEquals(statusForSqlError("policy_unavailable"),503);
});

Deno.test("FD-03 maintenance without a correct machine secret starts no database operation",async()=>{
  const previous=Deno.env.get("JOB_SECRET");Deno.env.set("JOB_SECRET","synthetic-test-only-0000000000000000");
  try {
    for(const headers of [new Headers(), new Headers({"x-job-secret":"wrong"})]) {
      const error=await assertRejects(()=>maintenance(new Request("https://fixture.invalid/study-maintenance",{method:"POST",headers})),HttpError,"unauthorized");assertEquals(error.status,401);
    }
    assertEquals((await maintenance(new Request("https://fixture.invalid/study-maintenance",{method:"GET",headers:{"x-job-secret":"synthetic-test-only-0000000000000000"}}))).status,405);
  } finally {if(previous===undefined) Deno.env.delete("JOB_SECRET");else Deno.env.set("JOB_SECRET",previous);}
});
