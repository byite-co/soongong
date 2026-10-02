-- pgTAP · S03b fixes — 0009 (photo residue scan · marks/items validation) and
-- dev/0002 (jsonb_key_paths recursion). Runs as postgres for the dev-only helpers
-- (service_role has no EXECUTE on them), then as service_role for the RPCs.
begin;
select plan(47);

-- ---------------------------------------------------------------------------
-- 1. jsonb_key_paths (dev/0002): several keys · nested objects · arrays · depth cap
-- ---------------------------------------------------------------------------
select is(
  (select array_agg(p order by p collate "C") from public.jsonb_key_paths('{"a":1,"b":{"c":2,"d":{"e":3}},"f":"x"}'::jsonb) p),
  array['a', 'b', 'b.c', 'b.d', 'b.d.e', 'f'], 'key paths: several keys + nested objects');
select is(
  (select array_agg(p order by p collate "C") from public.jsonb_key_paths(
    '{"identities":[{"provider":"email","identity_data":{"sub":"x"}}],"tags":["a","b"],"m":[[{"z":1}]]}'::jsonb) p),
  array['identities', 'identities[].identity_data', 'identities[].identity_data.sub', 'identities[].provider', 'm', 'm[][].z', 'tags'],
  'key paths: arrays as [] (objects inside arrays, nested arrays, scalar arrays)');
select lives_ok($$select count(*) from public.jsonb_key_paths((repeat('{"k":', 40) || '1' || repeat('}', 40))::jsonb)$$,
  'key paths: 40 nested levels do not raise (no planner inlining)');
select is((select count(*) from public.jsonb_key_paths((repeat('{"k":', 40) || '1' || repeat('}', 40))::jsonb)), 32::bigint,
  'key paths: depth capped at 32 levels');
select is((select count(*) from public.jsonb_key_paths('[]'::jsonb)), 0::bigint, 'key paths: empty array → nothing');

-- capture hook (dev/0002) records the shape of a realistic email payload, never values
insert into public.server_config (key, value) values ('hook_fixtures_capture', 'on') on conflict (key) do update set value = 'on';
select is(public.before_user_created_hook('{"metadata":{"uuid":"00000000-0000-4000-8000-000000000000","time":"2026-10-02T00:00:00Z","name":"before-user-created"},"user":{"id":"cccccccc-0000-4000-8000-000000000001","aud":"authenticated","role":"","email":"capture@test.local","phone":"","app_metadata":{"provider":"email","providers":["email"]},"user_metadata":{"email":"capture@test.local","email_verified":false},"identities":[],"is_anonymous":false,"created_at":"2026-10-02T00:00:00Z","updated_at":"2026-10-02T00:00:00Z"}}'::jsonb) -> 'error' ->> 'http_code',
  '400', 'capture hook: no pass → reject');
select results_eq($$select provider, subject_source, decision, key_paths ? 'user.email', key_paths ? 'user.app_metadata.providers', key_paths::text like '%capture@test.local%' from public.hook_fixtures$$,
  $$values ('email'::text, 'email'::text, 'reject'::text, true, true, false)$$, 'capture hook: one fixture row with provider · key paths · decision, no values');
update public.server_config set value = 'off' where key = 'hook_fixtures_capture';

-- validator edge cases (direct, as postgres)
select is(public.reading_validate_marks('[{"page_index":1.5,"number":1,"mark":"correct"}]'::jsonb), 'mark_invalid', 'validate_marks: non-integer page_index → mark_invalid');
select is(public.reading_validate_marks('[{"page_index":"0","number":1,"mark":"correct"}]'::jsonb), 'mark_invalid', 'validate_marks: string page_index → mark_invalid');
select is(public.reading_validate_marks('[{"page_index":0,"number":1,"mark":"wrong","wrong_item_id":"90000000-0000-4000-8000-000000000001"},{"page_index":0,"number":2,"mark":"partial","wrong_item_id":"90000000-0000-4000-8000-000000000001"}]'::jsonb),
  'wrong_item_id_duplicate', 'validate_marks: same wrong_item_id twice → wrong_item_id_duplicate');
