-- NEXT-02: cost-only reading execution. No AI point lot/grant/allocation.
create table public.reading_ai_policies (
 id uuid primary key default gen_random_uuid(), enabled boolean not null default false,
 provider text not null check(provider='local'), model text not null check(length(model) between 1 and 200),
 fixed_price numeric(20,10) not null check(fixed_price>=0), currency text not null check(currency ~ '^[A-Z]{3}$'),
 krw_per_currency numeric(20,10) not null check(krw_per_currency>0), price_version text not null, fx_version text not null,
 fx_at timestamptz not null
);
create unique index reading_ai_one_policy on public.reading_ai_policies(enabled) where enabled;
create trigger reading_ai_policy_immutable before update on public.reading_ai_policies for each row execute function public.ai_policy_immutable();
create table public.reading_ai_costs (
 id uuid primary key default gen_random_uuid(), user_id uuid references public.profiles(user_id) on delete set null,
 request_id text, attempt integer not null check(attempt>0), policy_id uuid not null references public.reading_ai_policies,
 attempt_id uuid not null unique default gen_random_uuid(), month date not null references public.ai_budgets,
 pages integer not null check(pages between 1 and 20), provider text not null, model text not null,
 price_version text not null, currency text not null, fx_version text not null, fx_at timestamptz not null,
 krw_per_currency numeric(20,10) not null, ceiling_krw numeric(20,8) not null check(ceiling_krw>=0),
 status text not null default 'unknown' check(status in ('unknown','settled')),
 actual_currency numeric(20,10), actual_krw numeric(20,8), usage jsonb, settlement_id uuid unique,
 settled_at timestamptz, unique(user_id,request_id)
);
alter table public.reading_ai_policies enable row level security;
alter table public.reading_ai_costs enable row level security;
revoke all on public.reading_ai_policies,public.reading_ai_costs from public,anon,authenticated;
grant all on public.reading_ai_policies,public.reading_ai_costs to service_role;

create function public.reading_ai_detach() returns trigger language plpgsql set search_path='' as $$
begin if new.user_id is null then new.request_id:=null; end if; return new; end $$;
create trigger reading_ai_detach before update of user_id on public.reading_ai_costs for each row execute function public.reading_ai_detach();

create function public.reading_ai_begin(p_user uuid,p_request text,p_attempt integer) returns jsonb
language plpgsql security definer set search_path='' as $$
declare j public.reading_jobs; r public.reading_requests; p public.reading_ai_policies; c public.reading_ai_costs;
 b public.ai_budgets; amount numeric(20,8); mon date; n integer;
begin
 perform public.user_lock(p_user);
 select * into r from public.reading_requests where user_id=p_user and request_id=p_request and deleted_at is null;
 if not found or r.status not in ('processing','taking_long') then raise exception 'reading_unavailable'; end if;
 perform public.ai_profile(p_user,r.purge_epoch);
 perform public.ai_lock();
 select * into j from public.reading_jobs where user_id=p_user and request_id=p_request for update;
 if not found or j.attempts is distinct from p_attempt or j.lease_until is null or j.lease_until<=now() or j.deadline<=now() then raise exception 'stale_attempt'; end if;
 select * into c from public.reading_ai_costs where user_id=p_user and request_id=p_request;
 if found then return jsonb_build_object('claimed',false,'cost_id',c.id); end if;
 select * into p from public.reading_ai_policies where enabled;
 if not found then raise exception 'policy_unavailable'; end if;
 n:=cardinality(j.object_paths);
 if n is null or n not between 1 and 20 then raise exception 'invalid_payload'; end if;
 amount:=ceil(n*p.fixed_price*p.krw_per_currency*100000000)/100000000;
 mon:=date_trunc('month',public.study_now() at time zone 'Asia/Seoul')::date;
 select * into b from public.ai_budgets where month=mon for update;
 if not found then raise exception 'budget_unavailable'; end if;
 if b.spent_krw+b.reserved_krw+b.infrastructure_krw+amount>b.limit_krw then raise exception 'budget_exceeded'; end if;
 insert into public.reading_ai_costs(user_id,request_id,attempt,policy_id,month,pages,provider,model,price_version,currency,fx_version,fx_at,krw_per_currency,ceiling_krw)
 values(p_user,p_request,p_attempt,p.id,mon,n,p.provider,p.model,p.price_version,p.currency,p.fx_version,p.fx_at,p.krw_per_currency,amount) returning * into c;
 update public.ai_budgets set reserved_krw=reserved_krw+amount where month=mon;
 return jsonb_build_object('claimed',true,'cost_id',c.id,'attempt_id',c.attempt_id,'provider',c.provider,'model',c.model,'epoch',r.purge_epoch);
