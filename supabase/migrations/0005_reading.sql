-- =============================================================================
-- S03 · 0005_reading.sql — D16 · D17 reading ledger, job queue, transitions,
-- photo delete queue, purge-all, delete-account.
--
-- All functions here are service_role only (Edge Functions verify the user JWT
-- and pass p_user). Every write goes through next_server_seq() under the user
-- advisory lock. Outcome codes are the Edge/HTTP contract (docs/reading-api.md).
-- =============================================================================

create or replace function public.reading_request_json(r public.reading_requests)
returns jsonb language sql immutable
set search_path = public, pg_temp
as $$
  select jsonb_build_object(
    'request_id', r.request_id, 'status', r.status, 'server_version', r.server_version, 'server_seq', r.server_seq,
    'submitted_at', r.submitted_at, 'completed_at', r.completed_at, 'fail_reason', r.fail_reason,
    'quota_month', r.quota_month, 'quota_charged', coalesce(r.quota_charged, false), 'payload_hash', r.payload_hash,
    'subject_id', r.subject_id, 'range_text', r.range_text, 'origin', r.origin,
    'session_id', r.session_id, 'planner_item_id', r.planner_item_id,
    'result_json', case when r.status in ('done_unsaved','saved') then r.result_json else null end,
    'marks_json', case when r.status = 'saved' then r.marks_json else null end)
$$;
revoke execute on function public.reading_request_json(public.reading_requests) from public, anon, authenticated, service_role;

create or replace function public.quota_json(p_user uuid, p_month text)
returns jsonb language sql stable security definer
set search_path = public, pg_temp
as $$
  select jsonb_build_object('month', p_month, 'used', coalesce(q.used, 0), 'reserved', coalesce(q.reserved, 0),
                            'limit', coalesce(q.quota_limit, 20))
  from (select 1) x left join public.reading_quota q on q.user_id = p_user and q.month = p_month
$$;
revoke execute on function public.quota_json(uuid, text) from public, anon, authenticated, service_role;

-- processing → taking_long after 60 s ([S03] threshold; UI "오래 걸림").
create or replace function public.reading_mark_taking_long(p_user uuid)
returns int language plpgsql security definer
set search_path = public, pg_temp
as $$
declare r record; n int := 0;
begin
  for r in
    select id from public.reading_requests
    where user_id = p_user and status = 'processing' and deleted_at is null
      and public.ts(submitted_at) < now() - interval '60 seconds'
  loop
    update public.reading_requests
    set status = 'taking_long', server_version = server_version + 1, server_received_at = now(),
        server_seq = public.next_server_seq(p_user)
    where id = r.id;
    n := n + 1;
  end loop;
  return n;
end $$;
revoke execute on function public.reading_mark_taking_long(uuid) from public, anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- reading_submit (D16 ①–⑥)
-- p_payload: {subject_id, range_text, origin, session_id?, planner_item_id?,
--             object_paths:[text], created_at?, client_updated_at?}
-- ---------------------------------------------------------------------------
create or replace function public.reading_submit(p_user uuid, p_request_id text, p_payload jsonb, p_device_id text default null)
returns jsonb language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  r public.reading_requests%rowtype;
  e record;
  v_hash text;
  v_canonical jsonb;
  v_paths text[];
  v_now text := public.iso_utc(now());
  v_month text := public.kst_month(now());
  v_other text;
  q public.reading_quota%rowtype;
  v_seq bigint;
  p text;
