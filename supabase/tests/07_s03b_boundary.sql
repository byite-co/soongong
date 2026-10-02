-- pgTAP · S03b 0010 — account boundary of the reading ledger (D16: (user_id, request_id)).
-- Accounts A and B hold a request with the SAME request_id. Everything B does to it
-- must leave A untouched, and A's result must never be visible through B.
-- (D17 allows one active request per account, so X · Y · Z run one after another.)
begin;
select plan(39);

insert into auth.users (id, email) values
  ('dddddddd-0000-4000-8000-00000000000a', 'bound-a@test.local'),
  ('dddddddd-0000-4000-8000-00000000000b', 'bound-b@test.local');
insert into public.profiles (user_id, consent_reading_version, consent_reading_at) values
  ('dddddddd-0000-4000-8000-00000000000a', 'r1', now()),
  ('dddddddd-0000-4000-8000-00000000000b', 'r1', now());
insert into public.reading_quota (user_id, month, used, reserved) values
  ('dddddddd-0000-4000-8000-00000000000a', public.kst_month(now()), 0, 1),
  ('dddddddd-0000-4000-8000-00000000000b', public.kst_month(now()), 0, 1);

-- helper: the same request_id in both accounts, both processing, one job each (A's job older)
create or replace function pg_temp.open_pair(p_req text, p_id_a text, p_id_b text) returns void language plpgsql as $$
begin
  insert into public.reading_requests (id, user_id, created_at, client_updated_at, device_id, server_seq, request_id, subject_id, range_text, origin, status, submitted_at, quota_month)
  values
    (p_id_a, 'dddddddd-0000-4000-8000-00000000000a', public.iso_utc(now() - interval '2 minutes'), public.iso_utc(now() - interval '2 minutes'), 'dev-a', 1, p_req,
     '50000000-0000-4000-8000-000000000001', 'p.1', 'home', 'processing', public.iso_utc(now() - interval '2 minutes'), public.kst_month(now())),
    (p_id_b, 'dddddddd-0000-4000-8000-00000000000b', public.iso_utc(now() - interval '2 minutes'), public.iso_utc(now() - interval '2 minutes'), 'dev-b', 1, p_req,
     '50000000-0000-4000-8000-000000000001', 'p.1', 'home', 'processing', public.iso_utc(now() - interval '2 minutes'), public.kst_month(now()));
  insert into public.reading_jobs (request_id, user_id, deadline, lease_until, attempts, object_paths, created_at) values
    (p_req, 'dddddddd-0000-4000-8000-00000000000a', now() + interval '10 minutes', null, 0, array['dddddddd-0000-4000-8000-00000000000a/' || p_req || '/p0.jpg'], now() - interval '2 seconds'),
    (p_req, 'dddddddd-0000-4000-8000-00000000000b', now() + interval '10 minutes', null, 0, array['dddddddd-0000-4000-8000-00000000000b/' || p_req || '/p0.jpg'], now() - interval '1 second');
  update public.reading_quota set reserved = 1 where user_id in ('dddddddd-0000-4000-8000-00000000000a', 'dddddddd-0000-4000-8000-00000000000b');
end $$;
grant execute on function pg_temp.open_pair(text, text, text) to service_role;

select col_is_pk('public', 'reading_jobs', array['user_id', 'request_id'], 'reading_jobs primary key is (user_id, request_id)');
select has_index('public', 'photo_delete_queue', 'photo_delete_queue_user_request', 'photo_delete_queue indexed by (user_id, request_id)');
select throws_ok($$select public.reading_finish('e1000000-0000-4000-8000-000000000001', 'done', '{}'::jsonb)$$, '42883', null, 'old request_id-only reading_finish signature is gone');
select throws_ok($$select public.photo_delete_done('e1000000-0000-4000-8000-000000000001', array['x'])$$, '42883', null, 'old photo_delete_done(request_id, paths) signature is gone');

-- X: both accounts processing, same request_id ---------------------------------------------------
select lives_ok($$select pg_temp.open_pair('e1000000-0000-4000-8000-000000000001', 'e1a00000-0000-4000-8000-000000000001', 'e1b00000-0000-4000-8000-000000000001')$$,
  'two accounts may hold a job for the same request_id (composite key)');
select is((select count(*) from public.reading_jobs where request_id = 'e1000000-0000-4000-8000-000000000001'), 2::bigint, 'X: one job per account');

set local role service_role;

-- B cancels X → only (B, X) changes
select is(public.reading_finish('dddddddd-0000-4000-8000-00000000000b', 'e1000000-0000-4000-8000-000000000001', 'cancelled', null, 'user_cancel') ->> 'outcome',
  'cancelled', 'B cancels X → cancelled');
select results_eq($$select status::text, server_version from public.reading_requests where id = 'e1a00000-0000-4000-8000-000000000001'$$,
  $$values ('processing'::text, 1)$$, 'A''s X is still processing (status · version unchanged)');
select results_eq($$select reserved from public.reading_quota where user_id = 'dddddddd-0000-4000-8000-00000000000a'$$, $$values (1)$$, 'A''s reservation unchanged');
select results_eq($$select reserved from public.reading_quota where user_id = 'dddddddd-0000-4000-8000-00000000000b'$$, $$values (0)$$, 'B''s reservation released');
select results_eq($$select user_id::text from public.reading_jobs where request_id = 'e1000000-0000-4000-8000-000000000001'$$,
  $$values ('dddddddd-0000-4000-8000-00000000000a'::text)$$, 'only B''s job for X was removed; A''s job stays');
select results_eq($$select user_id::text, bucket_path from public.photo_delete_queue where request_id = 'e1000000-0000-4000-8000-000000000001'$$,
  $$values ('dddddddd-0000-4000-8000-00000000000b'::text, 'dddddddd-0000-4000-8000-00000000000b/e1000000-0000-4000-8000-000000000001/p0.jpg')$$,
  'only B''s photo was queued, under B''s user_id');
select is(public.photo_delete_done('dddddddd-0000-4000-8000-00000000000a', 'e1000000-0000-4000-8000-000000000001', array['dddddddd-0000-4000-8000-00000000000b/e1000000-0000-4000-8000-000000000001/p0.jpg']), 0,
  'A cannot mark B''s queue row done (same request_id)');
select is(public.photo_delete_done('dddddddd-0000-4000-8000-00000000000b', 'e1000000-0000-4000-8000-000000000001', array['dddddddd-0000-4000-8000-00000000000b/e1000000-0000-4000-8000-000000000001/p0.jpg']), 1,
  'B marks its own row done');

-- A completes X → B sees no result
select is(public.reading_finish('dddddddd-0000-4000-8000-00000000000a', 'e1000000-0000-4000-8000-000000000001', 'done', '{"pages":[{"index":0,"items":[{"number":1,"mark":"wrong","confidence":0.9}]}]}'::jsonb) ->> 'outcome',
  'done', 'A finishes X → done');
select results_eq($$select status::text, result_json is not null, quota_charged from public.reading_requests where id = 'e1a00000-0000-4000-8000-000000000001'$$,
  $$values ('done_unsaved'::text, true, true)$$, 'A''s X is done_unsaved with a result');
select results_eq($$select status::text, result_json is null from public.reading_requests where id = 'e1b00000-0000-4000-8000-000000000001'$$,
  $$values ('cancelled'::text, true)$$, 'B''s X stays cancelled without a result');
select results_eq($$select x ->> 'status', x -> 'result_json' from public.reading_status('dddddddd-0000-4000-8000-00000000000b', 'e1000000-0000-4000-8000-000000000001') x$$,
  $$values ('cancelled'::text, 'null'::jsonb)$$, 'reading-status for B shows no result of A');
select is(public.reading_status('dddddddd-0000-4000-8000-00000000000a', 'e1000000-0000-4000-8000-000000000001') -> 'result_json' -> 'pages' -> 0 -> 'items' -> 0 ->> 'mark', 'wrong', 'reading-status for A shows A''s result');
select results_eq($$select used, reserved from public.reading_quota where user_id = 'dddddddd-0000-4000-8000-00000000000a'$$, $$values (1, 0)$$, 'A charged once');
select results_eq($$select used, reserved from public.reading_quota where user_id = 'dddddddd-0000-4000-8000-00000000000b'$$, $$values (0, 0)$$, 'B not charged by A''s completion');
select is(public.reading_save('dddddddd-0000-4000-8000-00000000000b', 'e1000000-0000-4000-8000-000000000001', '[]'::jsonb, '[]'::jsonb) ->> 'outcome', 'not_unsaved', 'B cannot save A''s result through the shared request_id');
select is(public.reading_discard('dddddddd-0000-4000-8000-00000000000b', 'e1000000-0000-4000-8000-000000000001') ->> 'outcome', 'not_unsaved', 'B cannot discard A''s result through the shared request_id');
select is((select count(*) from public.reading_jobs where request_id = 'e1000000-0000-4000-8000-000000000001'), 0::bigint, 'X: both jobs gone after both terminal transitions');

-- Y: worker claim keyed by (user_id, request_id), reaper per pair ---------------------------------------
select pg_temp.open_pair('e1000000-0000-4000-8000-000000000002', 'e1a00000-0000-4000-8000-000000000002', 'e1b00000-0000-4000-8000-000000000002');
select results_eq($$select x ->> 'user_id', x ->> 'request_id' from public.reading_claim_job() x$$,
  $$values ('dddddddd-0000-4000-8000-00000000000a'::text, 'e1000000-0000-4000-8000-000000000002'::text)$$, 'claim #1 → (A, Y) (older job)');
select results_eq($$select x ->> 'user_id', x ->> 'request_id' from public.reading_claim_job() x$$,
  $$values ('dddddddd-0000-4000-8000-00000000000b'::text, 'e1000000-0000-4000-8000-000000000002'::text)$$, 'claim #2 → (B, Y) — same request_id, other account');
select is(public.reading_claim_job(), null, 'claim #3 → nothing (both leased)');
update public.reading_jobs set deadline = now() - interval '1 minute' where user_id = 'dddddddd-0000-4000-8000-00000000000a' and request_id = 'e1000000-0000-4000-8000-000000000002';
select results_eq($$select f ->> 'user_id', f ->> 'request_id' from jsonb_array_elements(public.reading_reaper_run() -> 'finished') f$$,
  $$values ('dddddddd-0000-4000-8000-00000000000a'::text, 'e1000000-0000-4000-8000-000000000002'::text)$$, 'reaper finishes only (A, Y) whose deadline passed');
select results_eq($$select status::text from public.reading_requests where id = 'e1b00000-0000-4000-8000-000000000002'$$, $$values ('taking_long'::text)$$, '(B, Y) untouched by A''s timeout (only the 60 s taking_long flip)');
select results_eq($$select count(*) from public.reading_jobs where request_id = 'e1000000-0000-4000-8000-000000000002'$$, $$values (1::bigint)$$, 'B''s Y job still exists');
update public.reading_jobs set deadline = now() - interval '1 minute' where user_id = 'dddddddd-0000-4000-8000-00000000000b' and request_id = 'e1000000-0000-4000-8000-000000000002';
select results_eq($$select f ->> 'user_id', f ->> 'request_id' from jsonb_array_elements(public.reading_reaper_run() -> 'finished') f$$,
  $$values ('dddddddd-0000-4000-8000-00000000000b'::text, 'e1000000-0000-4000-8000-000000000002'::text)$$, 'reaper then finishes (B, Y) independently');
select results_eq($$select status::text, fail_reason::text from public.reading_requests where request_id = 'e1000000-0000-4000-8000-000000000002' order by user_id$$,
  $$values ('failed'::text, 'timeout'::text), ('failed'::text, 'timeout'::text)$$, 'both Y requests failed/timeout, each by its own reaper pass');
select results_eq($$select user_id::text, count(*) from public.photo_delete_queue where request_id = 'e1000000-0000-4000-8000-000000000002' group by user_id order by 1$$,
  $$values ('dddddddd-0000-4000-8000-00000000000a'::text, 1::bigint), ('dddddddd-0000-4000-8000-00000000000b'::text, 1::bigint)$$, 'each account''s Y photo queued under its own user_id');
select is(jsonb_array_length(public.reading_reaper_run() -> 'finished'), 0, 'reaper idempotent afterwards');

-- Z: purge-all / delete-account only touch the caller's jobs and requests ----------------------------
select pg_temp.open_pair('e1000000-0000-4000-8000-000000000003', 'e1a00000-0000-4000-8000-000000000003', 'e1b00000-0000-4000-8000-000000000003');
select is(jsonb_array_length(public.purge_all('dddddddd-0000-4000-8000-00000000000a') -> 'object_paths'), 1, 'purge-all(A) cancels A''s active Z only (1 path)');
select results_eq($$select user_id::text from public.reading_jobs where request_id = 'e1000000-0000-4000-8000-000000000003'$$,
  $$values ('dddddddd-0000-4000-8000-00000000000b'::text)$$, 'B''s Z job survives A''s purge-all');
select results_eq($$select status::text from public.reading_requests where id = 'e1b00000-0000-4000-8000-000000000003'$$, $$values ('processing'::text)$$, 'B''s Z request survives A''s purge-all');
select results_eq($$with d as (select public.delete_account_data('dddddddd-0000-4000-8000-00000000000b') as r)
  select count(distinct p), bool_and(p like 'dddddddd-0000-4000-8000-00000000000b/%') from d, jsonb_array_elements_text(d.r -> 'object_paths') p$$,
  $$values (2::bigint, true)$$, 'delete-account(B) returns B''s Z path + B''s still-pending Y path, none of A''s');
select is((select count(*) from public.reading_jobs where request_id like 'e1000000-%'), 0::bigint, 'no jobs left after both accounts closed their requests');

select * from finish();
rollback;
