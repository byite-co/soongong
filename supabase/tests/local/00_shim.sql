-- Local-only Supabase emulation for running the S03 migrations + pgTAP tests
-- against a plain PostgreSQL 16 (no Supabase CLI / Docker in the dev box).
-- NOT applied to any Supabase project. It creates the roles, the `auth`
-- schema subset the migrations touch, `auth.uid()/role()/jwt()` exactly as
-- Supabase implements them (request.jwt.claims), an `extensions` schema and
-- a recording stub of `net.http_post` (pg_net is not packaged for Ubuntu).

do $$
begin
  if not exists (select 1 from pg_roles where rolname = 'anon') then create role anon nologin noinherit; end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticated') then create role authenticated nologin noinherit; end if;
  if not exists (select 1 from pg_roles where rolname = 'service_role') then create role service_role nologin noinherit bypassrls; end if;
  if not exists (select 1 from pg_roles where rolname = 'supabase_auth_admin') then create role supabase_auth_admin nologin noinherit createrole; end if;
  if not exists (select 1 from pg_roles where rolname = 'authenticator') then create role authenticator noinherit login; end if;
end $$;
grant anon, authenticated, service_role to authenticator;
grant anon, authenticated, service_role, supabase_auth_admin to postgres;

create schema if not exists extensions;
grant usage on schema extensions to anon, authenticated, service_role;

-- Supabase default privileges (what a fresh project has): functions in
-- `public` created by `postgres` are executable by anon/authenticated/
-- service_role. The migrations must REVOKE these — rls.sql checks it.
alter default privileges for role postgres in schema public grant execute on functions to anon, authenticated, service_role;
alter default privileges for role postgres in schema public grant all on tables to anon, authenticated, service_role;
alter default privileges for role postgres in schema public grant all on sequences to anon, authenticated, service_role;
grant usage on schema public to anon, authenticated, service_role;

-- auth schema (subset) ----------------------------------------------------
create schema if not exists auth authorization supabase_auth_admin;
grant usage on schema auth to postgres, anon, authenticated, service_role;

create table if not exists auth.users (
  id uuid primary key default gen_random_uuid(),
  email text,
  encrypted_password text,
  raw_app_meta_data jsonb not null default '{}'::jsonb,
  raw_user_meta_data jsonb not null default '{}'::jsonb,
  is_anonymous boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table auth.users owner to supabase_auth_admin;

create table if not exists auth.identities (
  id uuid primary key default gen_random_uuid(),
  provider_id text not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  identity_data jsonb not null,
  provider text not null,
  last_sign_in_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  email text generated always as (lower(identity_data->>'email')) stored,
  unique (provider_id, provider)
);
alter table auth.identities owner to supabase_auth_admin;

grant all on auth.users, auth.identities to postgres, supabase_auth_admin;
grant select on auth.users, auth.identities to service_role;

create or replace function auth.jwt() returns jsonb language sql stable as $$
  select coalesce(
    nullif(current_setting('request.jwt.claim', true), ''),
    nullif(current_setting('request.jwt.claims', true), '')
  )::jsonb
$$;
create or replace function auth.uid() returns uuid language sql stable as $$
  select nullif(coalesce(
    current_setting('request.jwt.claim.sub', true),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'sub')
  ), '')::uuid
$$;
create or replace function auth.role() returns text language sql stable as $$
  select nullif(coalesce(
    current_setting('request.jwt.claim.role', true),
    (nullif(current_setting('request.jwt.claims', true), '')::jsonb ->> 'role')
  ), '')::text
$$;
grant execute on function auth.jwt(), auth.uid(), auth.role() to public;

-- pg_net stub ---------------------------------------------------------------
create schema if not exists net;
create table if not exists net._test_requests (
  id bigserial primary key,
  url text not null,
  body jsonb,
  headers jsonb,
  created_at timestamptz not null default clock_timestamp()
);
create or replace function net.http_post(
  url text,
  body jsonb default '{}'::jsonb,
  params jsonb default '{}'::jsonb,
  headers jsonb default '{"Content-Type": "application/json"}'::jsonb,
  timeout_milliseconds int default 2000
) returns bigint language plpgsql security definer as $$
declare v_id bigint;
begin
  insert into net._test_requests(url, body, headers) values (url, body, headers) returning id into v_id;
  return v_id;
end $$;
grant usage on schema net to postgres, service_role, authenticated;
grant select on net._test_requests to service_role, authenticated;

-- storage schema stub: buckets + objects with the columns photo_residue_run()
-- reads (bucket_id · name · created_at · id). path_tokens mirrors Supabase.
create schema if not exists storage;
create table if not exists storage.buckets (
  id text primary key,
  name text not null,
  public boolean not null default false,
  created_at timestamptz not null default now()
);
create table if not exists storage.objects (
  id uuid primary key default gen_random_uuid(),
  bucket_id text references storage.buckets(id),
  name text,
  owner uuid,
  owner_id text,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  last_accessed_at timestamptz default now(),
  metadata jsonb,
  path_tokens text[] generated always as (string_to_array(name, '/')) stored,
  version text
);
insert into storage.buckets (id, name, public) values ('reading-photos', 'reading-photos', false) on conflict do nothing;
grant usage on schema storage to postgres, service_role;