end $$;

-- SQL independently validates the versioned reading result before charging quota.
create function public.reading_valid_result(v jsonb,n integer) returns boolean language plpgsql set search_path='' as $$
declare p jsonb; i jsonb; seen text[]:='{}'; key text; b jsonb; x jsonb;
begin
 if v is null or jsonb_typeof(v) is distinct from 'object' or v->'schema_version' is distinct from '2'::jsonb or jsonb_typeof(v->'pages') is distinct from 'array'
 or jsonb_array_length(v->'pages')<>n or n not between 1 and 20 then return false; end if;
 for p in select value from jsonb_array_elements(v->'pages') loop
  if jsonb_typeof(p->'index') is distinct from 'number' or (p->>'index') !~ '^[0-9]+$' or (p->>'index')::numeric>=n
  or jsonb_typeof(p->'items') is distinct from 'array' or jsonb_array_length(p->'items')>500 then return false; end if;
  key:='page:'||(p->>'index'); if key=any(seen) then return false; end if; seen:=array_append(seen,key);
  for i in select value from jsonb_array_elements(p->'items') loop
   if jsonb_typeof(i->'number') is distinct from 'number' or (i->>'number') !~ '^[0-9]+$' or (i->>'number')::numeric>999999
   or not (i ?& array['number','mark','confidence','box','needs_review'])
   or (i->'mark'<>'null'::jsonb and i->>'mark' not in ('correct','wrong','partial','unsolved','guessed'))
   or i->'needs_review' is distinct from 'true'::jsonb then return false; end if;
   key:=(p->>'index')||':'||(i->>'number'); if key=any(seen) then return false; end if; seen:=array_append(seen,key);
   if i->'confidence'<>'null'::jsonb and (jsonb_typeof(i->'confidence')<>'number' or (i->>'confidence')::numeric not between 0 and 1) then return false; end if;
   b:=i->'box'; if jsonb_typeof(b)<>'array' or jsonb_array_length(b)<>4 then return false; end if;
   for x in select value from jsonb_array_elements(b) loop
    if jsonb_typeof(x)<>'number' or x::text::numeric not between 0 and 1 then return false; end if;
   end loop;
   if (b->>0)::numeric>(b->>2)::numeric or (b->>1)::numeric>(b->>3)::numeric then return false; end if;
  end loop;
 end loop;
 return true;
exception when others then return false;
end $$;

create function public.reading_finish_attempt(p_user uuid,p_request_id text,p_attempt integer,p_outcome text,p_result jsonb default null,p_fail_reason text default null)
returns jsonb language plpgsql security definer set search_path='' as $$
declare j public.reading_jobs; r public.reading_requests;
begin
 perform public.user_lock(p_user);
 select * into j from public.reading_jobs where user_id=p_user and request_id=p_request_id for update;
 if not found or j.attempts is distinct from p_attempt or j.lease_until is null or j.lease_until<=now() or j.deadline<=now() then
  return jsonb_build_object('outcome','noop','reason','stale_attempt');
 end if;
 select * into r from public.reading_requests where user_id=p_user and request_id=p_request_id;
 if p_outcome='done' then
  perform public.ai_profile(p_user,r.purge_epoch);
  if not public.reading_valid_result(p_result,cardinality(j.object_paths)) then raise exception 'invalid_engine_result'; end if;
 end if;
 return public.reading_finish(p_user,p_request_id,p_outcome,p_result,p_fail_reason);
