-- pgTAP · D2 sync_push / sync_pull — 6 core cases (new · CAS · conflict ·
-- tombstone deleted · receipt replay · epoch) + reading_requests rules
-- (data-model §7 ①, D16 delete-only mutation, acceptance scenario ①).
begin;
select plan(47);

insert into auth.users (id, email) values ('aaaaaaaa-0000-4000-8000-000000000001', 'u1@test.local');
insert into public.profiles (user_id) values ('aaaaaaaa-0000-4000-8000-000000000001');

create or replace function pg_temp.as_user(p_uid text) returns void language plpgsql as $$
begin
  set local role authenticated;
  perform set_config('request.jwt.claims', json_build_object('sub', p_uid, 'role', 'authenticated')::text, true);
end $$;
create or replace function pg_temp.row(p_table text, p_id text, p_mut text, p_base int, p_data jsonb) returns jsonb language sql as $$
  select jsonb_build_array(jsonb_build_object('table', p_table, 'id', p_id, 'mutation_id', p_mut, 'base_server_version', p_base, 'purge_epoch', 0, 'data', p_data))
$$;
create or replace function pg_temp.common(p_updated text default '2026-09-30T14:03:00.000Z') returns jsonb language sql as $$
  select jsonb_build_object('created_at', '2026-09-30T14:00:00.000Z', 'client_updated_at', p_updated, 'deleted_at', null, 'device_id', 'dev-a', 'purge_epoch', 0)
$$;

grant execute on function pg_temp.row(text,text,text,int,jsonb), pg_temp.common(text) to authenticated, service_role;
select pg_temp.as_user('aaaaaaaa-0000-4000-8000-000000000001');

-- 1. new row --------------------------------------------------------------------
select is(
  public.sync_push(0, pg_temp.row('subjects', '10000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', null,
    pg_temp.common() || '{"name":"수학","color_index":1,"sort_order":0,"is_default":false}'::jsonb)) -> 'accepted' -> 0,
  '{"id":"10000000-0000-4000-8000-000000000001","table":"subjects","server_seq":1,"mutation_id":"20000000-0000-4000-8000-000000000001","server_version":1}'::jsonb,
  '1 new row → accepted, server_version 1, seq 1');
select is((select user_id from public.subjects where id = '10000000-0000-4000-8000-000000000001'), 'aaaaaaaa-0000-4000-8000-000000000001'::uuid, '1 user_id filled from auth.uid()');

-- 2. CAS update ----------------------------------------------------------------------
select is(
  public.sync_push(0, pg_temp.row('subjects', '10000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000002', 1,
    pg_temp.common('2026-09-30T14:05:00.000Z') || '{"name":"수학Ⅱ","color_index":1,"sort_order":0,"is_default":false}'::jsonb)) -> 'accepted' -> 0 -> 'server_version',
  '2'::jsonb, '2 CAS with matching base → version 2');
select is((select name from public.subjects where id = '10000000-0000-4000-8000-000000000001'), '수학Ⅱ', '2 content updated');

-- 3. conflict (stale base) → version_conflict + server_row --------------------------------------
select is(
  (public.sync_push(0, pg_temp.row('subjects', '10000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000003', 1,
    pg_temp.common('2026-09-30T14:06:00.000Z') || '{"name":"국어","color_index":2,"sort_order":0,"is_default":false}'::jsonb)) -> 'rejected' -> 0) - 'server_row',
  '{"id":"10000000-0000-4000-8000-000000000001","table":"subjects","reason":"version_conflict","mutation_id":"20000000-0000-4000-8000-000000000003"}'::jsonb,
  '3 stale base → version_conflict');
select is(
  public.sync_push(0, pg_temp.row('subjects', '10000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000003', 1,
    pg_temp.common() || '{"name":"국어","color_index":2,"sort_order":0,"is_default":false}'::jsonb)) -> 'rejected' -> 0 -> 'server_row' ->> 'name',
  '수학Ⅱ', '3 server_row carries the server copy');
