-- pgTAP · D24 permission boundary — the 10 negative cases of S03 §4.2-8.
-- Run: supabase/tests/local/run.sh supabase/tests/01_rls.sql
begin;
select plan(44);

-- fixtures -----------------------------------------------------------------
insert into auth.users (id, email) values
  ('aaaaaaaa-0000-4000-8000-000000000001', 'u1@test.local'),
  ('aaaaaaaa-0000-4000-8000-000000000002', 'u2@test.local'),
  ('aaaaaaaa-0000-4000-8000-000000000003', 'noprofile@test.local');
insert into public.profiles (user_id) values
  ('aaaaaaaa-0000-4000-8000-000000000001'), ('aaaaaaaa-0000-4000-8000-000000000002');
insert into public.subscription_state (user_id, status, has_history) values ('aaaaaaaa-0000-4000-8000-000000000001', 'free', false);
insert into public.reading_quota (user_id, month, used, reserved) values ('aaaaaaaa-0000-4000-8000-000000000001', '2026-10', 3, 0);
insert into public.sessions (id, user_id, created_at, client_updated_at, device_id, server_seq, kind, mode, started_at, status, seated_seconds, sensitivity_level)
values ('bbbbbbbb-0000-4000-8000-000000000001', 'aaaaaaaa-0000-4000-8000-000000000001', '2026-09-30T00:00:00.000Z', '2026-09-30T00:00:00.000Z', 'd', 1, 'study', 'camera', '2026-09-30T00:00:00.000Z', 'finished', 600, 0),
       ('bbbbbbbb-0000-4000-8000-000000000002', 'aaaaaaaa-0000-4000-8000-000000000002', '2026-09-30T00:00:00.000Z', '2026-09-30T00:00:00.000Z', 'd', 1, 'study', 'camera', '2026-09-30T00:00:00.000Z', 'finished', 600, 0);
insert into public.reading_requests (id, user_id, created_at, client_updated_at, device_id, server_seq, request_id, subject_id, range_text, origin, status, submitted_at, payload_hash, quota_month)
values ('cccccccc-0000-4000-8000-000000000001', 'aaaaaaaa-0000-4000-8000-000000000001', '2026-09-30T00:00:00.000Z', '2026-09-30T00:00:00.000Z', 'd', 2,
        'cccccccc-0000-4000-8000-000000000001', 'dddddddd-0000-4000-8000-000000000001', 'p.12', 'home', 'processing', '2026-09-30T00:00:00.000Z', 'h', '2026-10');

-- helper to act as a JWT user
create or replace function pg_temp.as_user(p_uid text, p_role text default 'authenticated') returns void language plpgsql as $$
begin
  execute format('set local role %I', p_role);
  perform set_config('request.jwt.claims', json_build_object('sub', p_uid, 'role', p_role)::text, true);
end $$;

-- ① subscription_state update ------------------------------------------------
select pg_temp.as_user('aaaaaaaa-0000-4000-8000-000000000001');
select throws_ok($$update public.subscription_state set status = 'premium' where user_id = 'aaaaaaaa-0000-4000-8000-000000000001'$$,
  '42501', null, '① authenticated cannot update subscription_state');
select results_eq($$select count(*) from public.subscription_state$$, $$values (1::bigint)$$, '① own ledger row is readable');
-- ② reading_quota update / insert ---------------------------------------------
select throws_ok($$update public.reading_quota set used = 0 where user_id = 'aaaaaaaa-0000-4000-8000-000000000001'$$,
  '42501', null, '② authenticated cannot update reading_quota');
select throws_ok($$insert into public.reading_quota (user_id, month) values ('aaaaaaaa-0000-4000-8000-000000000001', '2026-11')$$,
  '42501', null, '② authenticated cannot insert reading_quota');
-- ③ other users' rows ------------------------------------------------------------
select results_eq($$select id::text from public.sessions order by id$$,
  $$values ('bbbbbbbb-0000-4000-8000-000000000001')$$, '③ select sees only own sessions');
select throws_ok($$update public.sessions set note = 'x' where id = 'bbbbbbbb-0000-4000-8000-000000000002'$$,
  '42501', null, '③ update of any sessions row is denied (no update policy/grant)');
-- ④ reading_requests.status direct change --------------------------------------------
select throws_ok($$update public.reading_requests set status = 'saved' where id = 'cccccccc-0000-4000-8000-000000000001'$$,
  '42501', null, '④ status cannot be changed directly');
-- ⑥ direct insert ------------------------------------------------------------------------
select throws_ok($$insert into public.sessions (id, user_id, created_at, client_updated_at, device_id, server_seq, kind, mode, started_at, status, seated_seconds, sensitivity_level)
  values ('bbbbbbbb-0000-4000-8000-000000000009', 'aaaaaaaa-0000-4000-8000-000000000001', '2026-09-30T00:00:00.000Z', '2026-09-30T00:00:00.000Z', 'd', 9, 'study', 'camera', '2026-09-30T00:00:00.000Z', 'finished', 1, 0)$$,
  '42501', null, '⑥ direct insert into sessions is denied');