end $$;

create function public.ai_valid_usage(v jsonb) returns boolean language plpgsql immutable set search_path='' as $$
begin
 if v is null or jsonb_typeof(v)<>'object' or octet_length(v::text)>2000 then return false; end if;
 return not exists(select from jsonb_object_keys(v) k where k not in ('input_tokens','output_tokens','cached_tokens','reasoning_tokens','requests','images','pages','crops','elapsed_ms'))
 and not exists(select from jsonb_each(v) x where jsonb_typeof(x.value)<>'number' or x.value::text !~ '^[0-9]+$');
end $$;

create function public.reading_ai_reconcile(p_cost uuid,p_settlement uuid,p_actual numeric,p_usage jsonb) returns void
language plpgsql security definer set search_path='' as $$
declare c public.reading_ai_costs; amount numeric(20,8);
begin
 perform public.ai_lock(); select * into c from public.reading_ai_costs where id=p_cost for update;
 if not found then raise exception 'cost_unavailable'; end if;
 if p_settlement is null or p_actual is null or p_actual<0 or p_actual::text in ('NaN','Infinity','-Infinity') or p_actual<>trunc(p_actual,10)
 or not public.ai_valid_usage(p_usage) then raise exception 'invalid_cost'; end if;
 if c.status='settled' then
  if c.settlement_id<>p_settlement or c.actual_currency<>p_actual or c.usage<>p_usage then raise exception 'settlement_conflict'; end if;
  return;
 end if;
 amount:=ceil(p_actual*c.krw_per_currency*100000000)/100000000;
 update public.ai_budgets set reserved_krw=reserved_krw-c.ceiling_krw,spent_krw=spent_krw+amount where month=c.month;
 update public.reading_ai_costs set status='settled',actual_currency=p_actual,actual_krw=amount,usage=p_usage,settlement_id=p_settlement,settled_at=public.study_now() where id=p_cost;
end $$;

-- A verified local worker receipt proves external API cost only. Infrastructure
-- remains the independent monthly allocation; never fabricate external tokens.
create function public.ai_local_evidence(p_job uuid,p_attempt uuid,p_provider text,p_model text,p_usage jsonb) returns void
language plpgsql security definer set search_path='' as $$
declare c public.ai_costs; p public.ai_policies;
begin
 perform public.ai_lock(); select * into c from public.ai_costs where job_id=p_job for update;
 if not found or c.attempt_id<>p_attempt or c.provider<>p_provider or c.model<>p_model or p_provider<>'local'
 or not public.ai_valid_usage(p_usage) or p_usage->>'requests' is distinct from '1' or p_usage->>'images' is distinct from '1' then raise exception 'invalid_usage_evidence'; end if;
 select q.* into p from public.ai_policies q join public.ai_jobs j on j.policy_id=q.id where j.id=p_job;
 if p.fixed_price<>0 or p.input_price<>0 or p.output_price<>0 then return; end if;
 -- Existing reconcile is kept for its exact amount/idempotency rules. The
 -- external API receipt uses requests only; detailed units have their own row.
 perform public.ai_reconcile(p_job,p_attempt,0,jsonb_build_object('requests',1));
end $$;

