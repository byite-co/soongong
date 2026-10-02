-- =============================================================================
-- S03b · 0009_photo_residue_marks_validation.sql
--
-- 1. photo_residue_run(): the 24-hour photo safety net (D14) becomes a daily
--    SQL job that scans storage.objects directly and is independent of the
--    delete queue. The Edge photo-delete-runner only drains the queue now (its
--    "first 20 users · 50 folders" Storage listing scan is removed).
-- 2. reading_save / reading_update_marks input validation: marks[] entries need
--    page_index · number · mark (enum), non-correct marks need wrong_item_id;
--    items[] must be exactly the set of non-correct marks (id · page_index ·
--    number · mark) — missing, extra or differing rows → `marks_items_mismatch`.
--    Nothing is written before every check has passed.
--
-- D27: new file only, every object is create or replace. Tests: tests/06_s03b.sql.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. photo residue scan (storage.objects → photo_delete_queue)
--    Objects of bucket `reading-photos` older than 24 h whose path
--    <user_id>/<request_id>/pN.jpg does not belong to an active
--    (processing · taking_long) request are queued as `pending`. Walks the whole
--    bucket with a (created_at, id) cursor, p_batch rows per round, so a
--    backlog > 500 is fully queued in one run. Paths already `pending` are not
--    queued twice; `done` rows do not block (the object is still there).
--    Runs as the postgres owner (security definer): select on storage.objects.
-- ---------------------------------------------------------------------------
create or replace function public.photo_residue_run(p_batch int default 500)
returns jsonb language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_cutoff timestamptz := now() - interval '24 hours';
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
                 where q.request_id = v_req and q.deleted_at is null and q.status in ('processing', 'taking_long')) then
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

-- 00:45 KST daily, regardless of queue state (the 5-minute runner picks the rows up).
select public.cron_upsert('soongong-photo-residue', '45 15 * * *',
  $$select public.photo_residue_run();$$);

-- ---------------------------------------------------------------------------
-- 2. marks[] / items[] validation
-- ---------------------------------------------------------------------------
-- marks[]: every element is an object with integer page_index · number (0–999999),
-- mark ∈ enum; non-correct marks carry a uuid wrong_item_id; (page_index, number)
-- unique; wrong_item_id unique. Returns the detail code or null.
create or replace function public.reading_validate_marks(p_marks jsonb)
returns text language plpgsql immutable
set search_path = public, pg_temp
as $$
declare
  v_m jsonb;
  v_ids text[] := '{}';
begin
  if p_marks is null or jsonb_typeof(p_marks) <> 'array' then return 'marks_not_array'; end if;
  for v_m in select * from jsonb_array_elements(p_marks) loop
    if jsonb_typeof(v_m) <> 'object'
       or (v_m -> 'page_index')::text !~ '^\d{1,6}$'
       or (v_m -> 'number')::text !~ '^\d{1,6}$'
       or (v_m ->> 'mark') is null
       or (v_m ->> 'mark') not in ('correct', 'wrong', 'partial', 'unsolved', 'guessed') then
      return 'mark_invalid';
    end if;
    if (v_m ->> 'mark') <> 'correct' then
      if (v_m ->> 'wrong_item_id') is null
         or (v_m ->> 'wrong_item_id') !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
        return 'wrong_item_id_required';
      end if;
      v_ids := v_ids || (v_m ->> 'wrong_item_id');
    end if;
  end loop;
  if (select count(*) from jsonb_array_elements(p_marks) x) <>
     (select count(distinct (x ->> 'page_index') || ':' || (x ->> 'number')) from jsonb_array_elements(p_marks) x) then
    return 'mark_duplicate';
  end if;
  if cardinality(v_ids) <> cardinality(array(select distinct unnest(v_ids))) then
    return 'wrong_item_id_duplicate';
  end if;
  return null;
end $$;
revoke execute on function public.reading_validate_marks(jsonb) from public, anon, authenticated, service_role;

