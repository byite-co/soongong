-- NEXT-01: new, isolated contracts. Never add bodies/jobs to D2 sync_tables.
-- All account operations: user_lock -> global AI lock -> row locks.
create table public.study_documents (
 user_id uuid not null references public.profiles(user_id) on delete cascade,
 id uuid not null, purge_epoch integer not null, revision integer not null check(revision>0),
 kind text not null check(kind in ('text','math')), title text check(length(title)<=80),
 created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
 deleted_at timestamptz, server_seq bigint not null,
 primary key(user_id,id), check(deleted_at is not null or title is not null)
);
create index study_documents_cursor on public.study_documents(user_id,server_seq);
create table public.study_bodies (
 user_id uuid not null, document_id uuid not null, revision integer not null,
 confirmed_text text not null check(length(btrim(confirmed_text)) between 1 and 20000),
 transcription jsonb not null, solution jsonb,
 primary key(user_id,document_id),
 foreign key(user_id,document_id) references public.study_documents(user_id,id) on delete cascade
);
create table public.study_photo_assets (
 id uuid primary key, user_id uuid not null, document_id uuid not null,
 object_path text not null unique,
 first_stored_at timestamptz not null, expires_at timestamptz not null,
 delete_requested boolean not null default false,
 foreign key(user_id,document_id) references public.study_documents(user_id,id) on delete cascade,
 check(expires_at=first_stored_at+interval '30 days')
);
create index study_photo_document on public.study_photo_assets(user_id,document_id);
create index study_photo_expiry on public.study_photo_assets(expires_at) where not delete_requested;
-- No owner/content/FK: obligation survives deletion of the user/document/asset.
create table public.study_object_deletions (
 id uuid primary key default gen_random_uuid(), object_path text not null unique,
 status text not null default 'pending' check(status in ('pending','done')),
 attempts integer not null default 0, next_at timestamptz not null default now(), completed_at timestamptz
);
create index study_object_due on public.study_object_deletions(next_at) where status='pending';
insert into storage.buckets(id,name,public) values('study-restore','study-restore',false) on conflict(id) do nothing;

create function public.study_now() returns timestamptz language sql volatile
set search_path='' as $$ select clock_timestamp() $$;

create function public.study_require_user(p_epoch integer) returns uuid language plpgsql security definer
set search_path='' as $$
declare u uuid:=auth.uid(); e integer;
begin
 if u is null then raise exception 'unauthorized'; end if;
 perform public.user_lock(u);
 select purge_epoch into e from public.profiles where user_id=u;
 if not found then raise exception 'no_profile'; end if;
 if e is distinct from p_epoch then raise exception 'stale_epoch'; end if;
 return u;
end $$;

create function public.study_valid_transcription(p jsonb,p_kind text) returns boolean language plpgsql immutable
set search_path='' as $$
declare b jsonb; total integer:=0; x numeric; a numeric[];
begin
 if (p is null or jsonb_typeof(p)<>'object' or octet_length(p::text)>256000
 or (select array_agg(k order by k) from jsonb_object_keys(p) k)<>array['blocks','engine','kind','schema_version']
 or p->'schema_version'<>'1'::jsonb or p->>'kind'<>p_kind or jsonb_typeof(p->'engine')<>'string'
 or length(p->>'engine') not between 1 and 200 or jsonb_typeof(p->'blocks')<>'array'
 or jsonb_array_length(p->'blocks')>500) is not false then return false; end if;
 for b in select value from jsonb_array_elements(p->'blocks') loop
  if (jsonb_typeof(b)<>'object' or (select array_agg(k order by k) from jsonb_object_keys(b) k)<>array['box','confidence','text']
  or jsonb_typeof(b->'text')<>'string' or length(b->>'text')>20000
  or jsonb_typeof(b->'box')<>'array' or jsonb_array_length(b->'box')<>4) is not false then return false; end if;
  total:=total+length(b->>'text')+1; a:='{}';
  for x in select value::text::numeric from jsonb_array_elements(b->'box') loop
   if x<0 or x>1 then return false; end if; a:=array_append(a,x);
  end loop;
  if a[1]>a[3] or a[2]>a[4] then return false; end if;
  if b->'confidence'<>'null'::jsonb and (jsonb_typeof(b->'confidence')<>'number' or (b->>'confidence')::numeric not between 0 and 1) then return false; end if;
 end loop;
 return total<=20000;