create table public.ai_execution_usage (
 attempt_id uuid primary key, job_id uuid, reading_cost_id uuid,
 provider text not null, model text not null, usage jsonb not null, received_at timestamptz not null default now(),
 check ((job_id is null)<>(reading_cost_id is null)),check(public.ai_valid_usage(usage))
);
alter table public.ai_execution_usage enable row level security;
revoke all on public.ai_execution_usage from public,anon,authenticated;
grant all on public.ai_execution_usage to service_role;
create function public.ai_record_evidence(p_job uuid,p_reading_cost uuid,p_attempt uuid,p_provider text,p_model text,p_usage jsonb) returns void
language plpgsql security definer set search_path='' as $$
declare c public.reading_ai_costs; p public.reading_ai_policies; e public.ai_execution_usage;
begin
 perform public.ai_lock();
 if (p_job is null)=(p_reading_cost is null) or not public.ai_valid_usage(p_usage) then raise exception 'invalid_usage_evidence'; end if;
 select * into e from public.ai_execution_usage where attempt_id=p_attempt;
 if found then
  if e.job_id is distinct from p_job or e.reading_cost_id is distinct from p_reading_cost or e.provider<>p_provider or e.model<>p_model or e.usage<>p_usage then raise exception 'settlement_conflict'; end if;
  return;
 end if;
 if p_job is not null then perform public.ai_local_evidence(p_job,p_attempt,p_provider,p_model,p_usage);
 else
  select * into c from public.reading_ai_costs where id=p_reading_cost for update;
  if not found or c.attempt_id<>p_attempt or c.provider<>p_provider or c.model<>p_model or p_provider<>'local'
  or p_usage->>'images' is distinct from c.pages::text or p_usage->>'pages' is distinct from c.pages::text or p_usage->>'requests' is distinct from c.pages::text then raise exception 'invalid_usage_evidence'; end if;
  select * into p from public.reading_ai_policies where id=c.policy_id;
  if p.fixed_price=0 then perform public.reading_ai_reconcile(c.id,p_attempt,0,p_usage); end if;
 end if;
 insert into public.ai_execution_usage(attempt_id,job_id,reading_cost_id,provider,model,usage)
 values(p_attempt,p_job,p_reading_cost,p_provider,p_model,p_usage);
end $$;

create function public.reading_quota_snapshot(p_user uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare mon text:=to_char(now() at time zone 'Asia/Seoul','YYYY-MM');
begin
 perform public.user_lock(p_user);
 if not exists(select from public.profiles where user_id=p_user) then raise exception 'no_profile'; end if;
 return public.quota_json(p_user,mon);
end $$;

revoke execute on function public.reading_ai_detach(),public.reading_valid_result(jsonb,integer),public.ai_valid_usage(jsonb) from public,anon,authenticated,service_role;
revoke execute on function public.reading_ai_begin(uuid,text,integer),public.reading_finish_attempt(uuid,text,integer,text,jsonb,text),
 public.reading_ai_reconcile(uuid,uuid,numeric,jsonb),public.ai_local_evidence(uuid,uuid,text,text,jsonb),
 public.ai_record_evidence(uuid,uuid,uuid,text,text,jsonb),public.reading_quota_snapshot(uuid) from public,anon,authenticated;
grant execute on function public.reading_ai_begin(uuid,text,integer),public.reading_finish_attempt(uuid,text,integer,text,jsonb,text),
 public.reading_ai_reconcile(uuid,uuid,numeric,jsonb),public.ai_local_evidence(uuid,uuid,text,text,jsonb),
 public.ai_record_evidence(uuid,uuid,uuid,text,text,jsonb),public.reading_quota_snapshot(uuid) to service_role;

-- Missing confidence stays missing, including after manual mark edits.
alter table public.wrong_items drop constraint wrong_items_tombstone;
alter table public.wrong_items add constraint wrong_items_tombstone check(deleted_at is not null or
 (subject_id is not null and range_text is not null and page_index is not null and number is not null
  and mark is not null and user_confirmed is not null and status is not null));
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
      (it ->> 'confidence')::real, coalesce((it ->> 'user_confirmed')::boolean, false), 'open');
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
        p_request_id, r.subject_id, r.range_text, (m ->> 'page_index')::int, (m ->> 'number')::int, m ->> 'mark', null, true, 'open');
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
