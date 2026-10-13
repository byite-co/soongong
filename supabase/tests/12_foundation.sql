-- Real Postgres transactions, not a fake ledger. Fixtures roll back completely.
begin;
select no_plan();
create or replace function public.study_now() returns timestamptz language sql volatile set search_path='' as $$ select '2026-10-31T14:59:59Z'::timestamptz $$;
insert into auth.users(id) values('aaaaaaaa-0000-4000-8000-000000000101'),('bbbbbbbb-0000-4000-8000-000000000101');
insert into public.profiles(user_id,consent_account_at,consent_reading_at) values
 ('aaaaaaaa-0000-4000-8000-000000000101',now(),now()),('bbbbbbbb-0000-4000-8000-000000000101',now(),now());
select set_config('request.jwt.claim.sub','aaaaaaaa-0000-4000-8000-000000000101',true);
create function pg_temp.tr() returns jsonb language sql as $$ select '{"schema_version":1,"kind":"text","engine":"synthetic","blocks":[{"text":"private fixture","box":[0,0,1,1],"confidence":null}]}'::jsonb $$;
select is(public.study_save_v1(0,'10000000-0000-4000-8000-000000000101',null,'text','bounded title','private fixture',pg_temp.tr())->>'revision','1','FD-06 confirmed body saved at server revision 1');
select ok((public.study_metadata_v1(0)::text not like '%private fixture%'),'FD-04 metadata does not contain full source');
select ok((public.study_metadata_v1(0)::text not like '%transcription%'),'FD-04 metadata has no large JSON');
select is(public.study_body_v1(0,'10000000-0000-4000-8000-000000000101',1)->>'text','private fixture','FD-05 only selected body retrieved');
select throws_ok($$select public.study_save_v1(0,'10000000-0000-4000-8000-000000000101',0,'text','x','x',pg_temp.tr())$$,'P0001','revision_conflict','FD-06 stale revision rejected');
select throws_ok($$select public.study_save_v1(0,'10000000-0000-4000-8000-000000000102',null,'text',repeat('x',81),'x',pg_temp.tr())$$,'P0001','invalid_payload','FD-04 title cannot carry unlimited source');
select throws_ok($$select public.study_body_v1(1,'10000000-0000-4000-8000-000000000101',1)$$,'P0001','stale_epoch','FD-07 epoch mismatch denied');
select set_config('request.jwt.claim.sub','bbbbbbbb-0000-4000-8000-000000000101',true);
select throws_ok($$select public.study_body_v1(0,'10000000-0000-4000-8000-000000000101',1)$$,'P0001','body_unavailable','FD-03 B cannot get A body');
select is(jsonb_array_length(public.study_metadata_v1(0)->'rows'),0,'FD-03 B list empty');
select set_config('request.jwt.claim.sub','aaaaaaaa-0000-4000-8000-000000000101',true);
select is((select count(*) from public.sync_tables),12::bigint,'FD-08 body not inserted into D2 tables');
select ok(not has_function_privilege('anon','public.study_body_v1(integer,uuid,integer)','EXECUTE'),'FD-03 anon no body RPC');
select ok(not has_function_privilege('authenticated','public.ai_grant(uuid,text,text,integer,timestamptz)','EXECUTE'),'FD-14 client cannot grant points');
select ok(not has_function_privilege('authenticated','public.ai_reserve(uuid,integer,uuid,uuid,text,text,uuid,integer)','EXECUTE'),'FD-03 client cannot forge service user');
select ok(not has_table_privilege('authenticated','public.ai_costs','SELECT'),'FD-27 costs private');
select ok(not has_table_privilege('authenticated','public.study_bodies','SELECT'),'FD-03 direct body table closed');
select ok((select bool_and(relrowsecurity) from pg_class where relnamespace='public'::regnamespace and relname in ('study_documents','study_bodies','study_photo_assets','ai_jobs','ai_point_lots','ai_costs')),'FD-03 new exposed tables enable RLS');
select throws_ok($$select public.ai_quote('aaaaaaaa-0000-4000-8000-000000000101',0,'ocr_text')$$,'P0001','policy_unavailable','FD-01 missing policy closed');

-- Exercise actual database roles in addition to catalog privilege assertions.
set local role authenticated;
select is(public.study_body_v1(0,'10000000-0000-4000-8000-000000000101',1)->>'text','private fixture','FD-03 authenticated A allowed own RPC');
select throws_ok($$select * from public.study_bodies$$,'42501',null,'FD-03 direct table forbidden with actual role');
select throws_ok($$select public.ai_grant('aaaaaaaa-0000-4000-8000-000000000101','purchase','forged',500,null)$$,'42501',null,'FD-14 authenticated cannot grant');
reset role;
set local role anon;
select throws_ok($$select public.study_body_v1(0,'10000000-0000-4000-8000-000000000101',1)$$,'42501',null,'FD-03 actual anon body RPC forbidden');
reset role;
select ok(not public.study_valid_transcription(jsonb_set(pg_temp.tr(),'{schema_version}','"1"'),'text'),'FD-02 string version not numeric v1');