begin
  if p_user is null or p_request_id is null then
    raise exception 'invalid_request' using errcode = 'P0001';
  end if;
  perform public.user_lock(p_user);
  if not exists (select 1 from public.profiles where user_id = p_user) then
    raise exception 'no_profile' using errcode = 'P0001';
  end if;

  -- ② entitlement (D18 ledger) and consent ②
  select * into e from public.entitlement_status(p_user);
  if not e.entitled then
    return jsonb_build_object('outcome', 'not_entitled', 'status_code', 403, 'entitlement', e.status);
  end if;
  if not public.reading_consent_active(p_user) then
    return jsonb_build_object('outcome', 'consent_required', 'status_code', 403);
  end if;

  -- payload validation + hash
  select coalesce(array_agg(x), '{}') into v_paths from jsonb_array_elements_text(coalesce(p_payload -> 'object_paths', '[]'::jsonb)) x;
  if cardinality(v_paths) = 0 then
    return jsonb_build_object('outcome', 'invalid_payload', 'status_code', 400, 'detail', 'object_paths');
  end if;
  foreach p in array v_paths loop
    if position(p_user::text || '/' || p_request_id || '/' in p) <> 1 then
      return jsonb_build_object('outcome', 'invalid_payload', 'status_code', 400, 'detail', 'object_path_prefix');
    end if;
  end loop;
  if (p_payload ->> 'origin') not in ('planner','wrongs','home')
     or coalesce(char_length(p_payload ->> 'range_text'), 0) not between 1 and 40
     or (p_payload ->> 'subject_id') is null then
    return jsonb_build_object('outcome', 'invalid_payload', 'status_code', 400, 'detail', 'fields');
  end if;
  v_canonical := jsonb_build_object(
    'subject_id', p_payload ->> 'subject_id', 'range_text', p_payload ->> 'range_text', 'origin', p_payload ->> 'origin',
    'session_id', p_payload ->> 'session_id', 'planner_item_id', p_payload ->> 'planner_item_id',
    'object_paths', to_jsonb(v_paths));
  v_hash := encode(sha256(convert_to(v_canonical::text, 'UTF8')), 'hex');

  -- ③ lookup: deleted first, then submitted
  select * into r from public.reading_requests where user_id = p_user and request_id = p_request_id for update;
  if found then
    if r.deleted_at is not null then
      return jsonb_build_object('outcome', 'request_deleted', 'status_code', 410);
    end if;
    if r.submitted_at is not null then
      if r.payload_hash = v_hash then
        return jsonb_build_object('outcome', 'accepted', 'idempotent', true, 'request', public.reading_request_json(r),
                                  'quota', public.quota_json(p_user, coalesce(r.quota_month, v_month)));
      end if;
      return jsonb_build_object('outcome', 'payload_mismatch', 'status_code', 409, 'status', r.status);
    end if;
    if not (r.status = 'selecting') then
      return jsonb_build_object('outcome', 'invalid_state', 'status_code', 409, 'status', r.status);
    end if;
  end if;

  -- ④ one active / unsaved per account (D17)
  select request_id into v_other from public.reading_requests
  where user_id = p_user and deleted_at is null and status in ('processing','taking_long','done_unsaved')
    and request_id <> p_request_id limit 1;
  if v_other is not null then
    return jsonb_build_object('outcome', 'active_exists', 'status_code', 409, 'request_id', v_other);
  end if;

  -- ⑤ quota (month fixed at submit time, KST)
  insert into public.reading_quota (user_id, month) values (p_user, v_month) on conflict do nothing;
  select * into q from public.reading_quota where user_id = p_user and month = v_month for update;
  if q.quota_limit - q.used - q.reserved <= 0 then
    return jsonb_build_object('outcome', 'quota_exhausted', 'status_code', 409, 'quota', public.quota_json(p_user, v_month));
  end if;

  -- ⑥ reserve + lock draft + job + worker kick
  update public.reading_quota set reserved = reserved + 1 where user_id = p_user and month = v_month;
  v_seq := public.next_server_seq(p_user);
  if r.id is null then
    insert into public.reading_requests (id, user_id, created_at, client_updated_at, deleted_at, device_id, purge_epoch,
      server_version, server_received_at, server_seq, request_id, subject_id, range_text, session_id, planner_item_id, origin,
      payload_hash, status, submitted_at, quota_month, quota_charged)
    select p_request_id, p_user, coalesce(p_payload ->> 'created_at', v_now), coalesce(p_payload ->> 'client_updated_at', v_now),
      null, coalesce(p_device_id, 'server'), pr.purge_epoch, 1, now(), v_seq, p_request_id,
      p_payload ->> 'subject_id', p_payload ->> 'range_text', p_payload ->> 'session_id', p_payload ->> 'planner_item_id',
      p_payload ->> 'origin', v_hash, 'processing', v_now, v_month, false
    from public.profiles pr where pr.user_id = p_user;
  else
    update public.reading_requests
    set subject_id = p_payload ->> 'subject_id', range_text = p_payload ->> 'range_text',
        session_id = p_payload ->> 'session_id', planner_item_id = p_payload ->> 'planner_item_id',
        origin = p_payload ->> 'origin', payload_hash = v_hash, status = 'processing', submitted_at = v_now,
        quota_month = v_month, quota_charged = false, server_version = server_version + 1,
        server_received_at = now(), server_seq = v_seq
    where id = r.id;
  end if;
  insert into public.reading_jobs (request_id, user_id, deadline, lease_until, attempts, object_paths)
  values (p_request_id, p_user, now() + interval '10 minutes', null, 0, v_paths);
  perform public.invoke_edge('reading-worker', jsonb_build_object('request_id', p_request_id));

  select * into r from public.reading_requests where user_id = p_user and request_id = p_request_id;
  return jsonb_build_object('outcome', 'accepted', 'idempotent', false, 'request', public.reading_request_json(r),
                            'quota', public.quota_json(p_user, v_month));