select throws_ok($$delete from public.sessions where id = 'bbbbbbbb-0000-4000-8000-000000000001'$$,
  '42501', null, '⑥ direct delete is denied');
-- ⑦ sync_push with a ledger table name -----------------------------------------------------
select is((public.sync_push(0, '[{"table":"reading_quota","id":"x","mutation_id":"eeeeeeee-0000-4000-8000-000000000001","base_server_version":null,"data":{"used":0}}]'::jsonb) -> 'rejected' -> 0 ->> 'reason'),
  'invalid_table', '⑦ ledger table name is rejected as invalid_table');
select is((public.sync_push(0, '[{"table":"inquiries","id":"x","mutation_id":"eeeeeeee-0000-4000-8000-000000000002","base_server_version":null,"data":{"body":"hi"}}]'::jsonb) -> 'rejected' -> 0 ->> 'reason'),
  'invalid_table', '⑦ inquiries is not a sync table');
-- ⑧ server column in data → invalid_columns -------------------------------------------------
select is((public.sync_push(0, '[{"table":"reading_requests","id":"cccccccc-0000-4000-8000-000000000003","mutation_id":"eeeeeeee-0000-4000-8000-000000000003","base_server_version":null,"data":{"request_id":"cccccccc-0000-4000-8000-000000000003","subject_id":"dddddddd-0000-4000-8000-000000000001","range_text":"p.1","origin":"home","status":"saved","created_at":"2026-09-30T00:00:00.000Z","client_updated_at":"2026-09-30T00:00:00.000Z","device_id":"d","purge_epoch":0}}]'::jsonb) -> 'rejected' -> 0 ->> 'reason'),
  'invalid_columns', '⑧ reading_requests.status in data → invalid_columns');
select is((public.sync_push(0, '[{"table":"sessions","id":"bbbbbbbb-0000-4000-8000-000000000001","mutation_id":"eeeeeeee-0000-4000-8000-000000000004","base_server_version":1,"data":{"note":"x","server_version":9}}]'::jsonb) -> 'rejected' -> 0 ->> 'reason'),
  'invalid_columns', '⑧ server_version in data → invalid_columns');
select is((public.sync_push(0, '[{"table":"wrong_items","id":"ffffffff-0000-4000-8000-000000000001","mutation_id":"eeeeeeee-0000-4000-8000-000000000005","base_server_version":1,"data":{"status":"resolved","mark":"wrong"}}]'::jsonb) -> 'rejected' -> 0 ->> 'reason'),
  'invalid_columns', '⑧ wrong_items content column outside §7 ② → invalid_columns');
-- ⑨ user_id key → invalid_columns ----------------------------------------------------------------
select is((public.sync_push(0, '[{"table":"sessions","id":"bbbbbbbb-0000-4000-8000-000000000001","mutation_id":"eeeeeeee-0000-4000-8000-000000000006","base_server_version":1,"data":{"note":"x","user_id":"aaaaaaaa-0000-4000-8000-000000000002"}}]'::jsonb) -> 'rejected' -> 0 ->> 'reason'),
  'invalid_columns', '⑨ user_id in data → invalid_columns');
select is((select note from public.sessions where id = 'bbbbbbbb-0000-4000-8000-000000000001'), null, '⑨ the rejected row did not change');
-- ⑩ service functions with a user JWT → denied -----------------------------------------------------
select throws_ok($$select public.reading_finish('aaaaaaaa-0000-4000-8000-000000000001', 'cccccccc-0000-4000-8000-000000000001', 'done', '{}'::jsonb)$$, '42501', null, '⑩ reading_finish denied to authenticated');
select throws_ok($$select public.reading_submit('aaaaaaaa-0000-4000-8000-000000000001', 'cccccccc-0000-4000-8000-000000000001', '{}'::jsonb)$$, '42501', null, '⑩ reading_submit denied to authenticated');
select throws_ok($$select public.reading_status('aaaaaaaa-0000-4000-8000-000000000001', 'cccccccc-0000-4000-8000-000000000001')$$, '42501', null, '⑩ reading_status denied to authenticated');
select throws_ok($$select public.reading_save('aaaaaaaa-0000-4000-8000-000000000001', 'x', '[]'::jsonb, '[]'::jsonb)$$, '42501', null, '⑩ reading_save denied to authenticated');
select throws_ok($$select public.reading_update_marks('aaaaaaaa-0000-4000-8000-000000000001', 'x', '[]'::jsonb, '[]'::jsonb)$$, '42501', null, '⑩ reading_update_marks denied to authenticated');
select throws_ok($$select public.metrics_run(null)$$, '42501', null, '⑩ metrics_run denied to authenticated');
select throws_ok($$select public.review_due_snapshot_run(null)$$, '42501', null, '⑩ review_due_snapshot_run denied to authenticated');
select throws_ok($$select public.reading_reaper_run()$$, '42501', null, '⑩ reading_reaper_run denied to authenticated');
select throws_ok($$select public.next_server_seq('aaaaaaaa-0000-4000-8000-000000000001')$$, '42501', null, 'internal helper next_server_seq denied to authenticated');
select throws_ok($$select public.purge_all('aaaaaaaa-0000-4000-8000-000000000001')$$, '42501', null, 'purge_all denied to authenticated');
select throws_ok($$select public.complete_signup('aaaaaaaa-0000-4000-8000-000000000001', 'v1')$$, '42501', null, 'complete_signup denied to authenticated');
select throws_ok($$select public.before_user_created_hook('{}'::jsonb)$$, '42501', null, 'hook denied to authenticated');
select throws_ok($$select * from public.signup_passes$$, '42501', null, 'signup_passes not selectable by users');
select throws_ok($$select * from public.sync_mutations$$, '42501', null, 'sync_mutations not selectable by users');
select throws_ok($$select * from public.server_config$$, '42501', null, 'server_config not selectable by users');

