-- pgTAP · D16/D17 reading ledger — reservation · completion · cancel race ·
-- month boundary · reaper · duplicate save (+ acceptance ②, worker claim,
-- update-marks, expire, purge-all, delete-account, status transitions).
begin;
select plan(76);

insert into auth.users (id, email) values
  ('aaaaaaaa-0000-4000-8000-000000000001', 'u1@test.local'),
  ('aaaaaaaa-0000-4000-8000-000000000002', 'free@test.local');
insert into public.profiles (user_id, consent_reading_version, consent_reading_at) values
  ('aaaaaaaa-0000-4000-8000-000000000001', 'r1', now()),
  ('aaaaaaaa-0000-4000-8000-000000000002', 'r1', now());
insert into public.subscription_state (user_id, expires_at, will_renew, period_type, has_history)
values ('aaaaaaaa-0000-4000-8000-000000000001', now() + interval '30 days', true, 'NORMAL', true);
insert into public.server_config (key, value) values ('functions_base_url', 'https://example.test/functions/v1'), ('job_secret', 's3cret');
set local role service_role;

create or replace function pg_temp.payload(p_req text, p_range text default 'p.1') returns jsonb language sql as $$
  select jsonb_build_object('subject_id', '50000000-0000-4000-8000-000000000001', 'range_text', p_range, 'origin', 'home',
    'object_paths', jsonb_build_array('aaaaaaaa-0000-4000-8000-000000000001/' || p_req || '/p0.jpg', 'aaaaaaaa-0000-4000-8000-000000000001/' || p_req || '/p1.jpg'))
$$;
create or replace function pg_temp.quota() returns table (used int, reserved int) language sql as $$
  select used, reserved from public.reading_quota where user_id = 'aaaaaaaa-0000-4000-8000-000000000001' and month = public.kst_month(now())
$$;

grant execute on function pg_temp.payload(text,text), pg_temp.quota() to authenticated, service_role;

-- month key (KST) ------------------------------------------------------------------------
select is(public.kst_month('2026-09-30T15:30:00Z'::timestamptz), '2026-10', 'KST month: 09-30 15:30Z → 2026-10');
select is(public.kst_month('2026-09-30T14:59:00Z'::timestamptz), '2026-09', 'KST month: 09-30 14:59Z → 2026-09');
select is(public.kst_month('2026-12-31T15:00:00Z'::timestamptz), '2027-01', 'KST month: year boundary');

-- entitlement / consent gates ------------------------------------------------------------------
select is(public.reading_submit('aaaaaaaa-0000-4000-8000-000000000002', '60000000-0000-4000-8000-00000000000f', pg_temp.payload('60000000-0000-4000-8000-00000000000f')) ->> 'outcome',
  'not_entitled', 'free user → not_entitled, nothing reserved');
select is((select count(*) from public.reading_quota where user_id = 'aaaaaaaa-0000-4000-8000-000000000002'), 0::bigint, 'free user: no quota row created');
select public.update_consent('aaaaaaaa-0000-4000-8000-000000000001', 'r1', false);
select is(public.reading_submit('aaaaaaaa-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000001', pg_temp.payload('60000000-0000-4000-8000-000000000001')) ->> 'outcome',
  'consent_required', 'revoked consent ② → consent_required');
select public.update_consent('aaaaaaaa-0000-4000-8000-000000000001', 'r1', true);
select is(public.reading_submit('aaaaaaaa-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000001',
    '{"subject_id":"50000000-0000-4000-8000-000000000001","range_text":"p.1","origin":"home","object_paths":["aaaaaaaa-0000-4000-8000-000000000002/60000000-0000-4000-8000-000000000001/p0.jpg"]}'::jsonb) ->> 'outcome',
  'invalid_payload', 'object path outside user/request prefix → invalid_payload');

-- 1. reservation ----------------------------------------------------------------------------------
select is(public.reading_submit('aaaaaaaa-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000001', pg_temp.payload('60000000-0000-4000-8000-000000000001')) ->> 'outcome',
  'accepted', '1 first submit (no synced draft) → accepted');
select results_eq($$select * from pg_temp.quota()$$, $$values (0, 1)$$, '1 reserved+1');
select results_eq($$select status::text, submitted_at is not null, quota_month = public.kst_month(now()) from public.reading_requests where request_id = '60000000-0000-4000-8000-000000000001'$$,
  $$values ('processing'::text, true, true)$$, '1 processing · submitted_at · quota_month fixed');