end $$;
revoke execute on function public.reading_submit(uuid, text, jsonb, text) from public, anon, authenticated;
grant execute on function public.reading_submit(uuid, text, jsonb, text) to service_role;

-- ---------------------------------------------------------------------------
-- reading_status
-- ---------------------------------------------------------------------------
create or replace function public.reading_status(p_user uuid, p_request_id text)
returns jsonb language plpgsql security definer
set search_path = public, pg_temp
as $$
declare r public.reading_requests%rowtype;
begin
  if not exists (select 1 from public.profiles where user_id = p_user) then
    raise exception 'no_profile' using errcode = 'P0001';
  end if;
  select * into r from public.reading_requests where user_id = p_user and request_id = p_request_id;
  if not found then
    return jsonb_build_object('outcome', 'not_found', 'status_code', 404);
  end if;
  if r.deleted_at is not null then
    return jsonb_build_object('outcome', 'request_deleted', 'status_code', 410);
  end if;
  if r.status = 'processing' and public.ts(r.submitted_at) < now() - interval '60 seconds' then
    perform public.user_lock(p_user);
    perform public.reading_mark_taking_long(p_user);
    select * into r from public.reading_requests where id = r.id;
  end if;
  return jsonb_build_object('outcome', 'ok') || public.reading_request_json(r)
         || jsonb_build_object('quota', public.quota_json(p_user, coalesce(r.quota_month, public.kst_month(now()))));
end $$;
revoke execute on function public.reading_status(uuid, text) from public, anon, authenticated;
grant execute on function public.reading_status(uuid, text) to service_role;

-- ---------------------------------------------------------------------------
-- reading_finish — the single terminal transition (first call wins)
-- ---------------------------------------------------------------------------
create or replace function public.reading_finish(p_request_id text, p_outcome text, p_result jsonb default null, p_fail_reason text default null)
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
  select * into r from public.reading_requests where request_id = p_request_id and deleted_at is null limit 1;
  if not found then
    return jsonb_build_object('outcome', 'noop', 'status', null);
  end if;
  perform public.user_lock(r.user_id);
  select * into r from public.reading_requests where id = r.id for update;
  if r.status not in ('processing','taking_long') then
    return jsonb_build_object('outcome', 'noop', 'status', r.status, 'request', public.reading_request_json(r));
  end if;

  select purge_epoch into v_epoch from public.profiles where user_id = r.user_id;
  if v_epoch is distinct from r.purge_epoch then
    v_outcome := 'cancelled'; v_reason := 'purge';
  end if;
  if v_outcome = 'done' and p_result is null then
    v_outcome := 'failed'; v_reason := coalesce(v_reason, 'empty_result');
  end if;

  if v_outcome = 'done' then
    update public.reading_quota set used = used + 1, reserved = greatest(0, reserved - 1)
    where user_id = r.user_id and month = r.quota_month;
    update public.reading_requests
    set status = 'done_unsaved', result_json = p_result, completed_at = v_now, quota_charged = true, fail_reason = null,
        server_version = server_version + 1, server_received_at = now(), server_seq = public.next_server_seq(r.user_id)
    where id = r.id;
  else
    update public.reading_quota set reserved = greatest(0, reserved - 1)
    where user_id = r.user_id and month = r.quota_month;
    update public.reading_requests
    set status = v_outcome, completed_at = v_now, fail_reason = v_reason,
        server_version = server_version + 1, server_received_at = now(), server_seq = public.next_server_seq(r.user_id)
    where id = r.id;
  end if;

  -- job row → delete; photo paths → delete queue (persistent, same txn)
  delete from public.reading_jobs where request_id = p_request_id returning object_paths into v_paths;
  if v_paths is not null then
    foreach p in array v_paths loop
      insert into public.photo_delete_queue (request_id, user_id, bucket_path) values (p_request_id, r.user_id, p);
    end loop;
  end if;

  select * into r from public.reading_requests where id = r.id;
  return jsonb_build_object('outcome', v_outcome, 'status', r.status, 'user_id', r.user_id,
                            'object_paths', to_jsonb(coalesce(v_paths, '{}')), 'request', public.reading_request_json(r));
end $$;
revoke execute on function public.reading_finish(text, text, jsonb, text) from public, anon, authenticated;
grant execute on function public.reading_finish(text, text, jsonb, text) to service_role;

