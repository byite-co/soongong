-- =============================================================================
-- S03 · 0003_sync_rpc.sql — D2 synchronisation: sync_push / sync_pull
--
-- Wire format (docs/sync-rpc.md):
--   sync_push(p_epoch int, rows jsonb)  rows = [{table, id, mutation_id,
--     base_server_version, purge_epoch, data}]  (≤ 500)
--   → {epoch, accepted:[{table,id,mutation_id,server_version,server_seq}],
--      rejected:[{table,id,mutation_id,reason,server_row?}]}
--     or {epoch, epoch_mismatch:true, accepted:[], rejected:[]}
--   sync_pull(p_epoch int, since_seq bigint, p_limit int)
--   → {epoch, rows:[{table,row}], next_seq, has_more,
--      ledger:{subscription_state, reading_quota}}  or {epoch_mismatch:true, epoch}
--
-- Row-level reasons: invalid_mutation · invalid_table · invalid_columns ·
--   insert_not_allowed · forbidden · version_conflict (+server_row) · deleted ·
--   constraint_violation. Function-level failures RAISE: not_authenticated ·
--   no_profile · batch_too_large.
--
-- JSON columns (settings.value_json, reading_requests.result_json/marks_json)
-- travel as JSON text strings (the client stores TEXT); a push may send either
-- the text or the JSON value.
-- =============================================================================

-- D2 common columns — never nulled on a tombstone.
create or replace function public.sync_common_columns()
returns text[] language sql immutable parallel safe
set search_path = public, pg_temp
as $$ select array['id','user_id','created_at','client_updated_at','deleted_at','device_id',
                   'purge_epoch','server_version','server_received_at','server_seq'] $$;
revoke execute on function public.sync_common_columns() from public, anon, authenticated, service_role;

-- Null every content column of a row JSON (tombstone representation).
create or replace function public.sync_null_content(p_table text, p_row jsonb)
returns jsonb language plpgsql stable security definer
set search_path = public, pg_temp
as $$
declare
  v_keep text[];
  v_col text;
  v_row jsonb := p_row;
begin
  select keep_keys into v_keep from public.sync_tables where table_name = p_table;
  for v_col in
    select column_name from information_schema.columns
    where table_schema = 'public' and table_name = p_table
      and column_name <> all (public.sync_common_columns())
      and column_name <> all (coalesce(v_keep, '{}'))
  loop
    v_row := jsonb_set(v_row, array[v_col], 'null'::jsonb, true);
  end loop;
  return v_row;
end $$;
revoke execute on function public.sync_null_content(text, jsonb) from public, anon, authenticated, service_role;

-- Row JSON for the wire: jsonb columns → JSON text, server_received_at dropped.
create or replace function public.sync_row_json(p_table text, p_row jsonb)
returns jsonb language plpgsql stable security definer
set search_path = public, pg_temp
as $$
declare
  v_col text;
  v_row jsonb := p_row - 'server_received_at';
begin
  for v_col in
    select column_name from information_schema.columns
    where table_schema = 'public' and table_name = p_table and data_type = 'jsonb'
  loop
    if v_row ? v_col and jsonb_typeof(v_row -> v_col) <> 'null' then
      v_row := jsonb_set(v_row, array[v_col], to_jsonb((v_row -> v_col)::text), true);
    end if;
  end loop;
  return v_row;
end $$;
revoke execute on function public.sync_row_json(text, jsonb) from public, anon, authenticated, service_role;

-- Write a full row JSON into p_table (insert or update by id).
create or replace function public.sync_write_row(p_table text, p_row jsonb, p_update boolean)
returns void language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_cols text;
  v_col text;
  v_row jsonb := p_row;
begin
  -- JSON columns sent as text → parse
  for v_col in
    select column_name from information_schema.columns
    where table_schema = 'public' and table_name = p_table and data_type = 'jsonb'
  loop
    if v_row ? v_col and jsonb_typeof(v_row -> v_col) = 'string' then
      v_row := jsonb_set(v_row, array[v_col], (v_row ->> v_col)::jsonb, true);
    end if;
  end loop;
  if p_update then
    select string_agg(quote_ident(column_name), ',' order by ordinal_position) into v_cols
    from information_schema.columns
    where table_schema = 'public' and table_name = p_table and column_name <> 'id';
    execute format(
      'update public.%I t set (%s) = (select %s from jsonb_populate_record(null::public.%I, $1)) where t.id = $2',
      p_table, v_cols, v_cols, p_table) using v_row, v_row ->> 'id';
  else
    execute format('insert into public.%I select * from jsonb_populate_record(null::public.%I, $1)',
      p_table, p_table) using v_row;
  end if;