select is(public.reading_validate_items('[{"page_index":0,"number":1,"mark":"wrong","wrong_item_id":"90000000-0000-4000-8000-000000000001"}]'::jsonb,
  '[{"id":"90000000-0000-4000-8000-000000000001","page_index":0,"number":1,"mark":"wrong","confidence":"high"}]'::jsonb),
  'item_invalid', 'validate_items: non-numeric confidence → item_invalid');
select is(public.reading_validate_items('[]'::jsonb, '[]'::jsonb), null, 'validate_items: no wrong marks and no items → ok');

-- ---------------------------------------------------------------------------
-- fixtures for 2 · 3 (as postgres)
-- ---------------------------------------------------------------------------
insert into auth.users (id, email) values ('bbbbbbbb-0000-4000-8000-000000000001', 'residue@test.local');
insert into public.profiles (user_id, consent_reading_version, consent_reading_at) values ('bbbbbbbb-0000-4000-8000-000000000001', 'r1', now());
insert into public.reading_requests (id, user_id, created_at, client_updated_at, device_id, server_seq, request_id, subject_id, range_text, origin, status, submitted_at)
select r.id, 'bbbbbbbb-0000-4000-8000-000000000001', public.iso_utc(now() - interval '2 days'), public.iso_utc(now() - interval '2 days'), 'dev', r.seq, r.id,
       '50000000-0000-4000-8000-000000000001', 'p.1', 'home', r.status, case when r.status = 'selecting' then null else public.iso_utc(now() - interval '2 days') end
from (values
  ('80000000-0000-4000-8000-000000000001', 1, 'done_unsaved'),
  ('80000000-0000-4000-8000-000000000002', 2, 'processing'),
  ('80000000-0000-4000-8000-000000000003', 3, 'selecting'),
  ('80000000-0000-4000-8000-000000000004', 4, 'failed')) as r(id, seq, status);

-- storage objects: draft (25 h, no queue) · processing (25 h) · unknown request (25 h)
--                  · fresh draft photo (1 h) · failed request already pending in the queue
insert into storage.objects (bucket_id, name, created_at) values
  ('reading-photos', 'bbbbbbbb-0000-4000-8000-000000000001/80000000-0000-4000-8000-000000000003/p0.jpg', now() - interval '25 hours'),
  ('reading-photos', 'bbbbbbbb-0000-4000-8000-000000000001/80000000-0000-4000-8000-000000000002/p0.jpg', now() - interval '25 hours'),
  ('reading-photos', 'bbbbbbbb-0000-4000-8000-000000000001/80000000-0000-4000-8000-0000000000ff/p0.jpg', now() - interval '25 hours'),
  ('reading-photos', 'bbbbbbbb-0000-4000-8000-000000000001/80000000-0000-4000-8000-000000000003/p1.jpg', now() - interval '1 hour'),
  ('reading-photos', 'bbbbbbbb-0000-4000-8000-000000000001/80000000-0000-4000-8000-000000000004/p0.jpg', now() - interval '25 hours');
insert into public.photo_delete_queue (request_id, user_id, bucket_path)
values ('80000000-0000-4000-8000-000000000004', 'bbbbbbbb-0000-4000-8000-000000000001', 'bbbbbbbb-0000-4000-8000-000000000001/80000000-0000-4000-8000-000000000004/p0.jpg');
-- 1200 orphan objects (uploaded, never submitted, request rows never synced), > 2 batches of 500
insert into storage.objects (bucket_id, name, created_at)
select 'reading-photos',
       'bbbbbbbb-0000-4000-8000-000000000001/81000000-0000-4000-8000-' || lpad(to_hex(g), 12, '0') || '/p0.jpg',
       now() - interval '48 hours' + (g || ' seconds')::interval
from generate_series(1, 1200) g;