-- ---------------------------------------------------------------------------
-- worker: atomic claim (D16 selection SQL)
-- ---------------------------------------------------------------------------
create or replace function public.reading_claim_job()
returns jsonb language plpgsql security definer
set search_path = public, pg_temp
as $$
declare j public.reading_jobs%rowtype; r public.reading_requests%rowtype;
begin
  update public.reading_jobs
  set lease_until = now() + interval '3 minutes', attempts = attempts + 1
  where request_id = (
    select request_id from public.reading_jobs
    where (lease_until is null or lease_until <= now()) and deadline > now() and attempts < 2
    order by created_at for update skip locked limit 1)
  returning * into j;
  if not found then
    return null;
  end if;
  select * into r from public.reading_requests where request_id = j.request_id;
  return jsonb_build_object('request_id', j.request_id, 'user_id', j.user_id, 'attempts', j.attempts,
                            'lease_until', public.iso_utc(j.lease_until), 'deadline', public.iso_utc(j.deadline),
                            'object_paths', to_jsonb(j.object_paths),
                            'subject_id', r.subject_id, 'range_text', r.range_text, 'status', r.status);
end $$;
revoke execute on function public.reading_claim_job() from public, anon, authenticated;
grant execute on function public.reading_claim_job() to service_role;

-- reaper (1-min cron): taking_long flips + timeouts → reading_finish(failed,'timeout')
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
    select j.request_id from public.reading_jobs j
    where j.deadline < now() or (j.attempts >= 2 and (j.lease_until is null or j.lease_until <= now()))
    union
    select r.request_id from public.reading_requests r
    where r.status in ('processing','taking_long') and r.deleted_at is null
      and not exists (select 1 from public.reading_jobs j where j.request_id = r.request_id)
      and public.ts(r.submitted_at) < now() - interval '10 minutes'
  loop
    v_fin := public.reading_finish(rec.request_id, 'failed', null, 'timeout');
    if v_fin ->> 'outcome' <> 'noop' then
      v_out := v_out || jsonb_build_object('request_id', rec.request_id, 'user_id', v_fin -> 'user_id', 'object_paths', v_fin -> 'object_paths');
    else
      delete from public.reading_jobs where request_id = rec.request_id;   -- stale job of a finished request
    end if;
  end loop;
  return jsonb_build_object('finished', v_out);
end $$;
revoke execute on function public.reading_reaper_run() from public, anon, authenticated;
grant execute on function public.reading_reaper_run() to service_role;

-- expire (daily): done_unsaved older than 7 days → expired + result_json null (D8)
create or replace function public.reading_expire_run()
returns int language plpgsql security definer
set search_path = public, pg_temp
as $$
declare rec record; n int := 0;
begin
  for rec in
    select id, user_id from public.reading_requests
    where status = 'done_unsaved' and deleted_at is null and public.ts(completed_at) < now() - interval '7 days'
  loop
    perform public.user_lock(rec.user_id);
    update public.reading_requests
    set status = 'expired', result_json = null, server_version = server_version + 1, server_received_at = now(),
        server_seq = public.next_server_seq(rec.user_id)
    where id = rec.id and status = 'done_unsaved';
    n := n + 1;
  end loop;
  return n;
end $$;
revoke execute on function public.reading_expire_run() from public, anon, authenticated;
grant execute on function public.reading_expire_run() to service_role;

-- ---------------------------------------------------------------------------
-- photo delete queue
-- ---------------------------------------------------------------------------
create or replace function public.photo_delete_claim(p_limit int default 50)
returns jsonb language plpgsql security definer
set search_path = public, pg_temp
as $$
declare v jsonb;
begin
  with c as (
    select id from public.photo_delete_queue
    where status = 'pending' and next_at <= now()
    order by next_at for update skip locked limit greatest(1, least(coalesce(p_limit, 50), 200))
  ), u as (
    update public.photo_delete_queue q set next_at = now() + interval '5 minutes', attempts = attempts + 1
    from c where q.id = c.id returning q.id, q.request_id, q.bucket_path, q.attempts
  )
  select coalesce(jsonb_agg(jsonb_build_object('id', id, 'request_id', request_id, 'bucket_path', bucket_path, 'attempts', attempts)), '[]'::jsonb)
  into v from u;
  return v;
end $$;
revoke execute on function public.photo_delete_claim(int) from public, anon, authenticated;
grant execute on function public.photo_delete_claim(int) to service_role;

create or replace function public.photo_delete_mark(p_ids bigint[], p_ok boolean)
returns int language plpgsql security definer
set search_path = public, pg_temp
as $$
declare n int;
begin
  if p_ok then
    update public.photo_delete_queue set status = 'done', completed_at = now() where id = any (p_ids) and status = 'pending';
  else
    update public.photo_delete_queue
    set next_at = now() + least(interval '5 minutes' * greatest(attempts, 1), interval '1 hour')
    where id = any (p_ids) and status = 'pending';
  end if;
  get diagnostics n = row_count;
  return n;
end $$;
revoke execute on function public.photo_delete_mark(bigint[], boolean) from public, anon, authenticated;
grant execute on function public.photo_delete_mark(bigint[], boolean) to service_role;

