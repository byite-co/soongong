-- pgTAP · S09e purge_all under contention — two REAL sessions through dblink
-- (same recipe as 08). Session "a" holds the user's advisory lock in an open
-- transaction and purges; session "b" sends the same request id (then a
-- request formed against the older epoch) and must block, then get a replay /
-- a superseded answer once "a" commits — never a second purge. Fixtures are
-- committed (no outer transaction) and removed at the end.
select plan(16);
create extension if not exists dblink;

insert into auth.users (id, email) values ('aaaaaaaa-0000-4000-8000-000000000010', 'g@x.io');
insert into public.profiles (user_id, onboarding_done) values ('aaaaaaaa-0000-4000-8000-000000000010', true);
create or replace function pg_temp.row_at(p_id text, p_epoch int) returns void language sql as $$
  insert into public.subjects (id, user_id, created_at, client_updated_at, device_id, server_seq, name, color_index, sort_order, is_default, purge_epoch)
  values (p_id, 'aaaaaaaa-0000-4000-8000-000000000010', '2026-10-01T00:00:00.000Z', '2026-10-01T00:00:00.000Z', 'dev-g',
          public.next_server_seq('aaaaaaaa-0000-4000-8000-000000000010'), '과목', 1, 0, false, p_epoch)
$$;
select pg_temp.row_at('70000000-0000-4000-8000-0000000000a1', 0);

create or replace function pg_temp.conn() returns text language sql as $$
  select format('dbname=%s host=%s port=%s user=%s', current_database(),
                split_part(current_setting('unix_socket_directories'), ',', 1), current_setting('port'), current_user)
$$;
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
create or replace function pg_temp.shape(p jsonb) returns text language sql as $$
  select format('%s|%s|%s', p ->> 'epoch', p ->> 'replayed', p ->> 'superseded')
$$;
create temporary table pids (name text primary key, pid int);

select dblink_connect('a', pg_temp.conn());
select dblink_connect('b', pg_temp.conn());
insert into pids select 'b', pid from dblink('b', 'select pg_backend_pid()') as t(pid int);

-- (1) the same id from two sessions at once: one purge, one replay ---------------------------------
select dblink_exec('a', 'begin');
select is((select count(*) from dblink('a', $q$select public.user_lock('aaaaaaaa-0000-4000-8000-000000000010')::text$q$) as t(x text)), 1::bigint,
  '(1) session a takes the user lock in an open transaction');
select is(dblink_send_query('b', $q$select public.purge_all('aaaaaaaa-0000-4000-8000-000000000010', '90000000-0000-4000-8000-000000000001', 0)::text$q$), 1,
  '(1) session b sends R1 (expected 0)');
select is(pg_temp.wait_for_lock((select pid from pids where name = 'b')), 'advisory', '(1) session b blocks on the user''s advisory lock');
select is(pg_temp.shape((select r::jsonb from dblink('a', $q$select public.purge_all('aaaaaaaa-0000-4000-8000-000000000010', '90000000-0000-4000-8000-000000000001', 0)::text$q$) as t(r text))),
  '1|false|false', '(1) session a serves R1 → epoch 1');
select dblink_exec('a', 'commit');
select is(pg_temp.shape((select r::jsonb from dblink_get_result('b') as t(r text))), '1|true|false', '(1) session b gets the replay with epoch 1 — no second purge');
select is((select count(*) from dblink_get_result('b') as t(r text)), 0::bigint, '(1) b: no further results');
select is((select purge_epoch from public.profiles where user_id = 'aaaaaaaa-0000-4000-8000-000000000010'), 1, '(1) epoch is 1, not 2');
select is((select count(*) from public.purge_receipts where user_id = 'aaaaaaaa-0000-4000-8000-000000000010'), 1::bigint, '(1) one receipt for R1');

-- (2) a request formed against epoch 1 while another purge (expected 1 too) wins the lock ------------
select pg_temp.row_at('70000000-0000-4000-8000-0000000000a2', 1);
select dblink_exec('a', 'begin');
select is((select count(*) from dblink('a', $q$select public.user_lock('aaaaaaaa-0000-4000-8000-000000000010')::text$q$) as t(x text)), 1::bigint,
  '(2) session a takes the lock again');
select is(dblink_send_query('b', $q$select public.purge_all('aaaaaaaa-0000-4000-8000-000000000010', '90000000-0000-4000-8000-000000000002', 1)::text$q$), 1,
  '(2) session b sends R2 (expected 1)');
select is(pg_temp.wait_for_lock((select pid from pids where name = 'b')), 'advisory', '(2) session b blocks');
select is(pg_temp.shape((select r::jsonb from dblink('a', $q$select public.purge_all('aaaaaaaa-0000-4000-8000-000000000010', '90000000-0000-4000-8000-000000000003', 1)::text$q$) as t(r text))),
  '2|false|false', '(2) session a serves R3 first → epoch 2');
select is((select id from dblink('a', $q$insert into public.subjects (id, user_id, created_at, client_updated_at, device_id, server_seq, name, color_index, sort_order, is_default, purge_epoch)
  values ('70000000-0000-4000-8000-0000000000a3', 'aaaaaaaa-0000-4000-8000-000000000010', '2026-10-01T00:00:00.000Z', '2026-10-01T00:00:00.000Z', 'dev-g',
          public.next_server_seq('aaaaaaaa-0000-4000-8000-000000000010'), '과목', 1, 0, false, 2) returning id$q$) as t(id text)),
  '70000000-0000-4000-8000-0000000000a3', '(2) a row of the new epoch is written by a before it commits');
select dblink_exec('a', 'commit');
select is(pg_temp.shape((select r::jsonb from dblink_get_result('b') as t(r text))), '2|false|true', '(2) session b''s R2 is superseded — nothing deleted, epoch stays 2');
select is((select count(*) from public.subjects where user_id = 'aaaaaaaa-0000-4000-8000-000000000010'), 1::bigint, '(2) the epoch-2 row survives');
select results_eq($$select request_id::text, outcome from public.purge_receipts where user_id = 'aaaaaaaa-0000-4000-8000-000000000010' order by request_id$$,
  $$values ('90000000-0000-4000-8000-000000000001', 'served'), ('90000000-0000-4000-8000-000000000002', 'superseded'), ('90000000-0000-4000-8000-000000000003', 'served')$$,
  '(2) receipts: R1 served · R2 superseded · R3 served');

-- cleanup (committed fixtures)
select dblink_disconnect('a');
select dblink_disconnect('b');
delete from auth.users where id = 'aaaaaaaa-0000-4000-8000-000000000010';
select * from finish();