end $$;
revoke execute on function public.sync_write_row(text, jsonb, boolean) from public, anon, authenticated, service_role;

-- Tombstone a live row by id with a new version/seq (server-initiated: cascade,
-- update-marks, orphan drafts). No-op when the row is missing or already deleted.
create or replace function public.sync_tombstone(p_table text, p_user uuid, p_id text, p_deleted_at text default null,
                                                 p_client_updated_at text default null, p_device_id text default null)
returns boolean language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_existing jsonb;
  v_row jsonb;
  v_now text := public.iso_utc(now());
begin
  execute format('select to_jsonb(t) from public.%I t where id = $1 and user_id = $2 and deleted_at is null', p_table)
    into v_existing using p_id, p_user;
  if v_existing is null then
    return false;
  end if;
  v_row := public.sync_null_content(p_table, v_existing)
        || jsonb_build_object(
             'deleted_at', coalesce(p_deleted_at, v_now),
             'client_updated_at', coalesce(p_client_updated_at, v_now),
             'device_id', coalesce(p_device_id, v_existing ->> 'device_id'),
             'server_version', (v_existing ->> 'server_version')::int + 1,
             'server_received_at', now(),
             'server_seq', public.next_server_seq(p_user));
  perform public.sync_write_row(p_table, v_row, true);
  return true;
end $$;
revoke execute on function public.sync_tombstone(text, uuid, text, text, text, text) from public, anon, authenticated, service_role;

-- D16 delete-only mutation on a saved request: parent + children tombstones in
-- one transaction (each child gets its own seq). Returns the parent's
-- {server_version, server_seq}.
create or replace function public.reading_tombstone_cascade(p_user uuid, p_request_id text, p_deleted_at text,
                                                            p_client_updated_at text, p_device_id text)
returns jsonb language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_id text;
  v_wrong_ids text[];
  v_out jsonb;
begin
  select coalesce(array_agg(id), '{}') into v_wrong_ids
  from public.wrong_items where user_id = p_user and request_id = p_request_id and deleted_at is null;

  perform public.sync_tombstone('reading_requests', p_user, p_request_id, p_deleted_at, p_client_updated_at, p_device_id);
  select jsonb_build_object('server_version', server_version, 'server_seq', server_seq) into v_out
  from public.reading_requests where user_id = p_user and request_id = p_request_id;

  foreach v_id in array v_wrong_ids loop
    perform public.sync_tombstone('wrong_items', p_user, v_id, p_deleted_at, p_client_updated_at, p_device_id);
  end loop;
  for v_id in
    select id from public.review_entries where user_id = p_user and deleted_at is null and wrong_item_id = any (v_wrong_ids)
  loop
    perform public.sync_tombstone('review_entries', p_user, v_id, p_deleted_at, p_client_updated_at, p_device_id);
  end loop;
  for v_id in
    select id from public.retry_records where user_id = p_user and deleted_at is null and wrong_item_id = any (v_wrong_ids)
  loop
    perform public.sync_tombstone('retry_records', p_user, v_id, p_deleted_at, p_client_updated_at, p_device_id);
  end loop;
  return v_out;
end $$;
revoke execute on function public.reading_tombstone_cascade(uuid, text, text, text, text) from public, anon, authenticated, service_role;

-- One row of sync_push (after receipt / table / column checks).
create or replace function public.sync_apply_row(p_user uuid, p_epoch int, p_table text, p_id text,
                                                 p_base int, p_data jsonb)
returns jsonb language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_spec public.sync_tables%rowtype;
  v_existing jsonb;
  v_row jsonb;
  v_deleting boolean := (p_data ? 'deleted_at') and jsonb_typeof(p_data -> 'deleted_at') <> 'null';
  v_seq bigint;
  v_version int;
  v_out jsonb;
  v_content_keys text[];