select is(
  public.sync_push(0, pg_temp.row('subjects', '10000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000004', null,
    pg_temp.common() || '{"name":"국어","color_index":2,"sort_order":0,"is_default":false}'::jsonb)) -> 'rejected' -> 0 ->> 'reason',
  'version_conflict', '3 base=null on a live existing row → version_conflict');

-- 4. tombstone, then create on a deleted id → deleted -----------------------------------------------
select is(
  public.sync_push(0, pg_temp.row('subjects', '10000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000005', 2,
    (pg_temp.common('2026-09-30T14:07:00.000Z') || '{"deleted_at":"2026-09-30T14:07:00.000Z"}'::jsonb))) -> 'accepted' -> 0 -> 'server_version',
  '3'::jsonb, '4 tombstone accepted (version 3)');
select results_eq(
  $$select name is null and color_index is null and sort_order is null and is_default is null and deleted_at is not null
    from public.subjects where id = '10000000-0000-4000-8000-000000000001'$$,
  $$values (true)$$, '4 content columns nulled on the tombstone');
select is(
  public.sync_push(0, pg_temp.row('subjects', '10000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000006', null,
    pg_temp.common() || '{"name":"부활","color_index":2,"sort_order":0,"is_default":false}'::jsonb)) -> 'rejected' -> 0 ->> 'reason',
  'deleted', '4 create on a tombstoned id → deleted (no resurrection)');

-- 5. receipt replay ---------------------------------------------------------------------------------------
select is(
  public.sync_push(0, pg_temp.row('subjects', '10000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000001', null,
    pg_temp.common() || '{"name":"수학","color_index":1,"sort_order":0,"is_default":false}'::jsonb)) -> 'accepted' -> 0,
  '{"id":"10000000-0000-4000-8000-000000000001","table":"subjects","server_seq":1,"mutation_id":"20000000-0000-4000-8000-000000000001","server_version":1}'::jsonb,
  '5 resent mutation_id → the original receipt, no re-evaluation');
select is((select server_version from public.subjects where id = '10000000-0000-4000-8000-000000000001'), 3, '5 replay did not change the row');

-- 6. epoch ----------------------------------------------------------------------------------------------------
select is(public.sync_push(1, '[]'::jsonb) -> 'epoch_mismatch', 'true'::jsonb, '6 push with a future epoch → epoch_mismatch');
select is(public.sync_pull(1, 0, 10), '{"epoch_mismatch":true,"epoch":0}'::jsonb, '6 pull with a wrong epoch → epoch_mismatch');

-- extra: batch limit · invalid mutation ------------------------------------------------------------------------
select throws_ok($$select public.sync_push(0, (select jsonb_agg(jsonb_build_object('table','subjects','id','x','mutation_id','x','data','{}'::jsonb)) from generate_series(1, 501)))$$,
  'P0001', 'batch_too_large', 'batch of 501 rows is refused');
select is(public.sync_push(0, pg_temp.row('subjects', 'x', 'not-a-uuid', null, '{}'::jsonb)) -> 'rejected' -> 0 ->> 'reason', 'invalid_mutation', 'bad mutation_id → invalid_mutation');

-- constraint violation inside the batch does not abort the batch ------------------------------------------------
select is(
  (select jsonb_agg(x ->> 'reason') from jsonb_array_elements(public.sync_push(0,
    pg_temp.row('subjects', '10000000-0000-4000-8000-000000000011', '20000000-0000-4000-8000-000000000011', null, pg_temp.common() || '{"name":"ok","color_index":9,"sort_order":0,"is_default":false}'::jsonb)
    || pg_temp.row('subjects', '10000000-0000-4000-8000-000000000012', '20000000-0000-4000-8000-000000000012', null, pg_temp.common() || '{"name":"ok","color_index":3,"sort_order":1,"is_default":false}'::jsonb)) -> 'rejected') x),
  '["constraint_violation"]'::jsonb, 'color_index 9 → constraint_violation; the sibling row is still accepted');
