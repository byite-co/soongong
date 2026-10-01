-- DEV PROJECT ONLY — never applied to prod (D6 acceptance: "훅 통과 후 트리거 단계 실패").
-- Re-creates the identity trigger function with one extra branch: after the
-- pass was consumed, `app.test_trigger_fail = 'on'` raises, so the whole
-- signup (user + identity + approval) rolls back and the pass stays.
--
-- Enable for a real Auth API signup:   alter database postgres set app.test_trigger_fail = 'on';
--   (Auth keeps pooled connections — terminate supabase_auth_admin backends or
--   wait for new connections). Disable: alter database postgres reset app.test_trigger_fail;
-- pgTAP uses `set local app.test_trigger_fail = 'on'`.
create or replace function public.signup_identity_trigger()
returns trigger language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_provider text := new.provider;
  v_subject text;
  v_consumed int;
begin
  if exists (select 1 from public.signup_approvals where user_id = new.user_id) then
    return new;
  end if;
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
  -- dev-only failure injection (after consumption, before approval)
  if current_setting('app.test_trigger_fail', true) = 'on' then
    raise exception 'test_trigger_fail' using errcode = 'P0001';
  end if;
  insert into public.signup_approvals (user_id, provider, age_verified, approved_at)
  values (new.user_id, v_provider, true, now())
  on conflict (user_id) do nothing;
  return new;
end $$;
revoke execute on function public.signup_identity_trigger() from public, anon, authenticated, service_role;
grant execute on function public.signup_identity_trigger() to supabase_auth_admin;