begin
  select * into v_spec from public.sync_tables where table_name = p_table;
  execute format('select to_jsonb(t) from public.%I t where id = $1', p_table) into v_existing using p_id;

  if v_existing is not null and (v_existing ->> 'user_id')::uuid <> p_user then
    return jsonb_build_object('ok', false, 'reason', 'forbidden');
  end if;

  -- reading_requests after submission: server-owned except the delete-only
  -- mutation of a `saved` request (D16 · D24 · S02 §7 ①, acceptance ①).
  if p_table = 'reading_requests' and v_existing is not null and v_existing ->> 'submitted_at' is not null then
    if v_deleting then
      select coalesce(array_agg(k), '{}') into v_content_keys
      from jsonb_object_keys(p_data) k
      where k <> all (array['deleted_at','created_at','client_updated_at','device_id','purge_epoch']);
      if cardinality(v_content_keys) > 0 then
        return jsonb_build_object('ok', false, 'reason', 'invalid_columns');
      end if;
      if v_existing ->> 'status' = 'saved' and p_base is not null and p_base = (v_existing ->> 'server_version')::int then
        v_out := public.reading_tombstone_cascade(p_user, p_id, p_data ->> 'deleted_at',
                                                  p_data ->> 'client_updated_at', p_data ->> 'device_id');
        return jsonb_build_object('ok', true, 'server_version', v_out -> 'server_version', 'server_seq', v_out -> 'server_seq');
      end if;
    end if;
    return jsonb_build_object('ok', false, 'reason', 'version_conflict',
                              'server_row', public.sync_row_json(p_table, v_existing));
  end if;

  if v_existing is null then
    if not v_spec.client_insert then
      return jsonb_build_object('ok', false, 'reason', 'insert_not_allowed');
    end if;
    v_seq := public.next_server_seq(p_user);
    v_row := p_data || jsonb_build_object(
      'id', p_id, 'user_id', p_user, 'server_version', 1, 'server_received_at', now(),
      'server_seq', v_seq, 'purge_epoch', p_epoch);
    if p_table = 'reading_requests' and not v_deleting then
      v_row := v_row || jsonb_build_object('status', 'selecting', 'quota_charged', false);
    end if;
    if v_deleting then
      v_row := public.sync_null_content(p_table, v_row);
    end if;
    perform public.sync_write_row(p_table, v_row, false);
    return jsonb_build_object('ok', true, 'server_version', 1, 'server_seq', v_seq);
  end if;

  if v_existing ->> 'deleted_at' is not null then
    return jsonb_build_object('ok', false, 'reason', 'deleted');
  end if;
  if p_base is null or p_base <> (v_existing ->> 'server_version')::int then
    return jsonb_build_object('ok', false, 'reason', 'version_conflict',
                              'server_row', public.sync_row_json(p_table, v_existing));
  end if;

  v_seq := public.next_server_seq(p_user);
  v_version := (v_existing ->> 'server_version')::int + 1;
  v_row := v_existing || p_data || jsonb_build_object(
    'id', p_id, 'user_id', p_user, 'server_version', v_version, 'server_received_at', now(),
    'server_seq', v_seq, 'purge_epoch', p_epoch);
  if v_deleting then
    v_row := public.sync_null_content(p_table, v_row);
  end if;
  perform public.sync_write_row(p_table, v_row, true);
  return jsonb_build_object('ok', true, 'server_version', v_version, 'server_seq', v_seq);
end $$;
revoke execute on function public.sync_apply_row(uuid, int, text, text, int, jsonb) from public, anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- sync_push (authenticated RPC)
-- ---------------------------------------------------------------------------
create or replace function public.sync_push(p_epoch int, rows jsonb)
returns jsonb language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_epoch int;
  v_accepted jsonb := '[]'::jsonb;
  v_rejected jsonb := '[]'::jsonb;
  r jsonb;
  v_table text;
  v_id text;
  v_mut uuid;
  v_base int;
  v_data jsonb;
  v_receipt public.sync_mutations%rowtype;
  v_bad text[];
  v_res jsonb;
