-- =============================================================================
-- S03 · 0004_signup.sql — D6 signup gate (hook = check only, trigger = consume
-- + approve), profiles / consent, onboarding RPC, inquiries.
--
-- Roles (D24): the hook function and the auth.identities trigger function are
-- owned by postgres, SECURITY DEFINER, EXECUTE only for supabase_auth_admin.
-- The hook writes nothing. The trigger consumes the pass (DELETE … RETURNING)
-- and inserts signup_approvals in the SAME transaction as the user/identity
-- insert; a RAISE rolls the whole signup back (backstop when the hook is off).
--
-- Pass key: social (provider, sha256(sub)) · email ('email', sha256(lower(email))).
-- Hashes are lowercase hex. The hook never logs email / sub / birth date.
-- =============================================================================

create or replace function public.subject_hash(p text)
returns text language sql immutable strict parallel safe
set search_path = public, pg_temp
as $$ select encode(sha256(convert_to(p, 'UTF8')), 'hex') $$;
revoke execute on function public.subject_hash(text) from public, anon, authenticated;
grant execute on function public.subject_hash(text) to service_role, supabase_auth_admin;

-- Extract (provider, subject) from the before-user-created payload.
-- email  → ('email', lower(user.email))
-- social → (app_metadata.provider, user_metadata.sub | user_metadata.provider_id)
--   `identities` is empty at hook time (Supabase docs); the provider claims
--   are copied into user_metadata by Auth. Path-specific fixtures:
--   docs/supabase-auth.md §3 (captured on the dev project, see handoff).
create or replace function public.signup_subject_from_hook(event jsonb, out provider text, out subject text)
language plpgsql immutable
set search_path = public, pg_temp
as $$
begin
  provider := event -> 'user' -> 'app_metadata' ->> 'provider';
  if provider is null or provider = 'email' then
    provider := 'email';
    subject := lower(nullif(event -> 'user' ->> 'email', ''));
  else
    subject := coalesce(nullif(event -> 'user' -> 'user_metadata' ->> 'sub', ''),
                        nullif(event -> 'user' -> 'user_metadata' ->> 'provider_id', ''));
  end if;
end $$;
revoke execute on function public.signup_subject_from_hook(jsonb) from public, anon, authenticated;
grant execute on function public.signup_subject_from_hook(jsonb) to supabase_auth_admin, service_role;

-- Before User Created hook (read-only). Supabase calls it as supabase_auth_admin.
create or replace function public.before_user_created_hook(event jsonb)
returns jsonb language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_provider text;
  v_subject text;
  v_reject constant jsonb := jsonb_build_object('error', jsonb_build_object('http_code', 400, 'message', '가입 확인이 필요합니다'));
begin
  select s.provider, s.subject into v_provider, v_subject from public.signup_subject_from_hook(event) s;
  if v_subject is null then
    return v_reject;
  end if;
  if exists (
    select 1 from public.signup_passes
    where provider = v_provider and subject_hash = public.subject_hash(v_subject) and expires_at > now()
  ) then
    return '{}'::jsonb;
  end if;
  return v_reject;
end $$;
revoke execute on function public.before_user_created_hook(jsonb) from public, anon, authenticated, service_role;
grant execute on function public.before_user_created_hook(jsonb) to supabase_auth_admin;

-- AFTER INSERT ON auth.identities — consume pass, approve (D6 order ①②).
create or replace function public.signup_identity_trigger()
returns trigger language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_provider text := new.provider;
  v_subject text;
  v_consumed int;
begin
  -- ① already approved → account linking (same-email OAuth auto-link included)
  if exists (select 1 from public.signup_approvals where user_id = new.user_id) then
    return new;
  end if;
  -- ② new signup → consume exactly one unexpired pass
  if v_provider = 'email' then
    v_subject := lower(nullif(new.identity_data ->> 'email', ''));
  else
    v_subject := nullif(new.provider_id, '');
  end if;
  if v_subject is null then
    raise exception 'signup_pass_required' using errcode = 'P0001';
  end if;
  delete from public.signup_passes
  where provider = v_provider and subject_hash = public.subject_hash(v_subject) and expires_at > now();
  get diagnostics v_consumed = row_count;
  if v_consumed = 0 then
    raise exception 'signup_pass_required' using errcode = 'P0001';
  end if;
  insert into public.signup_approvals (user_id, provider, age_verified, approved_at)
  values (new.user_id, v_provider, true, now())
  on conflict (user_id) do nothing;
  return new;