-- Mark paths done by (request_id, path) right after an immediate Storage delete.
create or replace function public.photo_delete_done(p_request_id text, p_paths text[])
returns int language plpgsql security definer
set search_path = public, pg_temp
as $$
declare n int;
begin
  update public.photo_delete_queue set status = 'done', completed_at = now()
  where request_id = p_request_id and bucket_path = any (p_paths) and status = 'pending';
  get diagnostics n = row_count;
  return n;
end $$;
revoke execute on function public.photo_delete_done(text, text[]) from public, anon, authenticated;
grant execute on function public.photo_delete_done(text, text[]) to service_role;

-- ---------------------------------------------------------------------------
-- reading_save (done_unsaved → saved)
-- p_marks: [{page_index, number, mark, wrong_item_id?}] (all confirmed marks)
-- p_items: [{id, page_index, number, mark, confidence, user_confirmed}] (non-correct only)
-- ---------------------------------------------------------------------------
create or replace function public.wrong_item_json(w public.wrong_items)
returns jsonb language sql immutable
set search_path = public, pg_temp
as $$
  select jsonb_build_object('id', w.id, 'request_id', w.request_id, 'subject_id', w.subject_id, 'range_text', w.range_text,
    'page_index', w.page_index, 'number', w.number, 'mark', w.mark, 'confidence', w.confidence,
    'user_confirmed', w.user_confirmed, 'status', w.status, 'resolved_at', w.resolved_at,
    'server_version', w.server_version, 'server_seq', w.server_seq, 'created_at', w.created_at,
    'client_updated_at', w.client_updated_at, 'device_id', w.device_id, 'purge_epoch', w.purge_epoch, 'deleted_at', w.deleted_at)
$$;
revoke execute on function public.wrong_item_json(public.wrong_items) from public, anon, authenticated, service_role;

create or replace function public.review_entry_json(e public.review_entries)
returns jsonb language sql immutable
set search_path = public, pg_temp
as $$
  select jsonb_build_object('id', e.id, 'wrong_item_id', e.wrong_item_id, 'due_at', e.due_at, 'interval_days', e.interval_days,
    'consecutive_correct', e.consecutive_correct, 'last_result', e.last_result, 'server_version', e.server_version,
    'server_seq', e.server_seq, 'created_at', e.created_at, 'client_updated_at', e.client_updated_at,
    'device_id', e.device_id, 'purge_epoch', e.purge_epoch, 'deleted_at', e.deleted_at)
$$;
revoke execute on function public.review_entry_json(public.review_entries) from public, anon, authenticated, service_role;

create or replace function public.reading_items_json(p_user uuid, p_request_id text)
returns jsonb language sql stable security definer
set search_path = public, pg_temp
as $$
  select jsonb_build_object(
    'items', coalesce((select jsonb_agg(public.wrong_item_json(w) order by w.page_index, w.number) from public.wrong_items w
                       where w.user_id = p_user and w.request_id = p_request_id and w.deleted_at is null), '[]'::jsonb),
    'entries', coalesce((select jsonb_agg(public.review_entry_json(e) order by e.due_at) from public.review_entries e
                         join public.wrong_items w on w.id = e.wrong_item_id and w.deleted_at is null
                         where w.user_id = p_user and w.request_id = p_request_id and e.deleted_at is null), '[]'::jsonb))
$$;
revoke execute on function public.reading_items_json(uuid, text) from public, anon, authenticated, service_role;

create or replace function public.reading_validate_marks(p_marks jsonb)
returns text language plpgsql immutable
set search_path = public, pg_temp
as $$
declare v_m jsonb;
begin
  if p_marks is null or jsonb_typeof(p_marks) <> 'array' then return 'marks_not_array'; end if;
  for v_m in select * from jsonb_array_elements(p_marks) loop
    if jsonb_typeof(v_m -> 'page_index') <> 'number' or jsonb_typeof(v_m -> 'number') <> 'number'
       or (v_m ->> 'mark') not in ('correct','wrong','partial','unsolved','guessed') then
      return 'mark_invalid';
    end if;
    if (v_m ->> 'mark') <> 'correct' and (v_m ->> 'wrong_item_id') !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
      return 'wrong_item_id_required';
    end if;
  end loop;
  if (select count(*) from jsonb_array_elements(p_marks) x) <>
     (select count(distinct (x ->> 'page_index') || ':' || (x ->> 'number')) from jsonb_array_elements(p_marks) x) then
    return 'mark_duplicate';
  end if;
  return null;
end $$;
revoke execute on function public.reading_validate_marks(jsonb) from public, anon, authenticated, service_role;