select is((select count(*) from public.subjects where id = '10000000-0000-4000-8000-000000000012'), 1::bigint, 'sibling row inserted');

-- settings: JSON column as text on the wire ----------------------------------------------------------------------
select is(public.sync_push(0, pg_temp.row('settings', '30000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000021', null,
    pg_temp.common() || '{"key":"daily_goal_minutes","value_json":"120"}'::jsonb)) -> 'accepted' -> 0 -> 'server_version', '1'::jsonb, 'settings row with JSON text accepted');
select is((select value_json from public.settings where id = '30000000-0000-4000-8000-000000000001'), '120'::jsonb, 'value_json parsed into jsonb');
select is((select r -> 'row' ->> 'value_json' from jsonb_array_elements(public.sync_pull(0, 0, 100) -> 'rows') r where r ->> 'table' = 'settings'), '120', 'pull emits value_json as JSON text');

-- wrong_items: no client inserts --------------------------------------------------------------------------------------
select is(public.sync_push(0, pg_temp.row('wrong_items', '40000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000031', null,
    '{"subject_id":"50000000-0000-4000-8000-000000000001","status":"open","client_updated_at":"2026-09-30T14:03:00.000Z","device_id":"d","purge_epoch":0}'::jsonb)) -> 'rejected' -> 0 ->> 'reason',
  'insert_not_allowed', 'wrong_items are created only by reading-save');

-- reading_requests · drafts (§7 ①) ------------------------------------------------------------------------------------------
select is(public.sync_push(0, pg_temp.row('reading_requests', '60000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000041', null,
    pg_temp.common() || '{"request_id":"60000000-0000-4000-8000-000000000001","subject_id":"50000000-0000-4000-8000-000000000001","range_text":"p.12–15","origin":"home","session_id":null,"planner_item_id":null}'::jsonb)) -> 'accepted' -> 0 -> 'server_version',
  '1'::jsonb, 'draft insert accepted');
select results_eq($$select status::text, submitted_at::text, quota_charged from public.reading_requests where id = '60000000-0000-4000-8000-000000000001'$$,
  $$values ('selecting'::text, null::text, false)$$, 'draft gets status selecting · submitted_at null (server-set)');
select is(public.sync_push(0, pg_temp.row('reading_requests', '60000000-0000-4000-8000-000000000001', '20000000-0000-4000-8000-000000000042', 1,
    pg_temp.common('2026-09-30T14:10:00.000Z') || '{"deleted_at":"2026-09-30T14:10:00.000Z"}'::jsonb)) -> 'accepted' -> 0 -> 'server_version',
  '2'::jsonb, 'draft delete (deleted_at on selecting) accepted');
select results_eq($$select request_id::text, subject_id::text, range_text::text, status::text from public.reading_requests where id = '60000000-0000-4000-8000-000000000001'$$,
  $$values ('60000000-0000-4000-8000-000000000001'::text, null::text, null::text, null::text)$$, 'draft tombstone keeps request_id, nulls content');
select is(public.sync_push(0, pg_temp.row('reading_requests', '60000000-0000-4000-8000-000000000002', '20000000-0000-4000-8000-000000000043', null,
    pg_temp.common() || '{"request_id":"60000000-0000-4000-8000-000000000002","deleted_at":"2026-09-30T14:10:00.000Z"}'::jsonb)) -> 'accepted' -> 0 -> 'server_version',
  '1'::jsonb, 'tombstone for an id the server never saw → inserted as tombstone (D2)');
select results_eq($$select deleted_at is not null, status is null from public.reading_requests where id = '60000000-0000-4000-8000-000000000002'$$,
  $$values (true, true)$$, 'inserted tombstone has no content');