-- items[] (reading_save): every element is an object {id uuid, page_index, number,
-- mark, confidence?, user_confirmed?}; ids unique; and the set
-- {(id, page_index, number, mark)} equals the non-correct marks
-- {(wrong_item_id, page_index, number, mark)} exactly. Call after
-- reading_validate_marks has returned null.
create or replace function public.reading_validate_items(p_marks jsonb, p_items jsonb)
returns text language plpgsql immutable
set search_path = public, pg_temp
as $$
declare
  v_i jsonb;
  v_diff int;
  v_items int;
  v_marks int;
begin
  if p_items is null or jsonb_typeof(p_items) <> 'array' then return 'items_not_array'; end if;
  for v_i in select * from jsonb_array_elements(p_items) loop
    if jsonb_typeof(v_i) <> 'object'
       or (v_i ->> 'id') is null
       or (v_i ->> 'id') !~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
       or (v_i -> 'page_index')::text !~ '^\d{1,6}$'
       or (v_i -> 'number')::text !~ '^\d{1,6}$'
       or (v_i ->> 'mark') is null
       or (v_i ->> 'mark') not in ('correct', 'wrong', 'partial', 'unsolved', 'guessed')
       or (v_i ? 'confidence' and jsonb_typeof(v_i -> 'confidence') not in ('number', 'null'))
       or (v_i ? 'user_confirmed' and jsonb_typeof(v_i -> 'user_confirmed') not in ('boolean', 'null')) then
      return 'item_invalid';
    end if;
  end loop;
  select count(*), count(distinct x ->> 'id') into v_items, v_diff from jsonb_array_elements(p_items) x;
  if v_items <> v_diff then return 'item_id_duplicate'; end if;
  select count(*) into v_marks from jsonb_array_elements(p_marks) x where (x ->> 'mark') <> 'correct';
  select count(*) into v_diff from (
    (select x ->> 'wrong_item_id' as id, (x ->> 'page_index')::int as page_index, (x ->> 'number')::int as number, x ->> 'mark' as mark
       from jsonb_array_elements(p_marks) x where (x ->> 'mark') <> 'correct'
     except
     select x ->> 'id', (x ->> 'page_index')::int, (x ->> 'number')::int, x ->> 'mark'
       from jsonb_array_elements(p_items) x)
    union all
    (select x ->> 'id', (x ->> 'page_index')::int, (x ->> 'number')::int, x ->> 'mark'
       from jsonb_array_elements(p_items) x
     except
     select x ->> 'wrong_item_id', (x ->> 'page_index')::int, (x ->> 'number')::int, x ->> 'mark'
       from jsonb_array_elements(p_marks) x where (x ->> 'mark') <> 'correct')
  ) d;
  if v_diff > 0 or v_items <> v_marks then return 'marks_items_mismatch'; end if;
  return null;
end $$;
revoke execute on function public.reading_validate_items(jsonb, jsonb) from public, anon, authenticated, service_role;

-- reading_save: same contract as 0005 (done_unsaved → saved; already_saved ·
-- not_unsaved · not_found · request_deleted · id_reused), with the item set check.
-- Order: lock → state → validate marks → validate items → id_reused → writes.
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
  v_err := public.reading_validate_items(p_marks, p_items);
  if v_err is not null then
    return jsonb_build_object('outcome', 'invalid_payload', 'status_code', 400, 'detail', v_err);
  end if;
  select coalesce(array_agg(x ->> 'id'), '{}') into v_ids from jsonb_array_elements(p_items) x;
  if exists (select 1 from public.wrong_items where id = any (v_ids)) then
    return jsonb_build_object('outcome', 'id_reused', 'status_code', 409);
  end if;

  for it in select * from jsonb_array_elements(p_items) loop
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

-- reading_update_marks (0005) is unchanged in body: it calls reading_validate_marks
-- (now also rejecting duplicate wrong_item_id and non-integer page/number) and
-- performs every id / entry check in pass 1 before pass 2 writes anything.