begin
  if v_user is null then
    raise exception 'not_authenticated' using errcode = 'P0001';
  end if;
  perform public.user_lock(v_user);
  select purge_epoch into v_epoch from public.profiles where user_id = v_user;
  if not found then
    raise exception 'no_profile' using errcode = 'P0001';
  end if;
  if rows is null or jsonb_typeof(rows) <> 'array' then
    raise exception 'invalid_rows' using errcode = 'P0001';
  end if;
  if jsonb_array_length(rows) > 500 then
    raise exception 'batch_too_large' using errcode = 'P0001';
  end if;
  if p_epoch is distinct from v_epoch then
    return jsonb_build_object('epoch', v_epoch, 'epoch_mismatch', true, 'accepted', v_accepted, 'rejected', v_rejected);
  end if;

  for r in select * from jsonb_array_elements(rows) loop
    v_table := r ->> 'table';
    v_id := r ->> 'id';
    v_data := r -> 'data';
    begin
      v_mut := (r ->> 'mutation_id')::uuid;
      v_base := (r ->> 'base_server_version')::int;
    exception when others then
      v_mut := null;
    end;
    if v_mut is null or v_id is null then
      v_rejected := v_rejected || jsonb_build_object('table', v_table, 'id', v_id, 'mutation_id', r -> 'mutation_id',
                                                     'reason', 'invalid_mutation');
      continue;
    end if;

    -- 1. receipt → replay
    select * into v_receipt from public.sync_mutations where user_id = v_user and mutation_id = v_mut;
    if found then
      v_accepted := v_accepted || jsonb_build_object('table', v_receipt.table_name, 'id', v_receipt.row_id,
        'mutation_id', v_mut, 'server_version', v_receipt.server_version, 'server_seq', v_receipt.server_seq);
      continue;
    end if;

    -- 2. table / columns
    if not exists (select 1 from public.sync_tables where table_name = v_table) then
      v_rejected := v_rejected || jsonb_build_object('table', v_table, 'id', v_id, 'mutation_id', v_mut, 'reason', 'invalid_table');
      continue;
    end if;
    if v_data is null or jsonb_typeof(v_data) <> 'object' then
      v_rejected := v_rejected || jsonb_build_object('table', v_table, 'id', v_id, 'mutation_id', v_mut, 'reason', 'invalid_columns');
      continue;
    end if;
    select coalesce(array_agg(k), '{}') into v_bad
    from jsonb_object_keys(v_data) k
    where not exists (select 1 from public.allowed_columns a where a.table_name = v_table and a.column_name = k);
    if cardinality(v_bad) > 0 then
      v_rejected := v_rejected || jsonb_build_object('table', v_table, 'id', v_id, 'mutation_id', v_mut, 'reason', 'invalid_columns');
      continue;
    end if;

    -- 3. apply (sub-transaction so one bad row does not abort the batch)
    begin
      v_res := public.sync_apply_row(v_user, v_epoch, v_table, v_id, v_base, v_data);
    exception
      when check_violation or not_null_violation or unique_violation or invalid_text_representation
        or string_data_right_truncation or numeric_value_out_of_range or datetime_field_overflow
        or invalid_datetime_format then
        v_res := jsonb_build_object('ok', false, 'reason', 'constraint_violation');
    end;

    if (v_res ->> 'ok')::boolean then
      insert into public.sync_mutations (user_id, mutation_id, table_name, row_id, server_version, server_seq, result)
      values (v_user, v_mut, v_table, v_id, (v_res ->> 'server_version')::int, (v_res ->> 'server_seq')::bigint, 'accepted');
      v_accepted := v_accepted || jsonb_build_object('table', v_table, 'id', v_id, 'mutation_id', v_mut,
        'server_version', v_res -> 'server_version', 'server_seq', v_res -> 'server_seq');
    else
      v_rejected := v_rejected || (jsonb_build_object('table', v_table, 'id', v_id, 'mutation_id', v_mut,
        'reason', v_res -> 'reason') || coalesce(jsonb_strip_nulls(jsonb_build_object('server_row', v_res -> 'server_row')), '{}'::jsonb));
    end if;
  end loop;

  return jsonb_build_object('epoch', v_epoch, 'accepted', v_accepted, 'rejected', v_rejected);
end $$;
revoke execute on function public.sync_push(int, jsonb) from public, anon, authenticated, service_role;
grant execute on function public.sync_push(int, jsonb) to authenticated;