-- Explicit synthetic terms/prices. No policy/grant is shipped in migrations.
insert into public.ai_policies(id,operation,enabled,provider,model,points,terms_version,charge_order,result_ttl_seconds,max_input_tokens,max_output_tokens,max_attempts,input_price,output_price,fixed_price,currency,price_version,fx_version,fx_at,krw_per_currency,lease_seconds)
values('20000000-0000-4000-8000-000000000101','ocr_text',true,'test-only','fixture',3,'test-terms','earliest_expiry',3600,100,50,1,.001,.002,0,'USD','test-price','test-fx',now(),1000,60),
('20000000-0000-4000-8000-000000000102','solve',true,'test-only','fixture',7,'test-terms','earliest_expiry',3600,100,50,1,.001,.002,0,'USD','test-price','test-fx',now(),1000,60);
select public.ai_budget_set('2026-10-01',300000,100000,.8);
select throws_ok($$select public.ai_budget_set('2026-10-01',300001,0,.8)$$,'P0001','budget_invalid','FD-19 above 300000 rejected');
select public.ai_grant('aaaaaaaa-0000-4000-8000-000000000101','subscription','synthetic-period',10,null);
select public.ai_grant('aaaaaaaa-0000-4000-8000-000000000101','subscription','synthetic-period',10,null);
select is((select sum(granted) from public.ai_point_lots),10::bigint,'FD-14 identical grant once');
select throws_ok($$select public.ai_grant('aaaaaaaa-0000-4000-8000-000000000101','subscription','synthetic-period',11,null)$$,'P0001','grant_conflict','FD-14 changed duplicate grant denied');
select is(public.ai_quote('aaaaaaaa-0000-4000-8000-000000000101',0,'ocr_text')->>'points','3','FD-15 OCR cost from server');
select is(public.ai_quote('aaaaaaaa-0000-4000-8000-000000000101',0,'solve')->>'points','7','FD-15 different solve cost');
select throws_ok($$update public.ai_policies set points=50 where operation='ocr_text'$$,'P0001','immutable_policy','FD-15 quoted price immutable');
create temp table fd_jobs(name text primary key,id uuid);
insert into fd_jobs select 'success',(public.ai_reserve('aaaaaaaa-0000-4000-8000-000000000101',0,'30000000-0000-4000-8000-000000000101','20000000-0000-4000-8000-000000000101','ocr_text',repeat('a',64),null,null)->>'job_id')::uuid;
select is((public.ai_reserve('aaaaaaaa-0000-4000-8000-000000000101',0,'30000000-0000-4000-8000-000000000101','20000000-0000-4000-8000-000000000101','ocr_text',repeat('a',64),null,null)->>'job_id')::uuid,(select id from fd_jobs where name='success'),'FD-12 same request returns same durable job');
select is((select sum(reserved) from public.ai_point_lots),3::bigint,'FD-12 reserve exactly once');
select throws_ok($$select public.ai_reserve('aaaaaaaa-0000-4000-8000-000000000101',0,'30000000-0000-4000-8000-000000000101','20000000-0000-4000-8000-000000000101','ocr_text',repeat('b',64),null,null)$$,'P0001','request_conflict','FD-12 input mismatch conflicts');
select is(public.ai_dispatch('aaaaaaaa-0000-4000-8000-000000000101',0,(select id from fd_jobs where name='success'))->>'claimed','true','FD-12 first dispatch eligible');
select is(public.ai_dispatch('aaaaaaaa-0000-4000-8000-000000000101',0,(select id from fd_jobs where name='success'))->>'claimed','false','FD-12 second dispatch cannot recall supplier');
select throws_ok($$select public.ai_finish((select id from fd_jobs where name='success'),'succeeded','{}')$$,'P0001','invalid_engine_result','FD-16 invalid result transaction does not charge');
select is((select sum(remaining) from public.ai_point_lots),10::bigint,'FD-16 result failure preserves balance');
select is(public.ai_finish((select id from fd_jobs where name='success'),'succeeded',pg_temp.tr())->>'state','succeeded','FD-16 result and charge commit together');
select public.ai_finish((select id from fd_jobs where name='success'),'succeeded',pg_temp.tr());
select is((select sum(remaining) from public.ai_point_lots),7::bigint,'FD-16 duplicate completion charge once');
select is((select count(*) from public.ai_point_ledger where kind='settle'),1::bigint,'FD-16 one final ledger event');
select is((select status from public.ai_costs where job_id=(select id from fd_jobs where name='success')),'unknown','FD-17 usage absence never zero cost');
create or replace function public.study_now() returns timestamptz language sql volatile set search_path='' as $$ select '2026-10-31T15:00:01Z'::timestamptz $$;
select public.ai_reconcile((select id from fd_jobs where name='success'),'40000000-0000-4000-8000-000000000101',.12,'{"input_tokens":100,"output_tokens":10}');
select public.ai_reconcile((select id from fd_jobs where name='success'),'40000000-0000-4000-8000-000000000101',.12,'{"input_tokens":100,"output_tokens":10}');
select is((select spent_krw from public.ai_budgets where month='2026-10-01'),120::numeric,'FD-20 late settlement goes to original KST month once');
select is((select reserved_krw from public.ai_budgets where month='2026-10-01'),0::numeric,'FD-20 original reservation released');
select is((select count(*) from public.ai_budgets where month='2026-11-01'),0::bigint,'FD-20 never moved into next month');
select throws_ok($$select public.ai_reconcile((select id from fd_jobs where name='success'),'40000000-0000-4000-8000-000000000101',.13,'{}')$$,'P0001','settlement_conflict','FD-20 changed repeated settlement denied');

