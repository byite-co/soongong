-- pgTAP · S03b 0011 — draft_orphan_tombstone_run takes the user's advisory lock and
-- re-checks the row before tombstoning. Two REAL sessions through dblink: session "a"
-- holds the lock in an open transaction (submit / edit), session "b" runs the job and
-- must block, then skip the row once "a" commits. Fixtures are committed (no outer
-- transaction) and removed at the end.
select plan(21);
create extension if not exists dblink;

insert into auth.users (id, email) values ('eeeeeeee-0000-4000-8000-000000000001', 'orphan@test.local');
insert into public.profiles (user_id, consent_reading_version, consent_reading_at) values ('eeeeeeee-0000-4000-8000-000000000001', 'r1', now());
insert into public.subscription_state (user_id, expires_at, will_renew, period_type, has_history)
values ('eeeeeeee-0000-4000-8000-000000000001', now() + interval '30 days', true, 'NORMAL', true);
-- a 31-day-old draft per scenario (inserted right before each one, so each job run has one candidate):
-- D1 (submitted while the job waits) · D2 (edited while it waits) · D3 (untouched)
create or replace function pg_temp.old_draft(p_id text) returns void language sql as $$
  insert into public.reading_requests (id, user_id, created_at, client_updated_at, device_id, server_seq, request_id, subject_id, range_text, origin, status)
  values (p_id, 'eeeeeeee-0000-4000-8000-000000000001', public.iso_utc(now() - interval '31 days'), public.iso_utc(now() - interval '31 days'), 'dev-a',
          public.next_server_seq('eeeeeeee-0000-4000-8000-000000000001'), p_id, '50000000-0000-4000-8000-000000000001', 'p.1', 'home', 'selecting')
$$;
select pg_temp.old_draft('e1000000-0000-4000-8000-000000000001');

create or replace function pg_temp.conn() returns text language sql as $$
  select format('dbname=%s host=%s port=%s user=%s', current_database(),
                split_part(current_setting('unix_socket_directories'), ',', 1), current_setting('port'), current_user)
$$;
-- polls pg_stat_activity until the backend waits on an advisory lock (≤ 10 s)
create or replace function pg_temp.wait_for_lock(p_pid int) returns text language plpgsql as $$
begin
  for i in 1..100 loop
    if exists (select 1 from pg_stat_activity where pid = p_pid and wait_event_type = 'Lock' and wait_event = 'advisory') then
      return 'advisory';
    end if;
    perform pg_sleep(0.1);
  end loop;
  return 'not waiting';
end $$;
create or replace function pg_temp.payload(p_req text) returns text language sql as $$
  select jsonb_build_object('subject_id', '50000000-0000-4000-8000-000000000001', 'range_text', 'p.1', 'origin', 'home',
    'object_paths', jsonb_build_array('eeeeeeee-0000-4000-8000-000000000001/' || p_req || '/p0.jpg'))::text
$$;
create temporary table pids (name text primary key, pid int);

select dblink_connect('a', pg_temp.conn());
select dblink_connect('b', pg_temp.conn());
insert into pids select 'b', pid from dblink('b', 'select pg_backend_pid()') as t(pid int);

-- ---------------------------------------------------------------------------
-- (a) submit commits while the job waits for the lock → the row is skipped
-- ---------------------------------------------------------------------------
select dblink_exec('a', 'begin');
select is((select o from dblink('a', format($q$select public.reading_submit('eeeeeeee-0000-4000-8000-000000000001', 'e1000000-0000-4000-8000-000000000001', %L::jsonb, 'dev-a') ->> 'outcome'$q$, pg_temp.payload('e1000000-0000-4000-8000-000000000001'))) as t(o text)),
  'accepted', '(a) session a: submit of the 31-day-old draft D1 inside an open transaction (user lock held)');
select is(dblink_send_query('b', 'select public.draft_orphan_tombstone_run()'), 1, '(a) session b: orphan job started asynchronously');
select is(pg_temp.wait_for_lock((select pid from pids where name = 'b')), 'advisory', '(a) session b blocks on the user''s advisory lock behind a''s submit');
select results_eq($$select status::text, deleted_at is null from public.reading_requests where id = 'e1000000-0000-4000-8000-000000000001'$$,
  $$values ('selecting'::text, true)$$, '(a) while b waits, D1 is still the uncommitted-submit draft from the outside');
select dblink_exec('a', 'commit');
select is((select n from dblink_get_result('b') as t(n int)), 0, '(a) after a commits, b re-checks under the lock and tombstones nothing');
select is((select count(*) from dblink_get_result('b') as t(n int)), 0::bigint, '(a) b: no further results');
select results_eq($$select status::text, submitted_at is not null, deleted_at is null, server_version from public.reading_requests where id = 'e1000000-0000-4000-8000-000000000001'$$,
  $$values ('processing'::text, true, true, 2)$$, '(a) D1 is processing · submitted · not tombstoned · version from the submit only');