select ok(has_function_privilege('service_role', 'public.photo_residue_run(int)', 'execute'), 'photo_residue_run: service_role may execute');
select ok(not has_function_privilege('authenticated', 'public.photo_residue_run(int)', 'execute')
      and not has_function_privilege('anon', 'public.photo_residue_run(int)', 'execute'), 'photo_residue_run: anon/authenticated may not');
select is((select count(*) from cron.job where jobname = 'soongong-photo-residue' and schedule = '45 15 * * *' and active), 1::bigint, 'daily cron job soongong-photo-residue registered');

set local role service_role;

-- ---------------------------------------------------------------------------
-- 2. photo_residue_run: everything > 24 h that is not an active request is queued, in one run
-- ---------------------------------------------------------------------------
create temporary table run1 as select public.photo_residue_run() as r;
select is((select r ->> 'scanned' from run1), '1204', 'residue: 1204 objects older than 24 h scanned (fresh one skipped)');
select is((select r ->> 'queued' from run1), '1202', 'residue: 1200 orphans + draft + unknown request queued (processing and already-pending skipped)');
select is((select r ->> 'skipped_active' from run1), '1', 'residue: the processing request''s photo is left alone');
select is((select (r ->> 'batches')::int from run1), 3, 'residue: 500-row cursor → 3 batches');
select results_eq($$select count(*) from public.photo_delete_queue where status = 'pending' and bucket_path like '%/80000000-0000-4000-8000-000000000003/p0.jpg'$$, $$values (1::bigint)$$, 'residue: abandoned draft photo queued');
select results_eq($$select count(*) from public.photo_delete_queue where bucket_path like '%/80000000-0000-4000-8000-000000000002/%'$$, $$values (0::bigint)$$, 'residue: processing request photo not queued');
select results_eq($$select count(*), min(request_id)::text from public.photo_delete_queue where bucket_path like '%/80000000-0000-4000-8000-0000000000ff/%'$$, $$values (1::bigint, '80000000-0000-4000-8000-0000000000ff'::text)$$, 'residue: object without a request row queued (request_id kept from the path)');
select results_eq($$select count(*) from public.photo_delete_queue where bucket_path like '%/p1.jpg'$$, $$values (0::bigint)$$, 'residue: object younger than 24 h not queued');
select results_eq($$select count(*) from public.photo_delete_queue where bucket_path like '%/80000000-0000-4000-8000-000000000004/%'$$, $$values (1::bigint)$$, 'residue: already-pending path not queued twice');
select results_eq($$select count(*) from public.photo_delete_queue where bucket_path like '%/81000000-%' and status = 'pending' and user_id = 'bbbbbbbb-0000-4000-8000-000000000001'$$, $$values (1200::bigint)$$, 'residue: all 1200 orphans queued with user_id');
select is(public.photo_residue_run() ->> 'queued', '0', 'residue: second run queues nothing new (idempotent while pending)');
select is((select count(*) from public.photo_delete_claim(10) x), 1::bigint, 'residue rows are claimable by the runner (jsonb array returned)');

-- ---------------------------------------------------------------------------
-- 3. reading_save: marks[] / items[] validation, nothing written before it passes
-- ---------------------------------------------------------------------------
select is(public.reading_save('bbbbbbbb-0000-4000-8000-000000000001', '80000000-0000-4000-8000-000000000001',
    '[{"page_index":0,"number":1,"mark":"wrong","wrong_item_id":"90000000-0000-4000-8000-000000000001"}]'::jsonb, '[]'::jsonb) ->> 'detail',
  'marks_items_mismatch', 'save: items=[] with a wrong mark → marks_items_mismatch');
select is(public.reading_save('bbbbbbbb-0000-4000-8000-000000000001', '80000000-0000-4000-8000-000000000001',
    '[{"page_index":0,"number":1,"mark":"wrong","wrong_item_id":"90000000-0000-4000-8000-000000000001"}]'::jsonb, '[]'::jsonb) ->> 'status_code',
  '400', 'save: mismatch is a 400 invalid_payload');