-- Restore assets use a separate trusted clock and separate deletion obligations.
select is(public.study_photo_register_v1(0,'10000000-0000-4000-8000-000000000101','50000000-0000-4000-8000-000000000101')->>'available','true','FD-21 first server asset available');
create temp table fd_photo as select * from public.study_photo_assets;
create or replace function public.study_now() returns timestamptz language sql volatile set search_path='' as $$ select '2026-11-30T15:00:00Z'::timestamptz $$;
select is(public.study_photo_register_v1(0,'10000000-0000-4000-8000-000000000101','50000000-0000-4000-8000-000000000101')->>'available','true','FD-21 one second before expiry');
select is((select first_stored_at from public.study_photo_assets),(select first_stored_at from fd_photo),'FD-21 retry does not extend first stored');
create or replace function public.study_now() returns timestamptz language sql volatile set search_path='' as $$ select '2026-11-30T15:00:01Z'::timestamptz $$;
select throws_ok($$select public.study_photo_access('aaaaaaaa-0000-4000-8000-000000000101',0,'50000000-0000-4000-8000-000000000101')$$,'P0001','asset_unavailable','FD-21 exact expiry blocks new access');
select is(public.study_photo_expire(),1,'FD-21 expiration enqueues deletion');
select is((select count(*) from public.study_bodies),1::bigint,'FD-21 expiration preserves confirmed body');
select is((select count(*) from public.study_object_claim(10)),1::bigint,'FD-22 cleanup claim real database');
select is((select status from public.study_object_deletions),'pending','FD-22 claim is not bytes-deleted acknowledgement');
select is((select count(*) from public.study_object_claim(10)),0::bigint,'FD-22 failure retains bounded backoff');
select public.study_delete_v1(0,'10000000-0000-4000-8000-000000000101');
select is((select count(*) from public.study_object_deletions),1::bigint,'FD-22 obligation survives document deletion and is deduplicated');
select throws_ok($$select public.study_save_v1(0,'10000000-0000-4000-8000-000000000101',null,'text','x','x',pg_temp.tr())$$,'P0001','document_deleted','FD-06 deleted ID never resurrected');
select public.study_object_done(array(select id from public.study_object_deletions));
select is((select status from public.study_object_deletions),'done','FD-22 worker acknowledgement marks completion');

select public.purge_all('aaaaaaaa-0000-4000-8000-000000000101','60000000-0000-4000-8000-000000000101',0);
select is((select sum(remaining) from public.ai_point_lots),7::bigint,'FD-24 purge preserves paid balance');
select is((select count(*) from public.ai_point_ledger where kind='grant'),1::bigint,'FD-24 purge preserves grant receipt');
select is((select spent_krw from public.ai_budgets where month='2026-10-01'),120::numeric,'FD-24 purge preserves monthly cost');
select is((select count(*) from public.ai_jobs where result is not null or input_digest is not null),0::bigint,'FD-24 purge removes content and digest');
select public.ai_grant('aaaaaaaa-0000-4000-8000-000000000101','subscription','synthetic-period',10,null);
select is((select sum(remaining) from public.ai_point_lots),7::bigint,'FD-24 purge cannot repeat subscription grant');
select public.delete_account_data('aaaaaaaa-0000-4000-8000-000000000101');
select throws_ok($$select public.study_metadata_v1(1)$$,'P0001','no_profile','FD-25 remaining JWT cannot access deleted account');
select throws_ok($$select public.ai_grant('aaaaaaaa-0000-4000-8000-000000000101','purchase','late',100,null)$$,'P0001','no_profile','FD-25 late callback cannot recreate wallet');
select is((select count(*) from public.ai_jobs where user_id is not null),0::bigint,'FD-25 remaining cost obligation detached from account');
select is((select spent_krw from public.ai_budgets where month='2026-10-01'),120::numeric,'FD-25 account deletion preserves anonymous cost');
select * from finish();
rollback;