select results_eq($$select used, reserved from public.reading_quota where user_id = 'eeeeeeee-0000-4000-8000-000000000001' and month = public.kst_month(now())$$,
  $$values (0, 1)$$, '(a) reservation untouched (used 0 · reserved 1)');
select is((select count(*) from public.reading_jobs where user_id = 'eeeeeeee-0000-4000-8000-000000000001' and request_id = 'e1000000-0000-4000-8000-000000000001'), 1::bigint,
  '(a) the job row of the submit still exists');

-- ---------------------------------------------------------------------------
-- (b) the user edits the draft (sync_push) while the job waits → the row is skipped
-- ---------------------------------------------------------------------------
select pg_temp.old_draft('e1000000-0000-4000-8000-000000000002');
select dblink_exec('a', 'begin');
select dblink_exec('a', 'set local role authenticated');
select is((select x from dblink('a', $q$select set_config('request.jwt.claims', '{"sub":"eeeeeeee-0000-4000-8000-000000000001","role":"authenticated"}', true)$q$) as t(x text)) is not null, true,
  '(b) session a acts as the user');
select is((select v from dblink('a', format($q$select public.sync_push(0, %L::jsonb) -> 'accepted' -> 0 ->> 'server_version'$q$,
    jsonb_build_array(jsonb_build_object('table', 'reading_requests', 'id', 'e1000000-0000-4000-8000-000000000002', 'mutation_id', 'e2000000-0000-4000-8000-000000000002',
      'base_server_version', 1, 'purge_epoch', 0,
      'data', jsonb_build_object('created_at', public.iso_utc(now() - interval '31 days'), 'client_updated_at', public.iso_utc(now()), 'deleted_at', null, 'device_id', 'dev-a', 'purge_epoch', 0,
        'request_id', 'e1000000-0000-4000-8000-000000000002', 'subject_id', '50000000-0000-4000-8000-000000000001', 'range_text', 'p.2 edited', 'origin', 'home', 'session_id', null, 'planner_item_id', null)))::text))
    as t(v text)),
  '2', '(b) session a: edit of D2 accepted inside an open transaction (user lock held)');
select is(dblink_send_query('b', 'select public.draft_orphan_tombstone_run()'), 1, '(b) session b: orphan job started asynchronously');
select is(pg_temp.wait_for_lock((select pid from pids where name = 'b')), 'advisory', '(b) session b blocks on the user''s advisory lock behind a''s edit');
select dblink_exec('a', 'commit');
select is((select n from dblink_get_result('b') as t(n int)), 0, '(b) after a commits, b sees the fresh client_updated_at and tombstones nothing');
select is((select count(*) from dblink_get_result('b') as t(n int)), 0::bigint, '(b) b: no further results');
select results_eq($$select status::text, deleted_at is null, range_text::text, server_version, public.ts(client_updated_at) > now() - interval '1 minute' from public.reading_requests where id = 'e1000000-0000-4000-8000-000000000002'$$,
  $$values ('selecting'::text, true, 'p.2 edited'::text, 2, true)$$, '(b) D2 keeps the edit: selecting · not tombstoned · version 2 · fresh client_updated_at');

-- ---------------------------------------------------------------------------
-- (c) untouched 31-day-old draft D3 → tombstoned (positive control, no contention)
-- ---------------------------------------------------------------------------
select pg_temp.old_draft('e1000000-0000-4000-8000-000000000003');
select is(public.draft_orphan_tombstone_run(), 1, '(c) D3 alone is tombstoned');
select results_eq($$select deleted_at is not null, status is null, server_version from public.reading_requests where id = 'e1000000-0000-4000-8000-000000000003'$$,
  $$values (true, true, 2)$$, '(c) D3 tombstone: deleted_at set · content nulled · version 2');
select is(public.draft_orphan_tombstone_run(), 0, '(c) second run finds nothing');
select is((select count(*) from public.reading_requests where user_id = 'eeeeeeee-0000-4000-8000-000000000001' and deleted_at is not null), 1::bigint,
  'only D3 was tombstoned across (a)(b)(c)');

-- cleanup (committed fixtures)
select dblink_disconnect('a');
select dblink_disconnect('b');
delete from auth.users where id = 'eeeeeeee-0000-4000-8000-000000000001';
select is((select count(*) from public.reading_requests where user_id = 'eeeeeeee-0000-4000-8000-000000000001'), 0::bigint, 'cleanup: fixture rows removed (cascade)');
select * from finish();