select results_eq($$select count(*), bool_and(lease_until is null and attempts = 0 and cardinality(object_paths) = 2) from public.reading_jobs where request_id = '60000000-0000-4000-8000-000000000001'$$,
  $$values (1::bigint, true)$$, '1 one job row (lease null, attempts 0, 2 paths)');
select results_eq($$select count(*) from net._test_requests where url like '%/reading-worker'$$, $$values (1::bigint)$$, '1 worker kick queued through pg_net');
select is(public.reading_submit('aaaaaaaa-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000001', pg_temp.payload('60000000-0000-4000-8000-000000000001')) -> 'idempotent',
  'true'::jsonb, '1 same payload again → idempotent accepted');
select results_eq($$select * from pg_temp.quota()$$, $$values (0, 1)$$, '1 repeated submit does not reserve again');
select is((select count(*) from public.reading_jobs), 1::bigint, '1 repeated submit adds no job');
select is(public.reading_submit('aaaaaaaa-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000001', pg_temp.payload('60000000-0000-4000-8000-000000000001', 'p.2')) ->> 'outcome',
  'payload_mismatch', '1 different payload on the same request_id → payload_mismatch');
select is(public.reading_submit('aaaaaaaa-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000002', pg_temp.payload('60000000-0000-4000-8000-000000000002')) ->> 'outcome',
  'active_exists', '1 another request while one is active → active_exists (D17)');

-- worker claim ------------------------------------------------------------------------------------
select is(public.reading_claim_job() ->> 'request_id', '60000000-0000-4000-8000-000000000001', 'worker claims the new job on first run');
select is(public.reading_claim_job(), null, 'second worker gets nothing while the lease is held');
select results_eq($$select attempts, lease_until > now() from public.reading_jobs$$, $$values (1, true)$$, 'claim set attempts=1 and a 3-minute lease');

-- status: taking_long after 60 s ------------------------------------------------------------------------
update public.reading_requests set submitted_at = public.iso_utc(now() - interval '90 seconds') where request_id = '60000000-0000-4000-8000-000000000001';
select is(public.reading_status('aaaaaaaa-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000001') ->> 'status', 'taking_long', 'status after 60 s → taking_long');
select is(public.reading_status('aaaaaaaa-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000001') -> 'result_json', 'null'::jsonb, 'no result_json while active');
select is(public.reading_status('aaaaaaaa-0000-4000-8000-000000000001', '99999999-0000-4000-8000-000000000001') ->> 'outcome', 'not_found', 'status of unknown id → not_found');

-- 2. completion -----------------------------------------------------------------------------------------
select is(public.reading_finish('aaaaaaaa-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000001', 'done', '{"pages":[{"index":0,"items":[{"number":1,"mark":"wrong","confidence":0.3}]}]}'::jsonb) ->> 'outcome',
  'done', '2 finish done');
select results_eq($$select * from pg_temp.quota()$$, $$values (1, 0)$$, '2 used+1 · reserved−1');
select results_eq($$select status::text, quota_charged, result_json is not null, completed_at is not null from public.reading_requests where request_id = '60000000-0000-4000-8000-000000000001'$$,
  $$values ('done_unsaved'::text, true, true, true)$$, '2 done_unsaved with result');
select is((select count(*) from public.reading_jobs), 0::bigint, '2 job row removed');
select results_eq($$select count(*), bool_and(status = 'pending') from public.photo_delete_queue where request_id = '60000000-0000-4000-8000-000000000001'$$,
  $$values (2::bigint, true)$$, '2 photo paths queued as pending in the same transaction');
select is(public.photo_delete_done('aaaaaaaa-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000001', array['aaaaaaaa-0000-4000-8000-000000000001/60000000-0000-4000-8000-000000000001/p0.jpg']), 1, 'immediate delete marks one path done');
select is(public.reading_status('aaaaaaaa-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000001') -> 'result_json' -> 'pages' -> 0 -> 'items' -> 0 ->> 'mark', 'wrong', 'status exposes result_json in done_unsaved');

