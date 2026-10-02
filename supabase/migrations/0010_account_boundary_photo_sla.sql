-- =============================================================================
-- S03b · 0010_account_boundary_photo_sla.sql
--
-- 1. Account boundary on the reading ledger (D16: a request is identified by
--    (user_id, request_id), never by request_id alone):
--    · reading_jobs primary key → (user_id, request_id)
--    · reading_finish(p_user, p_request_id, p_outcome, p_result, p_fail_reason)
--      (the old 4-argument signature is dropped; every caller passes the owner)
--    · reading_claim_job · reading_reaper_run · purge_all · delete_account_data
--      select, lease and delete jobs by both keys
--    · photo_delete_done(p_user, p_request_id, p_paths); queue index on (user_id, request_id)
-- 2. Photo residue SLA (D14 "24 hours"): photo_residue_run() runs hourly (:10) with a
--    23 h candidate age (23 h + 1 h period ≤ 24 h), photo_delete_claim accepts up to
--    500 rows so the runner (500 × ≤10 rounds per 5-minute run) drains a backlog within
--    the hour.
--
-- D27: new file only. Tests: tests/07_s03b_boundary.sql, tests/06_s03b.sql.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1a. keys
-- ---------------------------------------------------------------------------
alter table public.reading_jobs drop constraint reading_jobs_pkey;
alter table public.reading_jobs add constraint reading_jobs_pkey primary key (user_id, request_id);
create index if not exists photo_delete_queue_user_request on public.photo_delete_queue (user_id, request_id);

-- ---------------------------------------------------------------------------
-- 1b. reading_finish(p_user, p_request_id, …) — the single terminal transition
-- ---------------------------------------------------------------------------
drop function if exists public.reading_finish(text, text, jsonb, text);

create or replace function public.reading_finish(p_user uuid, p_request_id text, p_outcome text, p_result jsonb default null, p_fail_reason text default null)
returns jsonb language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  r public.reading_requests%rowtype;
  v_epoch int;
  v_outcome text := p_outcome;
  v_reason text := p_fail_reason;
  v_paths text[] := '{}';
  v_now text := public.iso_utc(now());
  p text;
begin
  if p_outcome not in ('done','failed','cancelled') then
    raise exception 'invalid_outcome' using errcode = 'P0001';
  end if;
  if p_user is null then
    raise exception 'invalid_request' using errcode = 'P0001';
  end if;
  select * into r from public.reading_requests where user_id = p_user and request_id = p_request_id and deleted_at is null;
  if not found then
    return jsonb_build_object('outcome', 'noop', 'status', null);
  end if;
  perform public.user_lock(p_user);
  select * into r from public.reading_requests where id = r.id for update;
  if r.status not in ('processing','taking_long') then
    return jsonb_build_object('outcome', 'noop', 'status', r.status, 'request', public.reading_request_json(r));
  end if;

  select purge_epoch into v_epoch from public.profiles where user_id = p_user;
  if v_epoch is distinct from r.purge_epoch then
    v_outcome := 'cancelled'; v_reason := 'purge';
  end if;
  if v_outcome = 'done' and p_result is null then
    v_outcome := 'failed'; v_reason := coalesce(v_reason, 'empty_result');
  end if;

  if v_outcome = 'done' then
    update public.reading_quota set used = used + 1, reserved = greatest(0, reserved - 1)
    where user_id = p_user and month = r.quota_month;
    update public.reading_requests
    set status = 'done_unsaved', result_json = p_result, completed_at = v_now, quota_charged = true, fail_reason = null,
        server_version = server_version + 1, server_received_at = now(), server_seq = public.next_server_seq(p_user)
    where id = r.id;
  else
    update public.reading_quota set reserved = greatest(0, reserved - 1)
    where user_id = p_user and month = r.quota_month;
    update public.reading_requests
    set status = v_outcome, completed_at = v_now, fail_reason = v_reason,
        server_version = server_version + 1, server_received_at = now(), server_seq = public.next_server_seq(p_user)
    where id = r.id;
  end if;

  -- this user's job row → delete; its photo paths → delete queue (persistent, same txn)
  delete from public.reading_jobs where user_id = p_user and request_id = p_request_id returning object_paths into v_paths;
  if v_paths is not null then
    foreach p in array v_paths loop
      insert into public.photo_delete_queue (request_id, user_id, bucket_path) values (p_request_id, p_user, p);
    end loop;
  end if;

  select * into r from public.reading_requests where id = r.id;
  return jsonb_build_object('outcome', v_outcome, 'status', r.status, 'user_id', p_user, 'request_id', p_request_id,
                            'object_paths', to_jsonb(coalesce(v_paths, '{}')), 'request', public.reading_request_json(r));