-- ---------------------------------------------------------------------------
-- ledger (D18 decision table; identical to the app's S12 table)
-- ---------------------------------------------------------------------------
create or replace function public.entitlement_status(p_user uuid)
returns table (status text, entitled boolean)
language plpgsql stable security definer
set search_path = public, pg_temp
as $$
declare
  s public.subscription_state%rowtype;
  v_now timestamptz := now();
begin
  select * into s from public.subscription_state where user_id = p_user;
  if not found then
    return query select 'free'::text, false; return;
  end if;
  if s.expires_at is not null and s.expires_at > v_now then
    if s.will_renew and s.period_type = 'TRIAL' then
      return query select 'trial'::text, true; return;
    elsif s.will_renew then
      return query select 'premium'::text, true; return;
    else
      return query select 'cancelPending'::text, true; return;
    end if;
  end if;
  if s.grace_expires_at is not null and s.grace_expires_at > v_now then
    return query select 'grace'::text, true; return;
  end if;
  if s.has_history then
    return query select 'expired'::text, false; return;
  end if;
  return query select 'free'::text, false;
end $$;
revoke execute on function public.entitlement_status(uuid) from public, anon, authenticated;
grant execute on function public.entitlement_status(uuid) to service_role;

create or replace function public.ledger_json(p_user uuid)
returns jsonb language plpgsql stable security definer
set search_path = public, pg_temp
as $$
declare
  s public.subscription_state%rowtype;
  e record;
  q public.reading_quota%rowtype;
  v_month text := public.kst_month(now());
  v_sub jsonb;
  v_quota jsonb;
begin
  select * into e from public.entitlement_status(p_user);
  select * into s from public.subscription_state where user_id = p_user;
  v_sub := jsonb_build_object(
    'status', e.status, 'entitled', e.entitled,
    'expires_at', case when s.expires_at is null then null else public.iso_utc(s.expires_at) end,
    'grace_expires_at', case when s.grace_expires_at is null then null else public.iso_utc(s.grace_expires_at) end,
    'period_type', s.period_type,
    'will_renew', coalesce(s.will_renew, false),
    'trial_used', coalesce(s.trial_used, false));
  select * into q from public.reading_quota where user_id = p_user and month = v_month;
  v_quota := jsonb_build_object('month', v_month, 'used', coalesce(q.used, 0), 'reserved', coalesce(q.reserved, 0),
                                'limit', coalesce(q.quota_limit, 20));
  return jsonb_build_object('subscription_state', v_sub, 'reading_quota', v_quota);
end $$;
revoke execute on function public.ledger_json(uuid) from public, anon, authenticated;
grant execute on function public.ledger_json(uuid) to service_role;

-- ---------------------------------------------------------------------------
-- sync_pull (authenticated RPC)
-- ---------------------------------------------------------------------------
create or replace function public.sync_pull(p_epoch int, since_seq bigint, p_limit int default 1000)
returns jsonb language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_epoch int;
  v_limit int := greatest(1, least(coalesce(p_limit, 1000), 1000));
  v_sql text;
  v_rows jsonb := '[]'::jsonb;
  v_count int := 0;
  v_next bigint := coalesce(since_seq, 0);
  v_has_more boolean := false;
  rec record;
begin
  if v_user is null then
    raise exception 'not_authenticated' using errcode = 'P0001';
  end if;
  select purge_epoch into v_epoch from public.profiles where user_id = v_user;
  if not found then
    raise exception 'no_profile' using errcode = 'P0001';
  end if;
  if p_epoch is distinct from v_epoch then
    return jsonb_build_object('epoch_mismatch', true, 'epoch', v_epoch);
  end if;

  select string_agg(format('select server_seq, %L as table_name, to_jsonb(t) as row from public.%I t where user_id = $1 and server_seq > $2',
                           table_name, table_name), ' union all ')
    into v_sql
  from public.sync_tables;
  v_sql := 'select * from (' || v_sql || ') u order by server_seq limit $3';

  for rec in execute v_sql using v_user, coalesce(since_seq, 0), v_limit + 1 loop
    v_count := v_count + 1;
    if v_count > v_limit then
      v_has_more := true;
      exit;
    end if;
    v_rows := v_rows || jsonb_build_object('table', rec.table_name, 'row', public.sync_row_json(rec.table_name, rec.row));
    v_next := rec.server_seq;
  end loop;

  return jsonb_build_object('epoch', v_epoch, 'rows', v_rows, 'next_seq', v_next, 'has_more', v_has_more,
                            'ledger', public.ledger_json(v_user));
end $$;
revoke execute on function public.sync_pull(int, bigint, int) from public, anon, authenticated, service_role;
grant execute on function public.sync_pull(int, bigint, int) to authenticated;