-- acceptance ①: submitted row + tombstone mutation → version_conflict + server_row ----------------------------------
reset role;
set local role service_role;
insert into public.subscription_state (user_id, expires_at, will_renew, period_type, has_history) values ('aaaaaaaa-0000-4000-8000-000000000001', now() + interval '30 days', true, 'NORMAL', true);
select public.update_consent('aaaaaaaa-0000-4000-8000-000000000001', 'r1', true);
reset role;
select pg_temp.as_user('aaaaaaaa-0000-4000-8000-000000000001');
select is(public.sync_push(0, pg_temp.row('reading_requests', '60000000-0000-4000-8000-000000000003', '20000000-0000-4000-8000-000000000051', null,
    pg_temp.common() || '{"request_id":"60000000-0000-4000-8000-000000000003","subject_id":"50000000-0000-4000-8000-000000000001","range_text":"p.1","origin":"planner"}'::jsonb)) -> 'accepted' -> 0 -> 'server_version',
  '1'::jsonb, '① draft synced first');
reset role;
set local role service_role;
select is(public.reading_submit('aaaaaaaa-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000003',
    '{"subject_id":"50000000-0000-4000-8000-000000000001","range_text":"p.1","origin":"planner","object_paths":["aaaaaaaa-0000-4000-8000-000000000001/60000000-0000-4000-8000-000000000003/p0.jpg"]}'::jsonb) ->> 'outcome',
  'accepted', '① reading-submit processed first → processing');
reset role;
select pg_temp.as_user('aaaaaaaa-0000-4000-8000-000000000001');
select is(
  (public.sync_push(0, pg_temp.row('reading_requests', '60000000-0000-4000-8000-000000000003', '20000000-0000-4000-8000-000000000052', 1,
    pg_temp.common('2026-09-30T14:20:00.000Z') || '{"deleted_at":"2026-09-30T14:20:00.000Z"}'::jsonb)) -> 'rejected' -> 0) ->> 'reason',
  'version_conflict', '① late tombstone on a submitted row → version_conflict');
select is(
  (public.sync_push(0, pg_temp.row('reading_requests', '60000000-0000-4000-8000-000000000003', '20000000-0000-4000-8000-000000000052', 2,
    pg_temp.common('2026-09-30T14:20:00.000Z') || '{"deleted_at":"2026-09-30T14:20:00.000Z"}'::jsonb)) -> 'rejected' -> 0 -> 'server_row') ->> 'status',
  'processing', '① even with a matching base: rejected, server_row.status = processing');
select results_eq($$select deleted_at is null, status from public.reading_requests where id = '60000000-0000-4000-8000-000000000003'$$,
  $$values (true, 'processing'::text)$$, '① tombstone NOT applied');
select is(public.sync_push(0, pg_temp.row('reading_requests', '60000000-0000-4000-8000-000000000003', '20000000-0000-4000-8000-000000000053', 2,
    pg_temp.common() || '{"range_text":"p.2"}'::jsonb)) -> 'rejected' -> 0 ->> 'reason',
  'version_conflict', 'client column edit after submission → version_conflict');

-- D16 delete-only mutation on a saved request → cascade -----------------------------------------------------------------
reset role;
set local role service_role;
select is(public.reading_finish('aaaaaaaa-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000003', 'done', '{"pages":[{"index":0,"items":[{"number":3,"mark":"wrong","confidence":0.4}]}]}'::jsonb) ->> 'outcome', 'done', 'finish → done_unsaved');
select is(public.reading_save('aaaaaaaa-0000-4000-8000-000000000001', '60000000-0000-4000-8000-000000000003',
    '[{"page_index":0,"number":3,"mark":"wrong","wrong_item_id":"70000000-0000-4000-8000-000000000001"}]'::jsonb,
    '[{"id":"70000000-0000-4000-8000-000000000001","page_index":0,"number":3,"mark":"wrong","confidence":0.4,"user_confirmed":true}]'::jsonb) ->> 'outcome',
  'saved', 'save → saved (1 wrong item + 1 review entry)');
insert into public.retry_records (id, user_id, created_at, client_updated_at, device_id, server_seq, wrong_item_id, result, at, voided)
values ('80000000-0000-4000-8000-000000000001', 'aaaaaaaa-0000-4000-8000-000000000001', '2026-09-30T15:00:00.000Z', '2026-09-30T15:00:00.000Z', 'd',
        999, '70000000-0000-4000-8000-000000000001', 'wrong', '2026-09-30T15:00:00.000Z', false);