end $$;
revoke execute on function public.reading_finish(uuid, text, text, jsonb, text) from public, anon, authenticated;
grant execute on function public.reading_finish(uuid, text, text, jsonb, text) to service_role;

-- ---------------------------------------------------------------------------
-- 1c. worker claim — one job, keyed by (user_id, request_id)
-- ---------------------------------------------------------------------------
create or replace function public.reading_claim_job()
returns jsonb language plpgsql security definer
set search_path = public, pg_temp
as $$
declare v_j public.reading_jobs%rowtype; r public.reading_requests%rowtype;
begin
  update public.reading_jobs
  set lease_until = now() + interval '3 minutes', attempts = attempts + 1
  where (user_id, request_id) = (
    select user_id, request_id from public.reading_jobs
    where (lease_until is null or lease_until <= now()) and deadline > now() and attempts < 2
    order by created_at for update skip locked limit 1)
  returning * into v_j;
  if not found then
    return null;
  end if;
  select * into r from public.reading_requests where user_id = v_j.user_id and request_id = v_j.request_id;
  return jsonb_build_object('request_id', v_j.request_id, 'user_id', v_j.user_id, 'attempts', v_j.attempts,
                            'lease_until', public.iso_utc(v_j.lease_until), 'deadline', public.iso_utc(v_j.deadline),
                            'object_paths', to_jsonb(v_j.object_paths),
                            'subject_id', r.subject_id, 'range_text', r.range_text, 'status', r.status);
end $$;
revoke execute on function public.reading_claim_job() from public, anon, authenticated;
grant execute on function public.reading_claim_job() to service_role;

-- ---------------------------------------------------------------------------
-- 1d. reaper — per (user_id, request_id)
-- ---------------------------------------------------------------------------
create or replace function public.reading_reaper_run()
returns jsonb language plpgsql security definer
set search_path = public, pg_temp
as $$
declare rec record; v_fin jsonb; v_out jsonb := '[]'::jsonb; u uuid;
begin
  for u in select distinct user_id from public.reading_requests where status = 'processing' and deleted_at is null
           and public.ts(submitted_at) < now() - interval '60 seconds' loop
    perform public.user_lock(u);
    perform public.reading_mark_taking_long(u);
  end loop;
  for rec in
    select j.user_id, j.request_id from public.reading_jobs j
    where j.deadline < now() or (j.attempts >= 2 and (j.lease_until is null or j.lease_until <= now()))
    union
    select r.user_id, r.request_id from public.reading_requests r
    where r.status in ('processing','taking_long') and r.deleted_at is null
      and not exists (select 1 from public.reading_jobs j where j.user_id = r.user_id and j.request_id = r.request_id)
      and public.ts(r.submitted_at) < now() - interval '10 minutes'
  loop
    v_fin := public.reading_finish(rec.user_id, rec.request_id, 'failed', null, 'timeout');
    if v_fin ->> 'outcome' <> 'noop' then
      v_out := v_out || jsonb_build_object('user_id', rec.user_id, 'request_id', rec.request_id, 'object_paths', v_fin -> 'object_paths');
    else
      delete from public.reading_jobs where user_id = rec.user_id and request_id = rec.request_id;   -- stale job of a finished request
    end if;
  end loop;
  return jsonb_build_object('finished', v_out);
end $$;
revoke execute on function public.reading_reaper_run() from public, anon, authenticated;
grant execute on function public.reading_reaper_run() to service_role;

-- ---------------------------------------------------------------------------
-- 1e. photo queue: done by (user, request, paths); claim cap 500
-- ---------------------------------------------------------------------------
drop function if exists public.photo_delete_done(text, text[]);

create or replace function public.photo_delete_done(p_user uuid, p_request_id text, p_paths text[])
returns int language plpgsql security definer
set search_path = public, pg_temp
as $$
declare n int;
begin
  update public.photo_delete_queue set status = 'done', completed_at = now()
  where user_id = p_user and request_id = p_request_id and bucket_path = any (p_paths) and status = 'pending';
  get diagnostics n = row_count;
  return n;
end $$;
revoke execute on function public.photo_delete_done(uuid, text, text[]) from public, anon, authenticated;
grant execute on function public.photo_delete_done(uuid, text, text[]) to service_role;

create or replace function public.photo_delete_claim(p_limit int default 50)
returns jsonb language plpgsql security definer
set search_path = public, pg_temp
as $$
declare v jsonb;
begin
  with c as (
    select id from public.photo_delete_queue
    where status = 'pending' and next_at <= now()
    order by next_at for update skip locked limit greatest(1, least(coalesce(p_limit, 50), 500))
  ), u as (
    update public.photo_delete_queue q set next_at = now() + interval '5 minutes', attempts = attempts + 1
    from c where q.id = c.id returning q.id, q.user_id, q.request_id, q.bucket_path, q.attempts
  )
  select coalesce(jsonb_agg(jsonb_build_object('id', id, 'user_id', user_id, 'request_id', request_id, 'bucket_path', bucket_path, 'attempts', attempts)), '[]'::jsonb)
  into v from u;
  return v;