exception when others then return false;
end $$;
create function public.study_valid_solution(p jsonb,p_id uuid,p_rev integer) returns boolean language sql immutable
set search_path='' as $$
 select coalesce(jsonb_typeof(p)='object' and octet_length(p::text)<=256000
 and (select array_agg(k order by k) from jsonb_object_keys(p) k)=array['answer','document_id','explanation','model','reference_provided','revision','schema_version','verification']
 and p->'schema_version'='1'::jsonb and p->>'document_id'=p_id::text and p->'revision'=to_jsonb(p_rev)
 and jsonb_typeof(p->'answer')='string' and length(p->>'answer')<=200
 and jsonb_typeof(p->'explanation')='string' and length(p->>'explanation')<=16000
 and jsonb_typeof(p->'model')='string' and length(p->>'model') between 1 and 200
 and jsonb_typeof(p->'reference_provided')='boolean'
 and p->>'verification' in ('verified','contradicted','inconclusive','unsupported')
 and (p->>'verification'<>'verified' or p->'reference_provided'='true'::jsonb),false)
$$;

create function public.study_save_v1(p_epoch integer,p_id uuid,p_expected_revision integer,p_kind text,p_title text,p_text text,p_transcription jsonb)
returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=public.study_require_user(p_epoch); d public.study_documents; r integer;
begin
 if p_id is null or p_kind not in ('text','math') or p_kind is null or p_title is null or length(p_title)>80
 or p_text is null or length(btrim(p_text)) not between 1 and 20000 or not public.study_valid_transcription(p_transcription,p_kind)
 then raise exception 'invalid_payload'; end if;
 select * into d from public.study_documents where user_id=u and id=p_id;
 if found then
  if d.deleted_at is not null then raise exception 'document_deleted'; end if;
  if d.revision is distinct from p_expected_revision then raise exception 'revision_conflict'; end if;
  r:=d.revision+1;
  update public.study_documents set revision=r,title=p_title,kind=p_kind,updated_at=public.study_now(),server_seq=public.next_server_seq(u) where user_id=u and id=p_id;
 else
  if p_expected_revision is not null then raise exception 'revision_conflict'; end if;
  r:=1;
  insert into public.study_documents(user_id,id,purge_epoch,revision,kind,title,server_seq)
  values(u,p_id,p_epoch,r,p_kind,p_title,public.next_server_seq(u));
 end if;
 insert into public.study_bodies values(u,p_id,r,p_text,p_transcription,null)
 on conflict(user_id,document_id) do update set revision=r,confirmed_text=p_text,transcription=p_transcription,solution=null;
 return jsonb_build_object('version',1,'id',p_id,'revision',r);
end $$;

create function public.study_solution_v1(p_epoch integer,p_id uuid,p_revision integer,p_solution jsonb)
returns void language plpgsql security definer set search_path='' as $$
declare u uuid:=public.study_require_user(p_epoch);
begin
 if not coalesce(public.study_valid_solution(p_solution,p_id,p_revision),false) then raise exception 'invalid_payload'; end if;
 if not exists(select from public.study_documents where user_id=u and id=p_id and revision=p_revision and deleted_at is null)
 then raise exception 'revision_conflict'; end if;
 update public.study_bodies set solution=p_solution where user_id=u and document_id=p_id and revision=p_revision;
 if not found then raise exception 'body_missing'; end if;
 update public.study_documents set updated_at=public.study_now(),server_seq=public.next_server_seq(u) where user_id=u and id=p_id;
end $$;

create function public.study_metadata_v1(p_epoch integer,p_since bigint default 0,p_limit integer default 100)
returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=public.study_require_user(p_epoch); rows jsonb; cursor bigint;
begin
 if p_since is null or p_since<0 or p_limit is null or p_limit not between 1 and 100 then raise exception 'invalid_payload'; end if;
 select coalesce(jsonb_agg(to_jsonb(v) order by v.server_seq),'[]'),coalesce(max(v.server_seq),p_since) into rows,cursor from (
  select d.id,d.purge_epoch,d.revision,d.kind,d.title,d.created_at,d.updated_at,d.deleted_at,d.server_seq,
   exists(select from public.study_bodies b where b.user_id=u and b.document_id=d.id) as has_body,
   exists(select from public.study_bodies b where b.user_id=u and b.document_id=d.id and b.solution is not null) as has_solution,
   exists(select from public.study_photo_assets a where a.user_id=u and a.document_id=d.id and not a.delete_requested and a.expires_at>public.study_now()) as has_photo
  from public.study_documents d where d.user_id=u and d.server_seq>p_since order by d.server_seq limit p_limit
 ) v;
 return jsonb_build_object('version',1,'purge_epoch',p_epoch,'rows',rows,'next_seq',cursor);
end $$;

create function public.study_body_v1(p_epoch integer,p_id uuid,p_revision integer)
returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=public.study_require_user(p_epoch); b public.study_bodies;
begin
 select b1.* into b from public.study_bodies b1 join public.study_documents d on d.user_id=b1.user_id and d.id=b1.document_id
 where d.user_id=u and d.id=p_id and d.deleted_at is null and d.revision=p_revision and b1.revision=p_revision;
 if not found then raise exception 'body_unavailable'; end if;
 return jsonb_build_object('version',1,'id',p_id,'revision',b.revision,'purge_epoch',p_epoch,'text',b.confirmed_text,'transcription',b.transcription,'solution',b.solution);
