-- DEV PROJECT ONLY — S03b execution-verification support. Never applied to prod.
--
-- 1. e2e_token: random token generated in the DB (never leaves the project);
--    the e2e-runner Edge function compares it with x-e2e-token.
-- 2. e2e_counts / e2e_pass_count: row counts by test e-mail for the runner's
--    redacted report (service_role only).
-- 3. hook_fixtures + hook capture: when server_config.hook_fixtures_capture =
--    'on', the before-user-created hook ALSO records the SHAPE of the payload
--    (provider, key paths, which subject source matched) — values are never
--    stored. The prod hook (0004) writes nothing.
insert into public.server_config (key, value) values ('e2e_token', gen_random_uuid()::text)
on conflict (key) do nothing;

create or replace function public.e2e_counts(p_email text)
returns jsonb language plpgsql security definer
set search_path = public, pg_temp
as $$
declare v_user uuid;
begin
  select id into v_user from auth.users where lower(email) = lower(p_email) limit 1;
  return jsonb_build_object(
    'users', (select count(*) from auth.users where lower(email) = lower(p_email)),
    'identities', (select count(*) from auth.identities where lower(identity_data ->> 'email') = lower(p_email)),
    'approvals', case when v_user is null then 0 else (select count(*) from public.signup_approvals where user_id = v_user) end,
    'approval_user_matches', case when v_user is null then null else exists (select 1 from public.signup_approvals where user_id = v_user) end,
    'profiles', case when v_user is null then 0 else (select count(*) from public.profiles where user_id = v_user) end,
    'passes', (select count(*) from public.signup_passes where provider = 'email' and subject_hash = public.subject_hash(lower(p_email))));
end $$;
revoke execute on function public.e2e_counts(text) from public, anon, authenticated;
grant execute on function public.e2e_counts(text) to service_role;

create or replace function public.e2e_pass_count(p_email text)
returns int language sql security definer
set search_path = public, pg_temp
as $$ select count(*)::int from public.signup_passes where provider = 'email' and subject_hash = public.subject_hash(lower(p_email)) $$;
revoke execute on function public.e2e_pass_count(text) from public, anon, authenticated;
grant execute on function public.e2e_pass_count(text) to service_role;

create table if not exists public.hook_fixtures (
  id bigserial primary key,
  captured_at timestamptz not null default now(),
  provider text,
  subject_source text,          -- email | user_metadata.sub | user_metadata.provider_id | none
  key_paths jsonb not null,     -- sorted list of JSON paths present in the payload (no values)
  decision text not null        -- allow | reject
);
alter table public.hook_fixtures enable row level security;
revoke all on table public.hook_fixtures from public, anon, authenticated;

-- paths of a jsonb document (keys only, arrays as [])
create or replace function public.jsonb_key_paths(p jsonb, p_prefix text default '')
returns setof text language sql immutable
as $$
  select case when jsonb_typeof(p) = 'object' then
    (select p_prefix || k from jsonb_object_keys(p) k)
  end
  union all
  select sub from jsonb_each(case when jsonb_typeof(p) = 'object' then p else '{}'::jsonb end) e,
       lateral public.jsonb_key_paths(e.value, p_prefix || e.key || '.') sub
  where jsonb_typeof(e.value) = 'object'
$$;
revoke execute on function public.jsonb_key_paths(jsonb, text) from public, anon, authenticated, service_role;

create or replace function public.before_user_created_hook(event jsonb)
returns jsonb language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_provider text;
  v_subject text;
  v_source text := 'none';
  v_decision text := 'reject';
  v_reject constant jsonb := jsonb_build_object('error', jsonb_build_object('http_code', 400, 'message', '가입 확인이 필요합니다'));
begin
  select s.provider, s.subject into v_provider, v_subject from public.signup_subject_from_hook(event) s;
  if v_subject is not null then
    v_source := case when v_provider = 'email' then 'email'
                     when (event -> 'user' -> 'user_metadata' ->> 'sub') is not null then 'user_metadata.sub'
                     else 'user_metadata.provider_id' end;
    if exists (select 1 from public.signup_passes
               where provider = v_provider and subject_hash = public.subject_hash(v_subject) and expires_at > now()) then
      v_decision := 'allow';
    end if;
  end if;
  if public.server_config_get('hook_fixtures_capture') = 'on' then
    insert into public.hook_fixtures (provider, subject_source, key_paths, decision)
    values (event -> 'user' -> 'app_metadata' ->> 'provider', v_source,
            (select coalesce(jsonb_agg(path order by path), '[]'::jsonb) from public.jsonb_key_paths(event) path where path is not null),
            v_decision);
  end if;
  return case when v_decision = 'allow' then '{}'::jsonb else v_reject end;
end $$;
revoke execute on function public.before_user_created_hook(jsonb) from public, anon, authenticated, service_role;
grant execute on function public.before_user_created_hook(jsonb) to supabase_auth_admin;