end $$;
revoke execute on function public.signup_identity_trigger() from public, anon, authenticated, service_role;
grant execute on function public.signup_identity_trigger() to supabase_auth_admin;

drop trigger if exists soongong_signup_identity on auth.identities;
create trigger soongong_signup_identity
  after insert on auth.identities
  for each row execute function public.signup_identity_trigger();

-- Pass upsert for issue-pass (service_role). Same key unconsumed → extend.
create or replace function public.signup_pass_upsert(p_provider text, p_subject text, p_ttl_seconds int default 600)
returns jsonb language plpgsql security definer
set search_path = public, pg_temp
as $$
declare v_exp timestamptz := now() + make_interval(secs => greatest(60, least(coalesce(p_ttl_seconds, 600), 3600)));
begin
  if p_provider not in ('email','apple','google','kakao') or p_subject is null or p_subject = '' then
    raise exception 'invalid_pass' using errcode = 'P0001';
  end if;
  insert into public.signup_passes (provider, subject_hash, expires_at)
  values (p_provider, public.subject_hash(case when p_provider = 'email' then lower(p_subject) else p_subject end), v_exp)
  on conflict (provider, subject_hash) do update set expires_at = excluded.expires_at;
  return jsonb_build_object('expires_at', public.iso_utc(v_exp));
end $$;
revoke execute on function public.signup_pass_upsert(text, text, int) from public, anon, authenticated;
grant execute on function public.signup_pass_upsert(text, text, int) to service_role;

-- check-email: existence only (service_role; the Edge function rate-limits).
create or replace function public.auth_email_exists(p_email text)
returns boolean language sql stable security definer
set search_path = public, pg_temp
as $$ select exists (select 1 from auth.users u where lower(u.email) = lower(p_email)) $$;
revoke execute on function public.auth_email_exists(text) from public, anon, authenticated;
grant execute on function public.auth_email_exists(text) to service_role;

-- complete-signup: approval → profile (idempotent) + consent ① (account / learning records).
create or replace function public.complete_signup(p_user uuid, p_consent_version text)
returns jsonb language plpgsql security definer
set search_path = public, pg_temp
as $$
declare v_ok boolean; p public.profiles%rowtype;
begin
  select age_verified into v_ok from public.signup_approvals where user_id = p_user;
  if not coalesce(v_ok, false) then
    raise exception 'not_approved' using errcode = 'P0001';
  end if;
  if p_consent_version is null or p_consent_version = '' then
    raise exception 'consent_required' using errcode = 'P0001';
  end if;
  perform public.user_lock(p_user);
  insert into public.profiles (user_id, consent_account_version, consent_account_at)
  values (p_user, p_consent_version, now())
  on conflict (user_id) do update
    set consent_account_version = excluded.consent_account_version,
        consent_account_at = coalesce(public.profiles.consent_account_at, now());
  select * into p from public.profiles where user_id = p_user;
  return public.profile_json(p);
end $$;

create or replace function public.profile_json(p public.profiles)
returns jsonb language sql immutable
set search_path = public, pg_temp
as $$
  select jsonb_build_object(
    'user_id', p.user_id,
    'onboarding_done', p.onboarding_done,
    'consent_account_version', p.consent_account_version,
    'consent_account_at', case when p.consent_account_at is null then null else public.iso_utc(p.consent_account_at) end,
    'consent_reading_version', p.consent_reading_version,
    'consent_reading_at', case when p.consent_reading_at is null then null else public.iso_utc(p.consent_reading_at) end,
    'consent_reading_revoked_at', case when p.consent_reading_revoked_at is null then null else public.iso_utc(p.consent_reading_revoked_at) end,
    'consent_reading_active', (p.consent_reading_at is not null and p.consent_reading_revoked_at is null),
    'purge_epoch', p.purge_epoch,
    'created_at', public.iso_utc(p.created_at))
