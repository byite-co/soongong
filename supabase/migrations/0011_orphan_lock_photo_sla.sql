-- =============================================================================
-- S03b · 0011_orphan_lock_photo_sla.sql
--
-- 1. draft_orphan_tombstone_run: a candidate is tombstoned only after the user's
--    advisory lock is held AND the row still qualifies in the same transaction
--    (status = 'selecting', submitted_at is null, deleted_at is null,
--    client_updated_at older than 30 days). reading_submit and sync_push take the
--    same lock, so a submit or an edit that commits while the job waits makes the
--    job skip the row instead of tombstoning a processing request / a fresh edit.
-- 2. Photo residue SLA (D14 "24 hours"): candidates are objects older than 22 h
--    (hourly scan at :10 → ≤ 1 h wait, 5-minute runner, one lost runner cycle for
--    backlog → worst case 23 h 10 m, proven in tests/09_photo_sla.sql). The photo
--    pipeline reads the clock through app_now() so the proof can inject time
--    (`app.test_now`; unset in production → now()).
--
-- D27: new file only. Tests: tests/08_s03b_orphan_lock.sql, tests/09_photo_sla.sql.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. orphan drafts: lock → re-check → tombstone
-- ---------------------------------------------------------------------------
create or replace function public.draft_orphan_tombstone_run()
returns int language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  rec record;
  n int := 0;
  v_cutoff timestamptz := now() - interval '30 days';
begin
  for rec in
    select id, user_id from public.reading_requests
    where status = 'selecting' and submitted_at is null and deleted_at is null
      and public.ts(client_updated_at) < v_cutoff
    order by user_id, id
  loop
    -- Serialize with sync_push / reading_submit (same lock), then read the row again in
    -- this transaction: whatever committed while we waited decides.
    perform public.user_lock(rec.user_id);
    perform 1 from public.reading_requests r
    where r.id = rec.id and r.user_id = rec.user_id
      and r.status = 'selecting' and r.submitted_at is null and r.deleted_at is null
      and public.ts(r.client_updated_at) < v_cutoff
    for update;
    if not found then
      continue;
    end if;
    if public.sync_tombstone('reading_requests', rec.user_id, rec.id) then n := n + 1; end if;
  end loop;
  return n;
end $$;
revoke execute on function public.draft_orphan_tombstone_run() from public, anon, authenticated;
grant execute on function public.draft_orphan_tombstone_run() to service_role;

-- ---------------------------------------------------------------------------
-- 2a. app_now(): the photo pipeline's clock (tests inject `app.test_now`)
-- ---------------------------------------------------------------------------
create or replace function public.app_now()
returns timestamptz language sql stable
set search_path = public, pg_temp
as $$ select coalesce(nullif(current_setting('app.test_now', true), '')::timestamptz, now()) $$;
revoke execute on function public.app_now() from public, anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 2b. photo_residue_run: candidates older than 22 h (hourly scan at :10)
-- ---------------------------------------------------------------------------
create or replace function public.photo_residue_run(p_batch int default 500)
returns jsonb language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_now timestamptz := public.app_now();
  v_cutoff timestamptz := v_now - interval '22 hours';
  v_cur_at timestamptz := '-infinity';
  v_cur_id uuid := '00000000-0000-0000-0000-000000000000';
  v_batch int := greatest(1, least(coalesce(p_batch, 500), 1000));
  v_n int;
  v_scanned int := 0;
  v_queued int := 0;
  v_active int := 0;
  v_batches int := 0;
  o record;
  v_user text;
  v_req text;
begin
  loop
    v_n := 0;
    v_batches := v_batches + 1;
    for o in
      select s.id, s.name, s.created_at
      from storage.objects s
      where s.bucket_id = 'reading-photos'
        and s.created_at < v_cutoff
        and (s.created_at, s.id) > (v_cur_at, v_cur_id)
      order by s.created_at, s.id
      limit v_batch
    loop
      v_n := v_n + 1;
      v_scanned := v_scanned + 1;
      v_cur_at := o.created_at;
      v_cur_id := o.id;
      v_user := split_part(o.name, '/', 1);
      v_req := split_part(o.name, '/', 2);
      if exists (select 1 from public.reading_requests q
                 where q.user_id::text = v_user and q.request_id = v_req and q.deleted_at is null
                   and q.status in ('processing', 'taking_long')) then
        v_active := v_active + 1;
        continue;
      end if;
      if exists (select 1 from public.photo_delete_queue d where d.bucket_path = o.name and d.status = 'pending') then
        continue;
      end if;
      insert into public.photo_delete_queue (request_id, user_id, bucket_path, status, next_at)
      values (
        case when v_req ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then v_req end,
        case when v_user ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then v_user::uuid end,
        o.name, 'pending', v_now);
      v_queued := v_queued + 1;
    end loop;
    exit when v_n < v_batch;
  end loop;
  return jsonb_build_object('scanned', v_scanned, 'queued', v_queued, 'skipped_active', v_active, 'batches', v_batches);
end $$;
revoke execute on function public.photo_residue_run(int) from public, anon, authenticated;
grant execute on function public.photo_residue_run(int) to service_role;

-- ---------------------------------------------------------------------------
-- 2c. queue claim / mark on the same clock (bodies otherwise unchanged from 0005/0010)
-- ---------------------------------------------------------------------------
create or replace function public.photo_delete_claim(p_limit int default 50)
returns jsonb language plpgsql security definer
set search_path = public, pg_temp
as $$
declare v jsonb; v_now timestamptz := public.app_now();
begin
  with c as (
    select id from public.photo_delete_queue
    where status = 'pending' and next_at <= v_now
    order by next_at for update skip locked limit greatest(1, least(coalesce(p_limit, 50), 500))
  ), u as (
    update public.photo_delete_queue q set next_at = v_now + interval '5 minutes', attempts = attempts + 1
    from c where q.id = c.id returning q.id, q.user_id, q.request_id, q.bucket_path, q.attempts
  )
  select coalesce(jsonb_agg(jsonb_build_object('id', id, 'user_id', user_id, 'request_id', request_id, 'bucket_path', bucket_path, 'attempts', attempts)), '[]'::jsonb)
  into v from u;
  return v;
end $$;
revoke execute on function public.photo_delete_claim(int) from public, anon, authenticated;
grant execute on function public.photo_delete_claim(int) to service_role;

create or replace function public.photo_delete_mark(p_ids bigint[], p_ok boolean)
returns int language plpgsql security definer
set search_path = public, pg_temp
as $$
declare n int; v_now timestamptz := public.app_now();
begin
  if p_ok then
    update public.photo_delete_queue set status = 'done', completed_at = v_now where id = any (p_ids) and status = 'pending';
  else
    update public.photo_delete_queue
    set next_at = v_now + least(interval '5 minutes' * greatest(attempts, 1), interval '1 hour')
    where id = any (p_ids) and status = 'pending';
  end if;
  get diagnostics n = row_count;
  return n;
end $$;
revoke execute on function public.photo_delete_mark(bigint[], boolean) from public, anon, authenticated;
grant execute on function public.photo_delete_mark(bigint[], boolean) to service_role;