-- 3. cancel vs completion race ---------------------------------------------------------------------------------
select results_eq($$select outcome, status from jsonb_to_record(public.reading_finish('aaaaaaaa-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000001', 'cancelled')) as x(outcome text, status text)$$,
  $$values ('noop'::text, 'done_unsaved'::text)$$, '3 late cancel → noop, result kept (already_done)');
select results_eq($$select * from pg_temp.quota()$$, $$values (1, 0)$$, '3 ledger unchanged by the late cancel');
select is(public.reading_submit('aaaaaaaa-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000002', pg_temp.payload('60000000-0000-4000-8000-000000000002')) ->> 'outcome',
  'active_exists', '3 unsaved result blocks a new request (D17)');

-- 6. save · duplicate save ---------------------------------------------------------------------------------------
select is(public.reading_save('aaaaaaaa-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000001',
    '[{"page_index":0,"number":1,"mark":"wrong","wrong_item_id":"70000000-0000-4000-8000-000000000001"},{"page_index":0,"number":2,"mark":"correct"}]'::jsonb,
    '[{"id":"70000000-0000-4000-8000-000000000001","page_index":0,"number":1,"mark":"wrong","confidence":0.3,"user_confirmed":true}]'::jsonb) ->> 'outcome',
  'saved', '6 save → saved');
select results_eq($$select count(*) from public.wrong_items where request_id = '60000000-0000-4000-8000-000000000001' and deleted_at is null$$, $$values (1::bigint)$$, '6 one wrong item');
select results_eq($$select interval_days, consecutive_correct from public.review_entries where wrong_item_id = '70000000-0000-4000-8000-000000000001' and deleted_at is null$$,
  $$values (1, 0)$$, '6 initial review entry (1 day)');
select is(public.reading_save('aaaaaaaa-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000001',
    '[{"page_index":0,"number":1,"mark":"wrong","wrong_item_id":"70000000-0000-4000-8000-000000000002"}]'::jsonb,
    '[{"id":"70000000-0000-4000-8000-000000000002","page_index":0,"number":1,"mark":"wrong","confidence":0.3,"user_confirmed":true}]'::jsonb) ->> 'outcome',
  'already_saved', '6 second save → already_saved');
select results_eq($$select count(*) from public.wrong_items where request_id = '60000000-0000-4000-8000-000000000001'$$, $$values (1::bigint)$$, '6 no duplicate wrong items');
select is(jsonb_array_length(public.reading_save('aaaaaaaa-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000001', '[]'::jsonb, '[]'::jsonb) -> 'items'), 1, '6 already_saved returns the server items');
select is(public.reading_discard('aaaaaaaa-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000001') ->> 'outcome', 'not_unsaved', 'discard after save → not_unsaved');

-- update-marks -------------------------------------------------------------------------------------------------------
select is(public.reading_update_marks('aaaaaaaa-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000001',
    '[{"page_index":0,"number":1,"mark":"correct"},{"page_index":0,"number":2,"mark":"wrong","wrong_item_id":"70000000-0000-4000-8000-000000000003"}]'::jsonb, '[]'::jsonb) ->> 'outcome',
  'updated', 'update-marks: #1 → O, #2 → X');
select results_eq($$select deleted_at is not null from public.wrong_items where id = '70000000-0000-4000-8000-000000000001'$$, $$values (true)$$, 'item that became O is tombstoned');
select results_eq($$select deleted_at is not null from public.review_entries where wrong_item_id = '70000000-0000-4000-8000-000000000001'$$, $$values (true)$$, 'its review entry is tombstoned (queue removed)');
select results_eq($$select mark::text, user_confirmed, deleted_at is null from public.wrong_items where id = '70000000-0000-4000-8000-000000000003'$$, $$values ('wrong'::text, true, true)$$, 'new X item created with the client uuid');
select results_eq($$select count(*) from public.review_entries where wrong_item_id = '70000000-0000-4000-8000-000000000003' and deleted_at is null$$, $$values (1::bigint)$$, 'new item got a default review entry');
select is(public.reading_update_marks('aaaaaaaa-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000001',
    '[{"page_index":0,"number":1,"mark":"wrong","wrong_item_id":"70000000-0000-4000-8000-000000000001"}]'::jsonb, '[]'::jsonb) ->> 'outcome',
  'id_reused', 'reusing a tombstoned wrong_item id → id_reused');