select is(public.reading_save('bbbbbbbb-0000-4000-8000-000000000001', '80000000-0000-4000-8000-000000000001',
    '[{"page_index":0,"number":1,"wrong_item_id":"90000000-0000-4000-8000-000000000001"}]'::jsonb,
    '[{"id":"90000000-0000-4000-8000-000000000001","page_index":0,"number":1,"mark":"wrong"}]'::jsonb) ->> 'detail',
  'mark_invalid', 'save: mark missing → mark_invalid');
select is(public.reading_save('bbbbbbbb-0000-4000-8000-000000000001', '80000000-0000-4000-8000-000000000001',
    '[{"page_index":0,"number":1,"mark":"wrong"}]'::jsonb,
    '[{"id":"90000000-0000-4000-8000-000000000001","page_index":0,"number":1,"mark":"wrong"}]'::jsonb) ->> 'detail',
  'wrong_item_id_required', 'save: non-correct mark without wrong_item_id → wrong_item_id_required');
select is(public.reading_save('bbbbbbbb-0000-4000-8000-000000000001', '80000000-0000-4000-8000-000000000001',
    '[{"page_index":0,"number":1,"mark":"wrong","wrong_item_id":"90000000-0000-4000-8000-000000000001"}]'::jsonb,
    '[{"id":"90000000-0000-4000-8000-000000000002","page_index":0,"number":1,"mark":"wrong"}]'::jsonb) ->> 'detail',
  'marks_items_mismatch', 'save: item id differs from wrong_item_id → marks_items_mismatch');
select is(public.reading_save('bbbbbbbb-0000-4000-8000-000000000001', '80000000-0000-4000-8000-000000000001',
    '[{"page_index":0,"number":1,"mark":"wrong","wrong_item_id":"90000000-0000-4000-8000-000000000001"}]'::jsonb,
    '[{"id":"90000000-0000-4000-8000-000000000001","page_index":0,"number":1,"mark":"wrong"},{"id":"90000000-0000-4000-8000-000000000002","page_index":0,"number":2,"mark":"wrong"}]'::jsonb) ->> 'detail',
  'marks_items_mismatch', 'save: extra item → marks_items_mismatch');
select is(public.reading_save('bbbbbbbb-0000-4000-8000-000000000001', '80000000-0000-4000-8000-000000000001',
    '[{"page_index":0,"number":1,"mark":"wrong","wrong_item_id":"90000000-0000-4000-8000-000000000001"}]'::jsonb,
    '[{"id":"90000000-0000-4000-8000-000000000001","page_index":0,"number":2,"mark":"wrong"}]'::jsonb) ->> 'detail',
  'marks_items_mismatch', 'save: same id but different number → marks_items_mismatch');
select is(public.reading_save('bbbbbbbb-0000-4000-8000-000000000001', '80000000-0000-4000-8000-000000000001',
    '[{"page_index":0,"number":1,"mark":"wrong","wrong_item_id":"90000000-0000-4000-8000-000000000001"}]'::jsonb,
    '[{"id":"90000000-0000-4000-8000-000000000001","page_index":0,"number":1,"mark":"partial"}]'::jsonb) ->> 'detail',
  'marks_items_mismatch', 'save: same id but different mark → marks_items_mismatch');
select is(public.reading_save('bbbbbbbb-0000-4000-8000-000000000001', '80000000-0000-4000-8000-000000000001',
    '[{"page_index":0,"number":1,"mark":"wrong","wrong_item_id":"90000000-0000-4000-8000-000000000001"},{"page_index":0,"number":2,"mark":"correct"}]'::jsonb,
    '[{"id":"90000000-0000-4000-8000-000000000001","page_index":0,"number":1,"mark":"wrong"},{"id":"90000000-0000-4000-8000-000000000002","page_index":0,"number":2,"mark":"correct"}]'::jsonb) ->> 'detail',
  'marks_items_mismatch', 'save: a correct item is an extra item → marks_items_mismatch');