reset role;
select pg_temp.as_user('aaaaaaaa-0000-4000-8000-000000000001');
select is(public.sync_push(0, pg_temp.row('reading_requests', '60000000-0000-4000-8000-000000000003', '20000000-0000-4000-8000-000000000061', 4,
    '{"deleted_at":"2026-09-30T16:00:00.000Z","range_text":"x"}'::jsonb)) -> 'rejected' -> 0 ->> 'reason',
  'invalid_columns', 'delete-only mutation with a content key → invalid_columns');
select is(public.sync_push(0, pg_temp.row('reading_requests', '60000000-0000-4000-8000-000000000003', '20000000-0000-4000-8000-000000000062', 4,
    '{"deleted_at":"2026-09-30T16:00:00.000Z","client_updated_at":"2026-09-30T16:00:00.000Z","device_id":"dev-a","purge_epoch":0}'::jsonb)) -> 'accepted' -> 0 -> 'server_version',
  '5'::jsonb, 'delete-only mutation on saved accepted (draft 1 → submit 2 → finish 3 → save 4 → delete 5)');
select results_eq($$select deleted_at is not null, result_json is null, marks_json is null, request_id::text from public.reading_requests where id = '60000000-0000-4000-8000-000000000003'$$,
  $$values (true, true, true, '60000000-0000-4000-8000-000000000003'::text)$$, 'request tombstoned: result/marks null, request_id kept');
select results_eq($$select count(*) from public.wrong_items where request_id = '60000000-0000-4000-8000-000000000003' and deleted_at is not null and mark is null$$,
  $$values (1::bigint)$$, 'child wrong_items tombstoned (content null)');
select results_eq($$select count(*) from public.review_entries where wrong_item_id = '70000000-0000-4000-8000-000000000001' and deleted_at is not null and due_at is null$$,
  $$values (1::bigint)$$, 'child review_entries tombstoned');
select results_eq($$select count(*) from public.retry_records where wrong_item_id = '70000000-0000-4000-8000-000000000001' and deleted_at is not null and result is null$$,
  $$values (1::bigint)$$, 'child retry_records tombstoned');
select results_eq(
  $$select count(distinct server_seq) = count(*) from (
      select server_seq from public.wrong_items where request_id = '60000000-0000-4000-8000-000000000003'
      union all select server_seq from public.review_entries where wrong_item_id = '70000000-0000-4000-8000-000000000001'
      union all select server_seq from public.retry_records where wrong_item_id = '70000000-0000-4000-8000-000000000001'
      union all select server_seq from public.reading_requests where id = '60000000-0000-4000-8000-000000000003') s$$,
  $$values (true)$$, 'each cascaded tombstone got its own seq');

-- pull: paging + tombstones with no content ---------------------------------------------------------------------------------
select is(public.sync_pull(0, 0, 3) -> 'has_more', 'true'::jsonb, 'pull limit 3 → has_more');
select is((select (p -> 'next_seq')::bigint = max((r -> 'row' ->> 'server_seq')::bigint) from public.sync_pull(0, 0, 3) p, jsonb_array_elements(p -> 'rows') r group by p),
  true, 'next_seq = last seq of the page');
select results_eq(
  $$select bool_and(((r -> 'row' ->> 'deleted_at') is null) or (r -> 'row' ->> 'name') is null) from jsonb_array_elements(public.sync_pull(0, 0, 1000) -> 'rows') r where r ->> 'table' = 'subjects'$$,
  $$values (true)$$, 'tombstones in a pull carry no content');
select is((select count(*) from jsonb_array_elements(public.sync_pull(0, (public.sync_pull(0, 0, 1000) ->> 'next_seq')::bigint, 1000) -> 'rows')), 0::bigint, 'pull from next_seq returns nothing (no overlap)');

select * from finish();
rollback;