create or replace function public.reading_save(p_user uuid, p_request_id text, p_marks jsonb, p_items jsonb, p_device_id text default null)
returns jsonb language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  r public.reading_requests%rowtype;
  it jsonb;
  v_now text := public.iso_utc(now());
  v_err text;
  v_dev text := coalesce(p_device_id, 'server');
  v_ids text[];
begin
  perform public.user_lock(p_user);
  if not exists (select 1 from public.profiles where user_id = p_user) then
    raise exception 'no_profile' using errcode = 'P0001';
  end if;
  select * into r from public.reading_requests where user_id = p_user and request_id = p_request_id for update;
  if not found then
    return jsonb_build_object('outcome', 'not_found', 'status_code', 404);
  end if;
  if r.deleted_at is not null then
    return jsonb_build_object('outcome', 'request_deleted', 'status_code', 410);
  end if;
  if r.status = 'saved' then
    return jsonb_build_object('outcome', 'already_saved', 'marks', r.marks_json) || public.reading_items_json(p_user, p_request_id);
  end if;
  if r.status <> 'done_unsaved' then
    return jsonb_build_object('outcome', 'not_unsaved', 'status', r.status);
  end if;

  v_err := public.reading_validate_marks(p_marks);
  if v_err is not null then
    return jsonb_build_object('outcome', 'invalid_payload', 'status_code', 400, 'detail', v_err);
  end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' then
    return jsonb_build_object('outcome', 'invalid_payload', 'status_code', 400, 'detail', 'items_not_array');
  end if;
  select coalesce(array_agg(x ->> 'id'), '{}') into v_ids from jsonb_array_elements(p_items) x where (x ->> 'mark') <> 'correct';
  if cardinality(v_ids) <> cardinality(array(select distinct unnest(v_ids))) then
    return jsonb_build_object('outcome', 'invalid_payload', 'status_code', 400, 'detail', 'item_id_duplicate');
  end if;
  if exists (select 1 from public.wrong_items where id = any (v_ids)) then
    return jsonb_build_object('outcome', 'id_reused', 'status_code', 409);
  end if;

  for it in select * from jsonb_array_elements(p_items) loop
    continue when (it ->> 'mark') = 'correct';
    insert into public.wrong_items (id, user_id, created_at, client_updated_at, deleted_at, device_id, purge_epoch,
      server_version, server_received_at, server_seq, request_id, subject_id, range_text, page_index, number, mark,
      confidence, user_confirmed, status)
    values (it ->> 'id', p_user, v_now, v_now, null, v_dev, r.purge_epoch, 1, now(), public.next_server_seq(p_user),
      p_request_id, r.subject_id, r.range_text, (it ->> 'page_index')::int, (it ->> 'number')::int, it ->> 'mark',
      coalesce((it ->> 'confidence')::real, 1.0), coalesce((it ->> 'user_confirmed')::boolean, false), 'open');
    -- D9 initial review entry: 1 day
    insert into public.review_entries (id, user_id, created_at, client_updated_at, deleted_at, device_id, purge_epoch,
      server_version, server_received_at, server_seq, wrong_item_id, due_at, interval_days, consecutive_correct)
    values (gen_random_uuid()::text, p_user, v_now, v_now, null, v_dev, r.purge_epoch, 1, now(), public.next_server_seq(p_user),
      it ->> 'id', public.iso_utc(now() + interval '1 day'), 1, 0);
  end loop;

  update public.reading_requests
  set status = 'saved', marks_json = p_marks, server_version = server_version + 1, server_received_at = now(),
      server_seq = public.next_server_seq(p_user)
  where id = r.id;

  return jsonb_build_object('outcome', 'saved', 'marks', p_marks) || public.reading_items_json(p_user, p_request_id);
end $$;
revoke execute on function public.reading_save(uuid, text, jsonb, jsonb, text) from public, anon, authenticated;
grant execute on function public.reading_save(uuid, text, jsonb, jsonb, text) to service_role;

-- reading_discard (done_unsaved → discarded, result_json null; D8)
create or replace function public.reading_discard(p_user uuid, p_request_id text)
returns jsonb language plpgsql security definer
set search_path = public, pg_temp
as $$
declare r public.reading_requests%rowtype;
begin
  perform public.user_lock(p_user);
  select * into r from public.reading_requests where user_id = p_user and request_id = p_request_id for update;
  if not found then return jsonb_build_object('outcome', 'not_found', 'status_code', 404); end if;
  if r.deleted_at is not null then return jsonb_build_object('outcome', 'request_deleted', 'status_code', 410); end if;
  if r.status <> 'done_unsaved' then return jsonb_build_object('outcome', 'not_unsaved', 'status', r.status); end if;
  update public.reading_requests
  set status = 'discarded', result_json = null, server_version = server_version + 1, server_received_at = now(),
      server_seq = public.next_server_seq(p_user)
  where id = r.id;
  return jsonb_build_object('outcome', 'discarded');