$$;
revoke execute on function public.profile_json(public.profiles) from public, anon, authenticated, service_role;
revoke execute on function public.complete_signup(uuid, text) from public, anon, authenticated;
grant execute on function public.complete_signup(uuid, text) to service_role;

-- update-consent: consent ② (external reading transfer) grant / revoke.
create or replace function public.update_consent(p_user uuid, p_version text, p_granted boolean)
returns jsonb language plpgsql security definer
set search_path = public, pg_temp
as $$
declare p public.profiles%rowtype;
begin
  perform public.user_lock(p_user);
  select * into p from public.profiles where user_id = p_user for update;
  if not found then
    raise exception 'no_profile' using errcode = 'P0001';
  end if;
  if p_granted then
    if p_version is null or p_version = '' then
      raise exception 'consent_required' using errcode = 'P0001';
    end if;
    update public.profiles set consent_reading_version = p_version, consent_reading_at = now(), consent_reading_revoked_at = null
    where user_id = p_user;
  else
    update public.profiles set consent_reading_revoked_at = now() where user_id = p_user and consent_reading_at is not null;
  end if;
  select * into p from public.profiles where user_id = p_user;
  return public.profile_json(p);
end $$;
revoke execute on function public.update_consent(uuid, text, boolean) from public, anon, authenticated;
grant execute on function public.update_consent(uuid, text, boolean) to service_role;

-- Consent ② currently valid? (reading_submit check)
create or replace function public.reading_consent_active(p_user uuid)
returns boolean language sql stable security definer
set search_path = public, pg_temp
as $$ select exists (select 1 from public.profiles where user_id = p_user and consent_reading_at is not null and consent_reading_revoked_at is null) $$;
revoke execute on function public.reading_consent_active(uuid) from public, anon, authenticated, service_role;

-- profile_set_onboarding_done() — the one profile write users do directly (authenticated RPC).
create or replace function public.profile_set_onboarding_done()
returns jsonb language plpgsql security definer
set search_path = public, pg_temp
as $$
declare v_user uuid := auth.uid(); p public.profiles%rowtype;
begin
  if v_user is null then
    raise exception 'not_authenticated' using errcode = 'P0001';
  end if;
  update public.profiles set onboarding_done = true where user_id = v_user returning * into p;
  if not found then
    raise exception 'no_profile' using errcode = 'P0001';
  end if;
  return public.profile_json(p);
end $$;
revoke execute on function public.profile_set_onboarding_done() from public, anon, authenticated, service_role;
grant execute on function public.profile_set_onboarding_done() to authenticated;

-- profile read for the app (service path via Edge complete-signup/update-consent responses);
-- users also SELECT their own profiles row through RLS.

-- submit-inquiry (service_role; Edge enforces auth). 2000 chars, 10/day.
create or replace function public.submit_inquiry(p_user uuid, p_body text, p_reply_email text)
returns jsonb language plpgsql security definer
set search_path = public, pg_temp
as $$
declare v_id uuid; v_today int;
begin
  if not exists (select 1 from public.profiles where user_id = p_user) then
    raise exception 'no_profile' using errcode = 'P0001';
  end if;
  if p_body is null or char_length(btrim(p_body)) = 0 or char_length(p_body) > 2000 then
    raise exception 'invalid_body' using errcode = 'P0001';
  end if;
  perform public.user_lock(p_user);
  select count(*) into v_today from public.inquiries
  where user_id = p_user and created_at >= date_trunc('day', now() at time zone 'Asia/Seoul') at time zone 'Asia/Seoul';
  if v_today >= 10 then
    raise exception 'rate_limited' using errcode = 'P0001';
  end if;
  insert into public.inquiries (user_id, body, reply_email) values (p_user, p_body, nullif(btrim(p_reply_email), ''))
  returning id into v_id;
  return jsonb_build_object('id', v_id, 'created_at', public.iso_utc(now()));
end $$;
revoke execute on function public.submit_inquiry(uuid, text, text) from public, anon, authenticated;
grant execute on function public.submit_inquiry(uuid, text, text) to service_role;