select is(public.reading_update_marks('aaaaaaaa-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000001',
    '[{"page_index":0,"number":2,"mark":"partial","wrong_item_id":"70000000-0000-4000-8000-000000000003"}]'::jsonb,
    '[{"id":"71000000-0000-4000-8000-000000000001","wrong_item_id":"70000000-0000-4000-8000-000000000003","due_at":"2026-10-05T00:00:00.000Z","interval_days":2,"consecutive_correct":1,"last_result":"correct"}]'::jsonb) ->> 'outcome',
  'updated', 'update-marks with a client-computed review entry');
select results_eq($$select id::text, interval_days, consecutive_correct from public.review_entries where wrong_item_id = '70000000-0000-4000-8000-000000000003' and deleted_at is null$$,
  $$values ('71000000-0000-4000-8000-000000000001'::text, 2, 1)$$, 'client entry replaced the default one (single live entry)');
select is(public.reading_update_marks('aaaaaaaa-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000001',
    '[{"page_index":0,"number":2,"mark":"partial","wrong_item_id":"70000000-0000-4000-8000-000000000003"}]'::jsonb,
    '[{"id":"71000000-0000-4000-8000-000000000002","wrong_item_id":"70000000-0000-4000-8000-000000000003","due_at":"2026-10-05T00:00:00.000Z","interval_days":3,"consecutive_correct":0}]'::jsonb) ->> 'detail',
  'entry_invalid', 'interval_days 3 violates D9 → invalid_payload');
select is((select marks_json -> 0 ->> 'mark' from public.reading_requests where request_id = '60000000-0000-4000-8000-000000000001'), 'partial', 'marks_json replaced by the last update');

-- acceptance ②: tombstone first, then a late submit → request_deleted ----------------------------------------------
reset role;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"aaaaaaaa-0000-4000-8000-000000000001","role":"authenticated"}', true);
select is((public.sync_push(0, ('[{"table":"reading_requests","id":"60000000-0000-4000-8000-000000000001","mutation_id":"20000000-0000-4000-8000-000000000071","base_server_version":' ||
    (select server_version from public.reading_requests where request_id = '60000000-0000-4000-8000-000000000001')::text ||
    ',"data":{"deleted_at":"2026-10-01T00:00:00.000Z","client_updated_at":"2026-10-01T00:00:00.000Z","device_id":"d","purge_epoch":0}}]')::jsonb) -> 'accepted' -> 0 -> 'server_version') is not null,
  true, '② saved result deleted via delete-only mutation');
select is(public.sync_push(0, '[{"table":"reading_requests","id":"60000000-0000-4000-8000-000000000005","mutation_id":"20000000-0000-4000-8000-000000000072","base_server_version":null,"data":{"request_id":"60000000-0000-4000-8000-000000000005","deleted_at":"2026-10-01T00:00:00.000Z","created_at":"2026-10-01T00:00:00.000Z","client_updated_at":"2026-10-01T00:00:00.000Z","device_id":"d","purge_epoch":0}}]'::jsonb) -> 'accepted' -> 0 -> 'server_version',
  '1'::jsonb, '② draft tombstone accepted before any submit');
reset role;
set local role service_role;
select is(public.reading_submit('aaaaaaaa-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000005', pg_temp.payload('60000000-0000-4000-8000-000000000005')) ->> 'outcome',
  'request_deleted', '② late submit on the tombstone → request_deleted');
select is(public.reading_submit('aaaaaaaa-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000001', pg_temp.payload('60000000-0000-4000-8000-000000000001')) ->> 'outcome',
  'request_deleted', '② re-submit of the deleted saved request → request_deleted (not resurrected)');
select results_eq($$select * from pg_temp.quota()$$, $$values (1, 0)$$, '② used/reserved unchanged');
select is((select count(*) from public.reading_jobs), 0::bigint, '② no job created');
select results_eq($$select result_json is null and marks_json is null from public.reading_requests where request_id = '60000000-0000-4000-8000-000000000001'$$, $$values (true)$$, '② result/marks not restored');
select is(public.reading_status('aaaaaaaa-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000001') ->> 'outcome', 'request_deleted', '② reading-status on the tombstone → 410 request_deleted');
select is(public.reading_update_marks('aaaaaaaa-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000001', '[]'::jsonb, '[]'::jsonb) ->> 'outcome', 'not_saved', '② late update-marks on the tombstone → not_saved');