-- anon ------------------------------------------------------------------------------------
reset role;
select pg_temp.as_user('', 'anon');
select throws_ok($$select public.sync_push(0, '[]'::jsonb)$$, '42501', null, 'anon cannot execute sync_push');
select throws_ok($$select public.sync_pull(0, 0, 10)$$, '42501', null, 'anon cannot execute sync_pull');

-- ⑤ token without profiles → nothing visible, RPC refused -----------------------------------
reset role;
insert into public.sessions (id, user_id, created_at, client_updated_at, device_id, server_seq, kind, mode, started_at, status, seated_seconds, sensitivity_level)
values ('bbbbbbbb-0000-4000-8000-000000000003', 'aaaaaaaa-0000-4000-8000-000000000003', '2026-09-30T00:00:00.000Z', '2026-09-30T00:00:00.000Z', 'd', 1, 'study', 'camera', '2026-09-30T00:00:00.000Z', 'finished', 600, 0);
select pg_temp.as_user('aaaaaaaa-0000-4000-8000-000000000003');
select results_eq($$select count(*) from public.sessions$$, $$values (0::bigint)$$, '⑤ no profile → own sessions invisible');
select throws_ok($$select public.sync_push(0, '[]'::jsonb)$$, 'P0001', 'no_profile', '⑤ no profile → sync_push refused');
select throws_ok($$select public.sync_pull(0, 0, 10)$$, 'P0001', 'no_profile', '⑤ no profile → sync_pull refused');
select throws_ok($$select public.profile_set_onboarding_done()$$, 'P0001', 'no_profile', '⑤ no profile → onboarding RPC refused');

-- ⑩ service_role succeeds ------------------------------------------------------------------
reset role;
set local role service_role;
select is((public.reading_finish('aaaaaaaa-0000-4000-8000-000000000001', 'cccccccc-0000-4000-8000-000000000001', 'done', '{"pages":[]}'::jsonb) ->> 'outcome'), 'done', '⑩ service_role may call reading_finish');
select is((public.reading_status('aaaaaaaa-0000-4000-8000-000000000001', 'cccccccc-0000-4000-8000-000000000001') ->> 'status'), 'done_unsaved', '⑩ service_role may call reading_status');
reset role;

-- default privileges: a brand-new function has no anon/authenticated EXECUTE
create function public._s03_probe() returns int language sql as 'select 1';
select ok(not has_function_privilege('anon', 'public._s03_probe()', 'execute')
          and not has_function_privilege('authenticated', 'public._s03_probe()', 'execute'),
  'new function has no anon/authenticated EXECUTE (default privileges revoked)');

-- D24 dump check: authenticated EXECUTE exists on exactly the 3 user RPCs (+ has_profile used by policies)
select is(
  (select string_agg(p.proname::text, ',' order by p.proname::text collate "C") from pg_proc p join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public' and has_function_privilege('authenticated', p.oid, 'execute')
      and not exists (select 1 from pg_depend d where d.objid = p.oid and d.deptype = 'e')),   -- local pgTAP lives in public
  'has_profile,profile_set_onboarding_done,sync_pull,sync_push',
  'authenticated can execute only sync_push · sync_pull · profile_set_onboarding_done (+ policy helper has_profile)');

-- partial unique indexes exist (merge check §8)
select has_index('public', 'reading_requests', 'reading_requests_one_active', 'D17 partial unique index (active)');
select has_index('public', 'reading_requests', 'reading_requests_one_unsaved', 'D17 partial unique index (unsaved)');
select has_index('public', 'review_entries', 'review_entries_live_wrong_item', '§7 ③ partial unique index');

select * from finish();
rollback;