select is(public.reading_save('bbbbbbbb-0000-4000-8000-000000000001', '80000000-0000-4000-8000-000000000001',
    '[{"page_index":0,"number":1,"mark":"wrong","wrong_item_id":"90000000-0000-4000-8000-000000000001"}]'::jsonb,
    '[{"id":"90000000-0000-4000-8000-000000000001","page_index":0,"number":1,"mark":"wrong"},{"id":"90000000-0000-4000-8000-000000000001","page_index":0,"number":1,"mark":"wrong"}]'::jsonb) ->> 'detail',
  'item_id_duplicate', 'save: duplicated item → item_id_duplicate');
select results_eq($$select count(*) from public.wrong_items where user_id = 'bbbbbbbb-0000-4000-8000-000000000001'$$, $$values (0::bigint)$$, 'save: rejections wrote no wrong_items');
select results_eq($$select count(*) from public.review_entries where user_id = 'bbbbbbbb-0000-4000-8000-000000000001'$$, $$values (0::bigint)$$, 'save: rejections wrote no review_entries');
select results_eq($$select status::text, marks_json is null, server_version from public.reading_requests where request_id = '80000000-0000-4000-8000-000000000001'$$,
  $$values ('done_unsaved'::text, true, 1)$$, 'save: request untouched after rejections');
select is(public.reading_save('bbbbbbbb-0000-4000-8000-000000000001', '80000000-0000-4000-8000-000000000001',
    '[{"page_index":0,"number":1,"mark":"wrong","wrong_item_id":"90000000-0000-4000-8000-000000000001"},{"page_index":0,"number":2,"mark":"correct"},{"page_index":1,"number":3,"mark":"partial","wrong_item_id":"90000000-0000-4000-8000-000000000003"}]'::jsonb,
    '[{"id":"90000000-0000-4000-8000-000000000003","page_index":1,"number":3,"mark":"partial","confidence":0.7,"user_confirmed":true},{"id":"90000000-0000-4000-8000-000000000001","page_index":0,"number":1,"mark":"wrong","confidence":0.4,"user_confirmed":true}]'::jsonb) ->> 'outcome',
  'saved', 'save: items match the non-correct marks (any order) → saved');
select results_eq($$select count(*) from public.wrong_items where request_id = '80000000-0000-4000-8000-000000000001' and deleted_at is null$$, $$values (2::bigint)$$, 'save: two wrong items written');
select results_eq($$select count(*) from public.review_entries where user_id = 'bbbbbbbb-0000-4000-8000-000000000001' and deleted_at is null and interval_days = 1$$, $$values (2::bigint)$$, 'save: one initial review entry per item');
select is((select status from public.reading_requests where request_id = '80000000-0000-4000-8000-000000000001'), 'saved', 'save: request is saved');

-- update-marks goes through the same marks validator
select is(public.reading_update_marks('bbbbbbbb-0000-4000-8000-000000000001', '80000000-0000-4000-8000-000000000001',
    '[{"page_index":0,"number":1,"mark":"wrong","wrong_item_id":"90000000-0000-4000-8000-000000000001"},{"page_index":1,"number":3,"mark":"partial","wrong_item_id":"90000000-0000-4000-8000-000000000001"}]'::jsonb, '[]'::jsonb) ->> 'detail',
  'wrong_item_id_duplicate', 'update-marks: duplicate wrong_item_id → rejected');
select is(public.reading_update_marks('bbbbbbbb-0000-4000-8000-000000000001', '80000000-0000-4000-8000-000000000001',
    '[{"page_index":0,"number":1,"mark":"wrong","wrong_item_id":"90000000-0000-4000-8000-000000000001"},{"page_index":1,"number":3}]'::jsonb, '[]'::jsonb) ->> 'detail',
  'mark_invalid', 'update-marks: mark missing → rejected');
select results_eq($$select count(*), bool_and(deleted_at is null), max(server_version) from public.wrong_items where request_id = '80000000-0000-4000-8000-000000000001'$$,
  $$values (2::bigint, true, 1)$$, 'update-marks: rejections wrote nothing');

select * from finish();
rollback;