end $$;
revoke execute on function public.photo_delete_claim(int) from public, anon, authenticated;
grant execute on function public.photo_delete_claim(int) to service_role;

-- ---------------------------------------------------------------------------
-- 1f. purge_all · delete_account_data call reading_finish with the owner
-- ---------------------------------------------------------------------------
create or replace function public.purge_all(p_user uuid)
returns jsonb language plpgsql security definer
set search_path = public, pg_temp
as $$
declare rec record; v_fin jsonb; v_paths jsonb := '[]'::jsonb; v_epoch int; t text;
begin
  perform public.user_lock(p_user);
  if not exists (select 1 from public.profiles where user_id = p_user) then
    raise exception 'no_profile' using errcode = 'P0001';
  end if;
  for rec in select request_id from public.reading_requests
             where user_id = p_user and deleted_at is null and status in ('processing','taking_long') loop
    v_fin := public.reading_finish(p_user, rec.request_id, 'cancelled', null, 'purge');
    v_paths := v_paths || coalesce(v_fin -> 'object_paths', '[]'::jsonb);
  end loop;
  -- pending queue rows of this user stay (the runner needs them); jobs of finished requests are gone.
  for t in select table_name from public.sync_tables loop
    execute format('delete from public.%I where user_id = $1', t) using p_user;
  end loop;
  delete from public.sync_mutations where user_id = p_user;
  update public.profiles set purge_epoch = purge_epoch + 1 where user_id = p_user returning purge_epoch into v_epoch;
  return jsonb_build_object('epoch', v_epoch, 'object_paths', v_paths);
end $$;
revoke execute on function public.purge_all(uuid) from public, anon, authenticated;
grant execute on function public.purge_all(uuid) to service_role;

create or replace function public.delete_account_data(p_user uuid)
returns jsonb language plpgsql security definer
set search_path = public, pg_temp
as $$
declare rec record; v_fin jsonb; v_paths jsonb := '[]'::jsonb; t text;
begin
  perform public.user_lock(p_user);
  for rec in select request_id from public.reading_requests
             where user_id = p_user and deleted_at is null and status in ('processing','taking_long') loop
    v_fin := public.reading_finish(p_user, rec.request_id, 'cancelled', null, 'account_deleted');
    v_paths := v_paths || coalesce(v_fin -> 'object_paths', '[]'::jsonb);
  end loop;
  select v_paths || coalesce(jsonb_agg(bucket_path), '[]'::jsonb) into v_paths
  from public.photo_delete_queue where user_id = p_user and status = 'pending';
  for t in select table_name from public.sync_tables loop
    execute format('delete from public.%I where user_id = $1', t) using p_user;
  end loop;
  delete from public.sync_mutations where user_id = p_user;
  delete from public.reading_jobs where user_id = p_user;
  delete from public.reading_quota where user_id = p_user;
  delete from public.subscription_events where user_id = p_user;
  delete from public.subscription_state where user_id = p_user;
  delete from public.review_due_snapshots where user_id = p_user;
  delete from public.inquiries where user_id = p_user;
  delete from public.signup_approvals where user_id = p_user;
  delete from public.profiles where user_id = p_user;
  delete from public.user_seq where user_id = p_user;
  return jsonb_build_object('object_paths', v_paths);
end $$;
revoke execute on function public.delete_account_data(uuid) from public, anon, authenticated;
grant execute on function public.delete_account_data(uuid) to service_role;

-- ---------------------------------------------------------------------------
-- 2. photo residue SLA: hourly at :10, candidates older than 23 h
--    (23 h candidate age + 1 h period ⇒ every object is queued ≤ 24 h after upload;
--     the 5-minute runner then drains 500 × ≤10 rounds per run)
-- ---------------------------------------------------------------------------
create or replace function public.photo_residue_run(p_batch int default 500)
returns jsonb language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_cutoff timestamptz := now() - interval '23 hours';
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
        o.name, 'pending', now());
      v_queued := v_queued + 1;
    end loop;
    exit when v_n < v_batch;
  end loop;
  return jsonb_build_object('scanned', v_scanned, 'queued', v_queued, 'skipped_active', v_active, 'batches', v_batches);
end $$;
revoke execute on function public.photo_residue_run(int) from public, anon, authenticated;
grant execute on function public.photo_residue_run(int) to service_role;

select public.cron_upsert('soongong-photo-residue', '10 * * * *',
  $$select public.photo_residue_run();$$);