-- 5. reaper: deadline passed → failed/timeout, reservation released ----------------------------------------------------
select is(public.reading_submit('aaaaaaaa-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000003', pg_temp.payload('60000000-0000-4000-8000-000000000003')) ->> 'outcome', 'accepted', '5 new request');
update public.reading_jobs set deadline = now() - interval '1 minute' where request_id = '60000000-0000-4000-8000-000000000003';
select is(jsonb_array_length(public.reading_reaper_run() -> 'finished'), 1, '5 reaper finishes the timed-out job');
select results_eq($$select status::text, fail_reason::text from public.reading_requests where request_id = '60000000-0000-4000-8000-000000000003'$$, $$values ('failed'::text, 'timeout'::text)$$, '5 failed · timeout');
select results_eq($$select * from pg_temp.quota()$$, $$values (1, 0)$$, '5 reservation released, used unchanged');
select is(jsonb_array_length(public.reading_reaper_run() -> 'finished'), 0, '5 reaper is idempotent');

-- 4. month boundary / quota exhaustion ------------------------------------------------------------------------------------
update public.reading_quota set used = 20 where user_id = 'aaaaaaaa-0000-4000-8000-000000000001' and month = public.kst_month(now());
select is(public.reading_submit('aaaaaaaa-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000004', pg_temp.payload('60000000-0000-4000-8000-000000000004')) ->> 'outcome',
  'quota_exhausted', '4 limit reached → quota_exhausted, no reservation');
select results_eq($$select * from pg_temp.quota()$$, $$values (20, 0)$$, '4 ledger untouched');
update public.reading_quota set used = 1 where user_id = 'aaaaaaaa-0000-4000-8000-000000000001' and month = public.kst_month(now());

-- expire ------------------------------------------------------------------------------------------------------------------
select is(public.reading_submit('aaaaaaaa-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000006', pg_temp.payload('60000000-0000-4000-8000-000000000006')) ->> 'outcome', 'accepted', 'expire: new request');
select is(public.reading_finish('aaaaaaaa-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000006', 'done', '{"pages":[]}'::jsonb) ->> 'outcome', 'done', 'expire: done');
update public.reading_requests set completed_at = public.iso_utc(now() - interval '8 days') where request_id = '60000000-0000-4000-8000-000000000006';
select is(public.reading_expire_run(), 1, 'expire run → 1');
select results_eq($$select status::text, result_json is null from public.reading_requests where request_id = '60000000-0000-4000-8000-000000000006'$$, $$values ('expired'::text, true)$$, 'expired · result_json null');

-- purge-all ----------------------------------------------------------------------------------------------------------------
select is(public.reading_submit('aaaaaaaa-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000007', pg_temp.payload('60000000-0000-4000-8000-000000000007')) ->> 'outcome', 'accepted', 'purge: active request');
select results_eq($$select epoch, jsonb_array_length(object_paths) from jsonb_to_record(public.purge_all('aaaaaaaa-0000-4000-8000-000000000001')) as x(epoch int, object_paths jsonb)$$,
  $$values (1, 2)$$, 'purge-all → epoch 1, object paths of the cancelled request returned');
select results_eq($$select (select count(*) from public.reading_requests where user_id = 'aaaaaaaa-0000-4000-8000-000000000001'),
                          (select count(*) from public.sync_mutations where user_id = 'aaaaaaaa-0000-4000-8000-000000000001'),
                          (select count(*) from public.reading_quota where user_id = 'aaaaaaaa-0000-4000-8000-000000000001')$$,
  $$values (0::bigint, 0::bigint, 1::bigint)$$, 'purge-all deleted rows + receipts, kept the quota ledger');
select results_eq($$select * from pg_temp.quota()$$, $$values (2, 0)$$, 'purge-all released the reservation (cancelled, used kept)');

-- delete-account ---------------------------------------------------------------------------------------------------------------
select is(jsonb_typeof(public.delete_account_data('aaaaaaaa-0000-4000-8000-000000000001') -> 'object_paths'), 'array', 'delete-account returns pending object paths');
select is((select count(*) from public.profiles where user_id = 'aaaaaaaa-0000-4000-8000-000000000001'), 0::bigint, 'delete-account removed the profile');

select * from finish();
rollback;
