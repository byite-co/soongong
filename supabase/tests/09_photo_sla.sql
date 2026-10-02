-- pgTAP · S03b 0011 — D14 "24 hours": proof by time injection (app.test_now → app_now()).
-- Worst-case schedule simulated minute by minute: hourly residue scan at :10, runner every
-- 5 minutes that runs BEFORE the scan when both fall on :10, and the first claim of every
-- row lost (backlog). For uploads at every minute of an hour plus the :09:59 / :10:00 /
-- :10:01 boundary, the actual deletion time (queue completed_at) minus the upload time
-- stays below 24 h; the maximum is 23 h 10 m (upload exactly at :10:00).
begin;
select plan(13);

insert into auth.users (id, email) values ('ffffffff-0000-4000-8000-000000000001', 'sla@test.local');

-- clock ----------------------------------------------------------------------------------------
select ok(abs(extract(epoch from public.app_now() - now())) < 1, 'app_now(): now() when app.test_now is unset');
select set_config('app.test_now', '2030-01-01T00:00:00Z', true);
select is(public.app_now(), '2030-01-01T00:00:00Z'::timestamptz, 'app_now(): the injected time when app.test_now is set');
select set_config('app.test_now', '', true);
select ok(not has_function_privilege('service_role', 'public.app_now()', 'execute')
      and not has_function_privilege('authenticated', 'public.app_now()', 'execute')
      and not has_function_privilege('anon', 'public.app_now()', 'execute'), 'app_now(): internal helper, no EXECUTE for API roles');

-- real-time cutoff: 22 h ---------------------------------------------------------------------------
insert into storage.objects (bucket_id, name, created_at) values
  ('reading-photos', 'ffffffff-0000-4000-8000-000000000001/f0000000-0000-4000-8000-000000000001/p0.jpg', now() - interval '22 hours 1 minute'),
  ('reading-photos', 'ffffffff-0000-4000-8000-000000000001/f0000000-0000-4000-8000-000000000002/p0.jpg', now() - interval '21 hours 59 minutes');
select is(public.photo_residue_run() ->> 'queued', '1', 'cutoff: 22 h 01 m old → queued, 21 h 59 m old → not yet');
select results_eq($$select request_id::text from public.photo_delete_queue where status = 'pending'$$,
  $$values ('f0000000-0000-4000-8000-000000000001'::text)$$, 'cutoff: the queued row is the 22 h 01 m object');
delete from public.photo_delete_queue;
delete from storage.objects where bucket_id = 'reading-photos';

-- worst-case schedule simulation ----------------------------------------------------------------
-- uploads: every minute of the hour starting 2030-03-01 00:00Z (k = 0..59) + 00:09:59 + 00:10:01
insert into storage.objects (bucket_id, name, created_at)
select 'reading-photos', 'ffffffff-0000-4000-8000-000000000001/f1000000-0000-4000-8000-' || lpad(k::text, 12, '0') || '/p0.jpg',
       '2030-03-01T00:00:00Z'::timestamptz + make_interval(mins => k)
from generate_series(0, 59) k;
insert into storage.objects (bucket_id, name, created_at) values
  ('reading-photos', 'ffffffff-0000-4000-8000-000000000001/f2000000-0000-4000-8000-000000000959/p0.jpg', '2030-03-01T00:09:59Z'),
  ('reading-photos', 'ffffffff-0000-4000-8000-000000000001/f2000000-0000-4000-8000-000000001001/p0.jpg', '2030-03-01T00:10:01Z');

-- one tick = 5 minutes: runner (claim → first claim lost, second done) then, at :10, the residue scan
create or replace function pg_temp.simulate(p_from timestamptz, p_ticks int) returns void language plpgsql as $$
declare t timestamptz; r jsonb; v_ok bigint[]; v_fail bigint[];
begin
  for i in 0..p_ticks loop
    t := p_from + make_interval(mins => 5 * i);
    perform set_config('app.test_now', t::text, true);
    select coalesce(array_agg((e ->> 'id')::bigint) filter (where (e ->> 'attempts')::int >= 2), '{}'),
           coalesce(array_agg((e ->> 'id')::bigint) filter (where (e ->> 'attempts')::int < 2), '{}')
      into v_ok, v_fail
      from jsonb_array_elements(public.photo_delete_claim(500)) e;
    if cardinality(v_fail) > 0 then perform public.photo_delete_mark(v_fail, false); end if;
    if cardinality(v_ok) > 0 then
      perform public.photo_delete_mark(v_ok, true);
      -- the runner deleted these objects from Storage
      delete from storage.objects o using public.photo_delete_queue q where q.id = any (v_ok) and o.bucket_id = 'reading-photos' and o.name = q.bucket_path;
    end if;
    if extract(minute from t) = 10 then perform public.photo_residue_run(); end if;
  end loop;
  perform set_config('app.test_now', '', true);
end $$;
select pg_temp.simulate('2030-03-01T00:00:00Z', 24 * 12);

-- every upload must be gone from Storage; its deletion time is the queue row's completed_at
select is((select count(*) from storage.objects where bucket_id = 'reading-photos'), 0::bigint, 'simulation: no upload is left in Storage after 24 h');
create temporary table sla as
  select q.bucket_path as name, q.status, u.uploaded_at, q.completed_at, q.attempts, q.completed_at - u.uploaded_at as elapsed
  from public.photo_delete_queue q
  join (select 'ffffffff-0000-4000-8000-000000000001/f1000000-0000-4000-8000-' || lpad(k::text, 12, '0') || '/p0.jpg' as name,
               '2030-03-01T00:00:00Z'::timestamptz + make_interval(mins => k) as uploaded_at from generate_series(0, 59) k
        union all select 'ffffffff-0000-4000-8000-000000000001/f2000000-0000-4000-8000-000000000959/p0.jpg', '2030-03-01T00:09:59Z'
        union all select 'ffffffff-0000-4000-8000-000000000001/f2000000-0000-4000-8000-000000001001/p0.jpg', '2030-03-01T00:10:01Z') u
    on u.name = q.bucket_path;
select is((select count(*) from sla), 62::bigint, 'simulation: 62 uploads → 62 queue rows (each queued exactly once)');
select is((select count(*) from sla where completed_at is null or status <> 'done'), 0::bigint, 'simulation: every queue row is done within the 24 h window');
select ok((select max(elapsed) < interval '24 hours' from sla), 'D14: max(done − upload) < 24 h for every upload minute of the hour');
select is((select max(elapsed) from sla), interval '23 hours 10 minutes', 'D14: worst case is 23 h 10 m (22 h candidate + 1 h scan period + 5 m runner + one lost runner cycle)');
select results_eq(
  $$select elapsed from sla where name like '%/f2000000-0000-4000-8000-000000000959/%'
    union all select elapsed from sla where name like '%/f1000000-0000-4000-8000-000000000010/%'
    union all select elapsed from sla where name like '%/f2000000-0000-4000-8000-000000001001/%'$$,
  $$values (interval '22 hours 10 minutes 1 second'), (interval '23 hours 10 minutes'), (interval '23 hours 9 minutes 59 seconds')$$,
  'boundary: upload :09:59 → 22 h 10 m 01 s · :10:00 → 23 h 10 m · :10:01 → 23 h 09 m 59 s');
select is((select count(*) from sla where attempts <> 2), 0::bigint, 'simulation: each row needed the lost claim + one more (attempts 2), as modelled');
select ok((select min(completed_at) >= '2030-03-01T00:00:00Z'::timestamptz + interval '22 hours' from sla), 'nothing is deleted before 22 h (residue scan never touches fresh uploads)');

select * from finish();
rollback;