end $$;

create function public.study_queue_asset_delete() returns trigger language plpgsql security definer set search_path='' as $$
begin
 insert into public.study_object_deletions(object_path) values(old.object_path) on conflict(object_path) do nothing;
 return old;
end $$;
create trigger study_asset_delete before delete on public.study_photo_assets for each row execute function public.study_queue_asset_delete();

create function public.study_delete_v1(p_epoch integer,p_id uuid) returns void language plpgsql security definer set search_path='' as $$
declare u uuid:=public.study_require_user(p_epoch);
begin
 delete from public.study_bodies where user_id=u and document_id=p_id;
 delete from public.study_photo_assets where user_id=u and document_id=p_id;
 update public.study_documents set deleted_at=public.study_now(),title=null,updated_at=public.study_now(),server_seq=public.next_server_seq(u)
 where user_id=u and id=p_id and deleted_at is null;
end $$;

create function public.study_photo_register_v1(p_epoch integer,p_document uuid,p_asset uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare u uuid:=public.study_require_user(p_epoch); a public.study_photo_assets; t timestamptz:=public.study_now();
begin
 if not exists(select from public.study_documents where user_id=u and id=p_document and deleted_at is null) then raise exception 'document_unavailable'; end if;
 select * into a from public.study_photo_assets where id=p_asset;
 if found then
  if a.user_id<>u or a.document_id<>p_document then raise exception 'asset_unavailable'; end if;
 else
  insert into public.study_photo_assets values(p_asset,u,p_document,gen_random_uuid()::text||'/'||gen_random_uuid()::text,t,t+interval '30 days',false) returning * into a;
  update public.study_documents set server_seq=public.next_server_seq(u),updated_at=t where user_id=u and id=p_document;
 end if;
 return jsonb_build_object('version',1,'id',a.id,'first_stored_at',a.first_stored_at,'expires_at',a.expires_at,'available',not a.delete_requested and a.expires_at>t);
end $$;

-- Service boundary only: Edge derives p_user from verified JWT, never request JSON.
create function public.study_photo_access(p_user uuid,p_epoch integer,p_asset uuid)
returns jsonb language plpgsql security definer set search_path='' as $$
declare a public.study_photo_assets; t timestamptz:=public.study_now(); ttl integer;
begin
 perform public.user_lock(p_user);
 if not exists(select from public.profiles where user_id=p_user and purge_epoch=p_epoch) then raise exception 'no_profile'; end if;
 select * into a from public.study_photo_assets where id=p_asset and user_id=p_user and not delete_requested;
 if not found or a.expires_at<=t then raise exception 'asset_unavailable'; end if;
 ttl:=least(60,floor(extract(epoch from a.expires_at-t))::integer);
 if ttl<1 then raise exception 'asset_unavailable'; end if;
 return jsonb_build_object('bucket','study-restore','path',a.object_path,'ttl_seconds',ttl,'expires_at',a.expires_at);
end $$;

create function public.study_photo_expire() returns integer language plpgsql security definer set search_path='' as $$
declare a record; n integer:=0;
begin
 for a in select id,user_id,document_id from public.study_photo_assets where expires_at<=public.study_now() and not delete_requested order by user_id,id limit 100 loop
  perform public.user_lock(a.user_id);
  insert into public.study_object_deletions(object_path)
  select object_path from public.study_photo_assets where id=a.id and expires_at<=public.study_now() on conflict(object_path) do nothing;
  update public.study_photo_assets set delete_requested=true where id=a.id and expires_at<=public.study_now();
  update public.study_documents set server_seq=public.next_server_seq(a.user_id),updated_at=public.study_now() where user_id=a.user_id and id=a.document_id and deleted_at is null;
  n:=n+1;
 end loop;
 return n;
end $$;
create function public.study_object_claim(p_limit integer default 100) returns setof public.study_object_deletions
language sql security definer set search_path='' as $$
 with picked as (select id from public.study_object_deletions where status='pending' and next_at<=public.study_now()
 order by next_at,id limit greatest(1,least(p_limit,500)) for update skip locked)
 update public.study_object_deletions d set attempts=attempts+1,next_at=public.study_now()+interval '5 minutes'
 where id in(select id from picked) returning d.*
$$;
create function public.study_object_done(p_ids uuid[]) returns void language sql security definer set search_path='' as $$
 update public.study_object_deletions set status='done',completed_at=public.study_now() where id=any(p_ids) and status='pending'
$$;

-- No seed pricing, grants or enabled policies. Commercial terms are NOT defaults.
create table public.ai_policies (
 id uuid primary key default gen_random_uuid(), operation text not null check(operation in ('ocr_text','ocr_math','solve')),
 enabled boolean not null default false, provider text not null check(length(provider) between 1 and 80), model text not null check(length(model) between 1 and 200),
 points integer not null check(points>0), terms_version text not null check(length(terms_version)>0),
 charge_order text not null check(charge_order='earliest_expiry'),
 result_ttl_seconds integer not null check(result_ttl_seconds between 60 and 604800),
 max_input_tokens integer not null check(max_input_tokens between 1 and 100000),
 max_output_tokens integer not null check(max_output_tokens between 1 and 16000),
 max_attempts integer not null check(max_attempts between 1 and 3),
 input_price numeric(20,10) not null check(input_price>=0), output_price numeric(20,10) not null check(output_price>=0),
 fixed_price numeric(20,10) not null check(fixed_price>=0), currency text not null check(currency ~ '^[A-Z]{3}$'),
 price_version text not null, fx_version text not null, fx_at timestamptz not null,
 krw_per_currency numeric(20,10) not null check(krw_per_currency>0),
 lease_seconds integer not null check(lease_seconds between 10 and 300),
 created_at timestamptz not null default now()
);
create unique index ai_one_policy on public.ai_policies(operation) where enabled;
create table public.ai_budgets (
 month date primary key check(extract(day from month)=1), limit_krw numeric(20,8) not null check(limit_krw between 0 and 300000),
 infrastructure_krw numeric(20,8) not null check(infrastructure_krw>=0),
 spent_krw numeric(20,8) not null default 0 check(spent_krw>=0),
 reserved_krw numeric(20,8) not null default 0 check(reserved_krw>=0),
 warning_ratio numeric(4,3) not null check(warning_ratio>0 and warning_ratio<1)
);
create table public.ai_point_lots (
 id uuid primary key default gen_random_uuid(), user_id uuid not null references public.profiles(user_id) on delete cascade,
 source text not null check(source in ('subscription','purchase','correction')), source_id text not null,
 granted integer not null check(granted>0), remaining integer not null, reserved integer not null default 0,
 expires_at timestamptz, created_at timestamptz not null default now(),
 unique(user_id,source,source_id),check(remaining>=reserved and reserved>=0 and remaining<=granted)
);
create index ai_lot_owner on public.ai_point_lots(user_id,expires_at,id);
create table public.ai_jobs (
 id uuid primary key default gen_random_uuid(), user_id uuid references public.profiles(user_id) on delete set null,
 request_id uuid, purge_epoch integer not null, operation text not null,
 input_digest text, document_id uuid, revision integer,
 policy_id uuid not null references public.ai_policies(id), points integer not null,
 state text not null check(state in ('reserved','dispatching','reconciliation_required','succeeded','failed','cancelled')),
 point_state text not null default 'reserved' check(point_state in ('reserved','settled','released')),
 result jsonb, result_expires_at timestamptz, created_at timestamptz not null default now(),
 lease_until timestamptz, unique(user_id,request_id)
);
create index ai_jobs_owner on public.ai_jobs(user_id,state);
create index ai_jobs_lease on public.ai_jobs(lease_until) where state in ('reserved','dispatching');
create table public.ai_point_allocations (
 job_id uuid not null references public.ai_jobs(id), lot_id uuid not null references public.ai_point_lots(id) on delete cascade,
 points integer not null check(points>0), primary key(job_id,lot_id)
);
create table public.ai_point_ledger (
 id bigint generated always as identity primary key,
 user_id uuid not null references public.profiles(user_id) on delete cascade,
 lot_id uuid not null references public.ai_point_lots(id) on delete cascade,
 job_id uuid references public.ai_jobs(id), kind text not null check(kind in ('grant','reserve','settle','release')),
 points integer not null check(points>0), created_at timestamptz not null default now(),
 unique(job_id,lot_id,kind)
);
-- An opaque job/attempt id is sufficient for reconciliation, without a user ID or input.
create table public.ai_costs (
 job_id uuid primary key references public.ai_jobs(id), attempt_id uuid not null unique default gen_random_uuid(),
 month date not null references public.ai_budgets(month), provider text not null, model text not null,
 operation text not null, price_version text not null, currency text not null,
 fx_version text not null, fx_at timestamptz not null, krw_per_currency numeric(20,10) not null,
 estimate_krw numeric(20,8) not null, ceiling_krw numeric(20,8) not null,
 actual_currency numeric(20,10), actual_krw numeric(20,8),
 status text not null default 'reserved' check(status in ('reserved','unknown','settled','not_dispatched')),
 usage jsonb, settlement_id uuid unique, settled_at timestamptz,
 check(estimate_krw>=0 and ceiling_krw>=estimate_krw),check(actual_krw is null or actual_krw>=0)
);
create index ai_cost_month on public.ai_costs(month,status);

create function public.ai_lock() returns void language sql set search_path='' as $$
 select pg_advisory_xact_lock(2147000000,7101)
$$;
create function public.ai_policy_immutable() returns trigger language plpgsql set search_path='' as $$
begin
 if to_jsonb(new)-'enabled' is distinct from to_jsonb(old)-'enabled' then raise exception 'immutable_policy'; end if;
 return new;
end $$;
create trigger ai_policy_immutable before update on public.ai_policies for each row execute function public.ai_policy_immutable();

create function public.ai_budget_set(p_month date,p_limit numeric,p_infrastructure numeric,p_warning numeric)
returns void language plpgsql security definer set search_path='' as $$
declare b public.ai_budgets;
begin
 perform public.ai_lock();
 select * into b from public.ai_budgets where month=p_month;
 if p_limit is null or p_limit<0 or p_limit>300000 or p_infrastructure is null or p_infrastructure<0
 or p_infrastructure+coalesce(b.spent_krw,0)+coalesce(b.reserved_krw,0)>p_limit then raise exception 'budget_invalid'; end if;
 insert into public.ai_budgets(month,limit_krw,infrastructure_krw,warning_ratio) values(p_month,p_limit,p_infrastructure,p_warning)
 on conflict(month) do update set limit_krw=p_limit,infrastructure_krw=p_infrastructure,warning_ratio=p_warning;
end $$;
create function public.ai_grant(p_user uuid,p_source text,p_source_id text,p_points integer,p_expires_at timestamptz)
returns uuid language plpgsql security definer set search_path='' as $$
declare a public.ai_point_lots;
begin
 perform public.user_lock(p_user);
 if not exists(select from public.profiles where user_id=p_user) then raise exception 'no_profile'; end if;
 select * into a from public.ai_point_lots where user_id=p_user and source=p_source and source_id=p_source_id;
 if found then
  if a.granted<>p_points or a.expires_at is distinct from p_expires_at then raise exception 'grant_conflict'; end if;
  return a.id;
 end if;
 if p_source_id is null or length(p_source_id) not between 1 and 200 or p_points is null or p_points<=0
 or (p_expires_at is not null and p_expires_at<=public.study_now()) then raise exception 'invalid_grant'; end if;
 insert into public.ai_point_lots(user_id,source,source_id,granted,remaining,expires_at)
 values(p_user,p_source,p_source_id,p_points,p_points,p_expires_at) returning * into a;
 insert into public.ai_point_ledger(user_id,lot_id,kind,points) values(p_user,a.id,'grant',p_points);
 return a.id;
end $$;
create function public.ai_profile(p_user uuid,p_epoch integer) returns void language plpgsql set search_path='' as $$
begin
 if not exists(select from public.profiles where user_id=p_user and purge_epoch=p_epoch and consent_account_at is not null
 and consent_reading_at is not null and consent_reading_revoked_at is null) then raise exception 'study_access_denied'; end if;
end $$;
create function public.ai_quote(p_user uuid,p_epoch integer,p_operation text) returns jsonb language plpgsql security definer set search_path='' as $$
declare p public.ai_policies;
begin
 perform public.user_lock(p_user); perform public.ai_profile(p_user,p_epoch);
 select * into p from public.ai_policies where operation=p_operation and enabled;
 if not found then raise exception 'policy_unavailable'; end if;
 return jsonb_build_object('version',2,'quote_id',p.id,'operation',p.operation,'points',p.points,'terms_version',p.terms_version);
end $$;
create function public.ai_job_view(p_job uuid) returns jsonb language sql set search_path='' as $$
 select jsonb_build_object('version',2,'job_id',j.id,'request_id',j.request_id,'state',j.state,
 'result',case when j.state='succeeded' and j.result_expires_at>public.study_now() then j.result else null end,
 'result_expired',j.state='succeeded' and (j.result_expires_at<=public.study_now() or j.result is null),
 'retryable',j.state='reserved','points_state',j.point_state)
 from public.ai_jobs j where j.id=p_job
$$;

create function public.ai_reserve(p_user uuid,p_epoch integer,p_request uuid,p_quote uuid,p_operation text,p_digest text,p_document uuid,p_revision integer)
returns jsonb language plpgsql security definer set search_path='' as $$
declare j public.ai_jobs; p public.ai_policies; b public.ai_budgets; lot public.ai_point_lots;
 amount numeric(20,8); mon date; needed integer; take integer; available bigint;
begin
 perform public.user_lock(p_user); perform public.ai_profile(p_user,p_epoch);
 if p_request is null or p_digest is null or p_digest !~ '^[a-f0-9]{64}$' or p_operation is null or p_quote is null or p_operation not in ('ocr_text','ocr_math','solve') then raise exception 'invalid_payload'; end if;
 select * into j from public.ai_jobs where user_id=p_user and request_id=p_request;
 if found then
  if j.purge_epoch<>p_epoch or j.operation<>p_operation or j.input_digest<>p_digest or j.policy_id<>p_quote
  or j.document_id is distinct from p_document or j.revision is distinct from p_revision then raise exception 'request_conflict'; end if;
  return public.ai_job_view(j.id);
 end if;
 select * into p from public.ai_policies where id=p_quote and operation=p_operation and enabled;
 if not found then raise exception 'quote_unavailable'; end if;
 if p_operation='solve' and not exists(select from public.study_documents where user_id=p_user and id=p_document and revision=p_revision and deleted_at is null)
 then raise exception 'revision_conflict'; end if;
 if p_operation<>'solve' and (p_document is not null or p_revision is not null) then raise exception 'invalid_payload'; end if;
 select coalesce(sum(remaining-reserved),0) into available from public.ai_point_lots where user_id=p_user and (expires_at is null or expires_at>public.study_now());
 if available<p.points then raise exception 'points_insufficient'; end if;
 -- Round UP at the reservation unit. No floating point or implicit unlimited budget.
 amount:=ceil((p.max_input_tokens*p.input_price+p.max_output_tokens*p.output_price+p.fixed_price)*p.max_attempts*p.krw_per_currency*100000000)/100000000;
 mon:=date_trunc('month',public.study_now() at time zone 'Asia/Seoul')::date;
 perform public.ai_lock();
 select * into b from public.ai_budgets where month=mon for update;
 if not found then raise exception 'budget_unavailable'; end if;
 if b.spent_krw+b.reserved_krw+b.infrastructure_krw+amount>b.limit_krw then raise exception 'budget_exceeded'; end if;
 insert into public.ai_jobs(user_id,request_id,purge_epoch,operation,input_digest,document_id,revision,policy_id,points,state,lease_until)
 values(p_user,p_request,p_epoch,p_operation,p_digest,p_document,p_revision,p.id,p.points,'reserved',public.study_now()+make_interval(secs=>p.lease_seconds)) returning * into j;
 needed:=p.points;
 for lot in select * from public.ai_point_lots where user_id=p_user and remaining>reserved and (expires_at is null or expires_at>public.study_now()) order by expires_at nulls last,created_at,id loop
  take:=least(needed,lot.remaining-lot.reserved);
  update public.ai_point_lots set reserved=reserved+take where id=lot.id;
  insert into public.ai_point_allocations values(j.id,lot.id,take);
  insert into public.ai_point_ledger(user_id,lot_id,job_id,kind,points) values(p_user,lot.id,j.id,'reserve',take);
  needed:=needed-take; exit when needed=0;
 end loop;
 if needed<>0 then raise exception 'points_insufficient'; end if;
 update public.ai_budgets set reserved_krw=reserved_krw+amount where month=mon;
 insert into public.ai_costs(job_id,month,provider,model,operation,price_version,currency,fx_version,fx_at,krw_per_currency,estimate_krw,ceiling_krw)
 values(j.id,mon,p.provider,p.model,p.operation,p.price_version,p.currency,p.fx_version,p.fx_at,p.krw_per_currency,amount,amount);
 return public.ai_job_view(j.id);
end $$;

create function public.ai_dispatch(p_user uuid,p_epoch integer,p_job uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare j public.ai_jobs; p public.ai_policies; c public.ai_costs;
begin
 perform public.user_lock(p_user); perform public.ai_profile(p_user,p_epoch); perform public.ai_lock();
 select * into j from public.ai_jobs where id=p_job and user_id=p_user and purge_epoch=p_epoch for update;
 if not found then raise exception 'job_unavailable'; end if;
 if j.state<>'reserved' or j.lease_until<=public.study_now() then return jsonb_build_object('claimed',false,'job',public.ai_job_view(j.id)); end if;
 select * into p from public.ai_policies where id=j.policy_id and enabled;
 if not found then raise exception 'policy_unavailable'; end if;
 if j.operation='solve' and not exists(select from public.study_documents where user_id=p_user and id=j.document_id and revision=j.revision and deleted_at is null) then raise exception 'revision_conflict'; end if;
 update public.ai_jobs set state='dispatching',lease_until=public.study_now()+make_interval(secs=>p.lease_seconds) where id=j.id;
 update public.ai_costs set status='unknown' where job_id=j.id returning * into c;
 return jsonb_build_object('claimed',true,'attempt_id',c.attempt_id,'provider',p.provider,'model',p.model,
 'limits',jsonb_build_object('max_input_tokens',p.max_input_tokens,'max_output_tokens',p.max_output_tokens,'max_attempts',p.max_attempts),'job',public.ai_job_view(j.id));
end $$;

create function public.ai_points_finish(p_job uuid,p_charge boolean) returns void language plpgsql set search_path='' as $$
declare j public.ai_jobs; a record;
begin
 select * into j from public.ai_jobs where id=p_job;
 if j.point_state<>'reserved' then return; end if;
 for a in select * from public.ai_point_allocations where job_id=p_job loop
  update public.ai_point_lots set reserved=reserved-a.points,remaining=remaining-case when p_charge then a.points else 0 end where id=a.lot_id;
  if j.user_id is not null then insert into public.ai_point_ledger(user_id,lot_id,job_id,kind,points)
   values(j.user_id,a.lot_id,p_job,case when p_charge then 'settle' else 'release' end,a.points); end if;
 end loop;
 update public.ai_jobs set point_state=case when p_charge then 'settled' else 'released' end where id=p_job;
end $$;

create function public.ai_finish(p_job uuid,p_outcome text,p_result jsonb default null) returns jsonb language plpgsql security definer set search_path='' as $$
declare j public.ai_jobs; u uuid; valid boolean; ttl integer; c public.ai_costs;
begin
 select user_id into u from public.ai_jobs where id=p_job;
 if u is not null then perform public.user_lock(u); end if;
 perform public.ai_lock();
 select * into j from public.ai_jobs where id=p_job for update;
 if not found then raise exception 'job_unavailable'; end if;
 if p_outcome is null or p_outcome not in ('succeeded','failed','cancelled','reconciliation_required') then raise exception 'invalid_outcome'; end if;
 if j.state in ('succeeded','failed','cancelled') then return public.ai_job_view(j.id); end if;
 valid:=exists(select from public.profiles where user_id=j.user_id and purge_epoch=j.purge_epoch and consent_account_at is not null and consent_reading_at is not null and consent_reading_revoked_at is null);
 if j.operation='solve' then valid:=valid and exists(select from public.study_documents where user_id=j.user_id and id=j.document_id and revision=j.revision and deleted_at is null); end if;
 if not valid then p_outcome:='cancelled'; p_result:=null; end if;
 if p_outcome='succeeded' then
  if j.state not in ('dispatching','reconciliation_required') then raise exception 'invalid_transition'; end if;
  if (j.operation='solve' and not public.study_valid_solution(p_result,j.document_id,j.revision)) or
   (j.operation<>'solve' and not public.study_valid_transcription(p_result,case when j.operation='ocr_math' then 'math' else 'text' end))
   or p_result is null then raise exception 'invalid_engine_result'; end if;
  select result_ttl_seconds into ttl from public.ai_policies where id=j.policy_id;
  perform public.ai_points_finish(j.id,true);
  update public.ai_jobs set result=p_result,result_expires_at=public.study_now()+make_interval(secs=>ttl) where id=j.id;
 elsif p_outcome in ('failed','cancelled') then
  perform public.ai_points_finish(j.id,false);
 end if;
 -- Only a never-dispatched reservation is proved to have consumed no external cost.
 if j.state='reserved' and p_outcome in ('failed','cancelled') then
  select * into c from public.ai_costs where job_id=j.id;
  update public.ai_budgets set reserved_krw=reserved_krw-c.ceiling_krw where month=c.month;
  update public.ai_costs set status='not_dispatched',actual_currency=0,actual_krw=0,settled_at=public.study_now() where job_id=j.id;
 end if;
 update public.ai_jobs set state=p_outcome where id=j.id;
 return public.ai_job_view(j.id);
end $$;

create function public.ai_reconcile(p_job uuid,p_settlement uuid,p_actual numeric,p_usage jsonb) returns void language plpgsql security definer set search_path='' as $$
declare c public.ai_costs; amount numeric(20,8);
begin
 -- Cost-only path NEVER takes a user lock or creates a profile/wallet.
 perform public.ai_lock(); select * into c from public.ai_costs where job_id=p_job for update;
 if not found then raise exception 'cost_unavailable'; end if;
 if p_settlement is null or p_actual is null or p_actual<0 or p_actual::text in ('NaN','Infinity','-Infinity') or p_usage is null or jsonb_typeof(p_usage)<>'object'
 or octet_length(p_usage::text)>2000 or exists(select from jsonb_object_keys(p_usage) k where k not in ('input_tokens','output_tokens','cached_tokens','reasoning_tokens','requests'))
 or exists(select from jsonb_each(p_usage) v where jsonb_typeof(v.value)<>'number' or v.value::text !~ '^[0-9]+$') then raise exception 'invalid_cost'; end if;
 if c.status='settled' then
  if c.settlement_id<>p_settlement or c.actual_currency<>p_actual or c.usage<>p_usage then raise exception 'settlement_conflict'; end if;
  return;
 end if;
 if c.status<>'unknown' then raise exception 'invalid_transition'; end if;
 amount:=ceil(p_actual*c.krw_per_currency*100000000)/100000000;
 -- A real overrun is recorded, not suppressed to make the budget appear safe.
 update public.ai_budgets set reserved_krw=reserved_krw-c.ceiling_krw,spent_krw=spent_krw+amount where month=c.month;
 update public.ai_costs set status='settled',actual_currency=p_actual,actual_krw=amount,usage=p_usage,settlement_id=p_settlement,settled_at=public.study_now() where job_id=p_job;
end $$;
create function public.ai_status(p_user uuid,p_epoch integer,p_request uuid) returns jsonb language plpgsql security definer set search_path='' as $$
declare j public.ai_jobs;
begin
 perform public.user_lock(p_user); perform public.ai_profile(p_user,p_epoch);
 select * into j from public.ai_jobs where user_id=p_user and request_id=p_request and purge_epoch=p_epoch;
 if not found then raise exception 'job_unavailable'; end if;
 return public.ai_job_view(j.id);
end $$;
create function public.ai_maintenance() returns integer language plpgsql security definer set search_path='' as $$
declare j record; n integer:=0;
begin
 -- ONE owner per transaction; never hold the global lock and then take another user's lock.
 for j in select id,user_id from public.ai_jobs where state in ('reserved','dispatching') and lease_until<=public.study_now() order by lease_until,id limit 1 loop
  if j.user_id is not null then perform public.user_lock(j.user_id); end if;
  -- Recheck after the lock: a completed job must never be rewritten by the sweep.
  if exists(select from public.ai_jobs where id=j.id and state='reserved' and lease_until<=public.study_now()) then
   perform public.ai_finish(j.id,'cancelled'); n:=n+1;
  elsif exists(select from public.ai_jobs where id=j.id and state='dispatching' and lease_until<=public.study_now()) then
   perform public.ai_finish(j.id,'reconciliation_required'); n:=n+1;
  end if;
 end loop;
 update public.ai_jobs set result=null where result_expires_at<=public.study_now();
 return n;
end $$;

create function public.study_account_boundary() returns trigger language plpgsql security definer set search_path='' as $$
declare j record;
begin
 if tg_op='UPDATE' and new.purge_epoch=old.purge_epoch then return new; end if;
 perform public.user_lock(old.user_id);
 for j in select id from public.ai_jobs where user_id=old.user_id order by id loop
  perform public.ai_finish(j.id,'cancelled');
 end loop;
 -- Final succeeded results must also be removed. Point/cost ledgers survive purge.
 update public.ai_jobs set result=null,input_digest=null,document_id=null,revision=null,
 state='cancelled' where user_id=old.user_id;
 delete from public.study_documents where user_id=old.user_id;
 if tg_op='DELETE' then
  update public.ai_jobs set user_id=null,request_id=null where user_id=old.user_id;
  return old;
 end if;
 return new;
end $$;
create trigger study_account_boundary before update of purge_epoch or delete on public.profiles for each row execute function public.study_account_boundary();

-- API roles have no direct access, including service routines through PUBLIC.
do $$ declare t text; f record; begin
 for t in select unnest(array['study_documents','study_bodies','study_photo_assets','study_object_deletions','ai_policies','ai_budgets','ai_point_lots','ai_jobs','ai_point_allocations','ai_point_ledger','ai_costs']) loop
  execute format('alter table public.%I enable row level security',t);
  execute format('revoke all on public.%I from public, anon, authenticated',t);
 end loop;
 for f in select oid::regprocedure as signature from pg_proc where pronamespace='public'::regnamespace and (proname like 'study_%' or proname like 'ai_%') loop
  execute format('revoke execute on function %s from public,anon,authenticated,service_role',f.signature);
 end loop;
end $$;
grant execute on function public.study_save_v1(integer,uuid,integer,text,text,text,jsonb),public.study_solution_v1(integer,uuid,integer,jsonb),
 public.study_metadata_v1(integer,bigint,integer),public.study_body_v1(integer,uuid,integer),public.study_delete_v1(integer,uuid),public.study_photo_register_v1(integer,uuid,uuid) to authenticated;
grant execute on function public.study_photo_access(uuid,integer,uuid),public.study_photo_expire(),public.study_object_claim(integer),public.study_object_done(uuid[]),
 public.ai_budget_set(date,numeric,numeric,numeric),public.ai_grant(uuid,text,text,integer,timestamptz),public.ai_quote(uuid,integer,text),
 public.ai_reserve(uuid,integer,uuid,uuid,text,text,uuid,integer),public.ai_dispatch(uuid,integer,uuid),public.ai_finish(uuid,text,jsonb),
 public.ai_reconcile(uuid,uuid,numeric,jsonb),public.ai_status(uuid,integer,uuid),public.ai_maintenance() to service_role;

-- No outbound request until existing server_config is explicitly provisioned.
-- Register only in the deployment migration; this session applies it in CI only.
select public.cron_upsert('soongong-study-maintenance','*/5 * * * *',
 $$select public.invoke_edge('study-maintenance','{"source":"cron"}'::jsonb)
 where exists(select from public.study_photo_assets where not delete_requested and expires_at<=public.study_now())
 or exists(select from public.study_object_deletions where status='pending' and next_at<=public.study_now())
 or exists(select from public.ai_jobs where (state in ('reserved','dispatching') and lease_until<=public.study_now()) or (result is not null and result_expires_at<=public.study_now()));$$);
