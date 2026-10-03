-- =============================================================================
-- S03 · 0006_billing.sql — D18 RevenueCat webhook ledger
--
-- revenuecat_apply_event(p_event) (service_role; the Edge function verifies
-- the webhook Authorization header first):
--   1. insert subscription_events (event_id PK; duplicate → 'duplicate')
--   2. app_user_id must be the auth uid (RevenueCat appUserId = auth.uid)
--   3. event_timestamp older than subscription_state.last_event_at → 'stale'
--   4. update expires_at / grace_expires_at / period_type / will_renew by type,
--      then status = entitlement_status() (same table as the app, D18).
-- BILLING_ISSUE only feeds grace_expires_at (may be null).
-- =============================================================================
create or replace function public.revenuecat_apply_event(p_event jsonb)
returns jsonb language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  e jsonb := coalesce(p_event -> 'event', p_event);
  v_id text := e ->> 'id';
  v_type text := e ->> 'type';
  v_user uuid;
  v_at timestamptz;
  v_exp timestamptz;
  v_grace timestamptz;
  v_period text := e ->> 'period_type';
  v_conv boolean := (e ->> 'is_trial_conversion')::boolean;
  s public.subscription_state%rowtype;
  st record;
  v_inserted int;
begin
  if v_id is null or v_type is null or (e ->> 'event_timestamp_ms') is null then
    raise exception 'invalid_event' using errcode = 'P0001';
  end if;
  v_at := to_timestamp((e ->> 'event_timestamp_ms')::bigint / 1000.0);
  v_exp := case when (e ->> 'expiration_at_ms') is null then null else to_timestamp((e ->> 'expiration_at_ms')::bigint / 1000.0) end;
  v_grace := case when (e ->> 'grace_period_expiration_at_ms') is null then null else to_timestamp((e ->> 'grace_period_expiration_at_ms')::bigint / 1000.0) end;
  begin
    v_user := (e ->> 'app_user_id')::uuid;
  exception when others then
    v_user := null;
  end;
  if v_user is not null and not exists (select 1 from auth.users where id = v_user) then
    v_user := null;
  end if;

  insert into public.subscription_events (event_id, user_id, type, period_type, is_trial_conversion,
    grace_period_expiration_at, expiration_at, event_at, raw)
  values (v_id, v_user, v_type, v_period, v_conv, v_grace, v_exp, v_at, p_event)
  on conflict (event_id) do nothing;
  get diagnostics v_inserted = row_count;
  if v_inserted = 0 then
    return jsonb_build_object('outcome', 'duplicate');
  end if;
  if v_user is null then
    return jsonb_build_object('outcome', 'stored_unlinked');
  end if;

  perform public.user_lock(v_user);
  insert into public.subscription_state (user_id) values (v_user) on conflict do nothing;
  select * into s from public.subscription_state where user_id = v_user for update;
  if s.last_event_at is not null and v_at < s.last_event_at then
    return jsonb_build_object('outcome', 'stale');
  end if;

  case v_type
    when 'INITIAL_PURCHASE', 'RENEWAL', 'PRODUCT_CHANGE', 'UNCANCELLATION', 'SUBSCRIPTION_EXTENDED', 'TEMPORARY_ENTITLEMENT_GRANT' then
      s.expires_at := coalesce(v_exp, s.expires_at);
      s.will_renew := true;
      s.grace_expires_at := v_grace;
      s.period_type := coalesce(v_period, s.period_type);
      s.has_history := true;
      s.trial_used := s.trial_used or coalesce(v_period, '') = 'TRIAL';
    when 'NON_RENEWING_PURCHASE' then
      s.expires_at := coalesce(v_exp, s.expires_at);
      s.will_renew := false;
      s.period_type := coalesce(v_period, s.period_type);
      s.has_history := true;
    when 'CANCELLATION' then
      s.will_renew := false;
      s.expires_at := coalesce(v_exp, s.expires_at);
      s.has_history := true;
    when 'SUBSCRIPTION_PAUSED' then
      s.will_renew := false;
      s.has_history := true;
    when 'BILLING_ISSUE' then
      s.grace_expires_at := v_grace;
      s.has_history := true;
    when 'EXPIRATION' then
      s.expires_at := coalesce(v_exp, v_at);
      s.will_renew := false;
      s.grace_expires_at := null;
      s.has_history := true;
    else
      -- TEST · SUBSCRIBER_ALIAS · TRANSFER · INVOICE_ISSUANCE … : stored only
      return jsonb_build_object('outcome', 'stored');
  end case;

  update public.subscription_state
  set expires_at = s.expires_at, grace_expires_at = s.grace_expires_at, period_type = s.period_type,
      will_renew = s.will_renew, trial_used = s.trial_used, has_history = s.has_history,
      last_event_at = v_at, updated_at = now()
  where user_id = v_user;
  select * into st from public.entitlement_status(v_user);
  update public.subscription_state set status = st.status where user_id = v_user;
  return jsonb_build_object('outcome', 'applied', 'status', st.status, 'entitled', st.entitled);
end $$;
revoke execute on function public.revenuecat_apply_event(jsonb) from public, anon, authenticated;
grant execute on function public.revenuecat_apply_event(jsonb) to service_role;