end $$;
revoke execute on function public.reading_discard(uuid, text) from public, anon, authenticated;
grant execute on function public.reading_discard(uuid, text) to service_role;

-- ---------------------------------------------------------------------------
-- reading_update_marks (saved only; D16)
-- p_entries: [{id, wrong_item_id, due_at, interval_days, consecutive_correct, last_result?}]
-- ---------------------------------------------------------------------------
create or replace function public.reading_update_marks(p_user uuid, p_request_id text, p_marks jsonb, p_entries jsonb, p_device_id text default null)
returns jsonb language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  r public.reading_requests%rowtype;
  m jsonb;
  en jsonb;
  v_now text := public.iso_utc(now());
  v_dev text := coalesce(p_device_id, 'server');
  v_err text;
  v_keep text[] := '{}';
  v_new text[] := '{}';
  v_id text;
  w public.wrong_items%rowtype;
  e public.review_entries%rowtype;
  v_entry_wrong text[] := '{}';
begin
  perform public.user_lock(p_user);
  if not exists (select 1 from public.profiles where user_id = p_user) then
    raise exception 'no_profile' using errcode = 'P0001';
  end if;
  select * into r from public.reading_requests where user_id = p_user and request_id = p_request_id for update;
  if not found or r.deleted_at is not null or r.status <> 'saved' then
    return jsonb_build_object('outcome', 'not_saved', 'status', case when found and r.deleted_at is null then r.status else null end);
  end if;
  v_err := public.reading_validate_marks(p_marks);
  if v_err is not null then
    return jsonb_build_object('outcome', 'invalid_payload', 'status_code', 400, 'detail', v_err);
  end if;
  if p_entries is not null and jsonb_typeof(p_entries) <> 'array' then
    return jsonb_build_object('outcome', 'invalid_payload', 'status_code', 400, 'detail', 'entries_not_array');
  end if;

  -- pass 1: validate ids (tombstone reuse → id_reused, no writes)
  for m in select * from jsonb_array_elements(p_marks) loop
    continue when (m ->> 'mark') = 'correct';
    v_id := m ->> 'wrong_item_id';
    select * into w from public.wrong_items where id = v_id;
    if found then
      if w.deleted_at is not null or w.user_id <> p_user or w.request_id <> p_request_id then
        return jsonb_build_object('outcome', 'id_reused', 'status_code', 409, 'wrong_item_id', v_id);
      end if;
      v_keep := v_keep || v_id;
    else
      v_new := v_new || v_id;
    end if;
  end loop;
  if cardinality(v_new) <> cardinality(array(select distinct unnest(v_new))) then
    return jsonb_build_object('outcome', 'invalid_payload', 'status_code', 400, 'detail', 'wrong_item_id_duplicate');
  end if;
  for en in select * from jsonb_array_elements(coalesce(p_entries, '[]'::jsonb)) loop
    if (en ->> 'wrong_item_id') <> all (v_keep || v_new)
       or coalesce((en ->> 'interval_days')::int, 0) not in (1,2,4,8,16,30)
       or coalesce((en ->> 'consecutive_correct')::int, -1) not between 0 and 1
       or (en ->> 'due_at') !~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,6})?Z$'
       or (en ->> 'id') !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
       or ((en ->> 'last_result') is not null and (en ->> 'last_result') not in ('correct','partial','wrong')) then
      return jsonb_build_object('outcome', 'invalid_payload', 'status_code', 400, 'detail', 'entry_invalid');
    end if;
    v_entry_wrong := v_entry_wrong || (en ->> 'wrong_item_id');
  end loop;

  -- pass 2: apply
  for m in select * from jsonb_array_elements(p_marks) loop
    continue when (m ->> 'mark') = 'correct';
    v_id := m ->> 'wrong_item_id';
    if v_id = any (v_keep) then
      update public.wrong_items
      set mark = m ->> 'mark', page_index = (m ->> 'page_index')::int, number = (m ->> 'number')::int, user_confirmed = true,
          client_updated_at = v_now, device_id = v_dev, server_version = server_version + 1, server_received_at = now(),
          server_seq = public.next_server_seq(p_user)
      where id = v_id and (mark <> (m ->> 'mark') or page_index <> (m ->> 'page_index')::int or number <> (m ->> 'number')::int or not user_confirmed);
    else
      insert into public.wrong_items (id, user_id, created_at, client_updated_at, deleted_at, device_id, purge_epoch,
        server_version, server_received_at, server_seq, request_id, subject_id, range_text, page_index, number, mark,
        confidence, user_confirmed, status)
      values (v_id, p_user, v_now, v_now, null, v_dev, r.purge_epoch, 1, now(), public.next_server_seq(p_user),
        p_request_id, r.subject_id, r.range_text, (m ->> 'page_index')::int, (m ->> 'number')::int, m ->> 'mark', 1.0, true, 'open');
      if v_id <> all (v_entry_wrong) then
        insert into public.review_entries (id, user_id, created_at, client_updated_at, deleted_at, device_id, purge_epoch,
          server_version, server_received_at, server_seq, wrong_item_id, due_at, interval_days, consecutive_correct)
        values (gen_random_uuid()::text, p_user, v_now, v_now, null, v_dev, r.purge_epoch, 1, now(), public.next_server_seq(p_user),
          v_id, public.iso_utc(now() + interval '1 day'), 1, 0);
      end if;
    end if;
  end loop;

  -- items that became correct → tombstone wrong item + its review entries + retry records
  for v_id in
    select id from public.wrong_items where user_id = p_user and request_id = p_request_id and deleted_at is null
      and id <> all (v_keep || v_new)
  loop
    perform public.sync_tombstone('wrong_items', p_user, v_id, v_now, v_now, v_dev);
    perform public.sync_tombstone('review_entries', p_user, e2.id, v_now, v_now, v_dev)
      from public.review_entries e2 where e2.user_id = p_user and e2.wrong_item_id = v_id and e2.deleted_at is null;
    perform public.sync_tombstone('retry_records', p_user, r2.id, v_now, v_now, v_dev)
      from public.retry_records r2 where r2.user_id = p_user and r2.wrong_item_id = v_id and r2.deleted_at is null;
  end loop;

  -- client-computed review entries (ReviewScheduler, D9 validated above)
  for en in select * from jsonb_array_elements(coalesce(p_entries, '[]'::jsonb)) loop
    select * into e from public.review_entries where wrong_item_id = (en ->> 'wrong_item_id') and deleted_at is null;
    if found and e.id <> (en ->> 'id') then
      perform public.sync_tombstone('review_entries', p_user, e.id, v_now, v_now, v_dev);
    end if;
    if found and e.id = (en ->> 'id') then
      update public.review_entries
      set due_at = en ->> 'due_at', interval_days = (en ->> 'interval_days')::int,
          consecutive_correct = (en ->> 'consecutive_correct')::int, last_result = en ->> 'last_result',
          client_updated_at = v_now, device_id = v_dev, server_version = server_version + 1, server_received_at = now(),
          server_seq = public.next_server_seq(p_user)
      where id = e.id;
    else
      if exists (select 1 from public.review_entries where id = (en ->> 'id')) then
        raise exception 'entry_id_reused' using errcode = 'P0001';
      end if;
      insert into public.review_entries (id, user_id, created_at, client_updated_at, deleted_at, device_id, purge_epoch,
        server_version, server_received_at, server_seq, wrong_item_id, due_at, interval_days, consecutive_correct, last_result)
      values (en ->> 'id', p_user, v_now, v_now, null, v_dev, r.purge_epoch, 1, now(), public.next_server_seq(p_user),
        en ->> 'wrong_item_id', en ->> 'due_at', (en ->> 'interval_days')::int, (en ->> 'consecutive_correct')::int, en ->> 'last_result');
    end if;
  end loop;

  update public.reading_requests
  set marks_json = p_marks, server_version = server_version + 1, server_received_at = now(),
      server_seq = public.next_server_seq(p_user)
  where id = r.id;

  return jsonb_build_object('outcome', 'updated', 'marks', p_marks) || public.reading_items_json(p_user, p_request_id);
end $$;
revoke execute on function public.reading_update_marks(uuid, text, jsonb, jsonb, text) from public, anon, authenticated;
grant execute on function public.reading_update_marks(uuid, text, jsonb, jsonb, text) to service_role;

-- ---------------------------------------------------------------------------
-- purge-all (D2): cancel active → keep object paths → physical delete → epoch+1
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
    v_fin := public.reading_finish(rec.request_id, 'cancelled', null, 'purge');
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

-- delete-account (D5): everything except metrics_weekly; auth user deleted by the Edge function after.
create or replace function public.delete_account_data(p_user uuid)
returns jsonb language plpgsql security definer
set search_path = public, pg_temp
as $$
declare rec record; v_fin jsonb; v_paths jsonb := '[]'::jsonb; t text;
begin
  perform public.user_lock(p_user);
  for rec in select request_id from public.reading_requests
             where user_id = p_user and deleted_at is null and status in ('processing','taking_long') loop
    v_fin := public.reading_finish(rec.request_id, 'cancelled', null, 'account_deleted');
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
