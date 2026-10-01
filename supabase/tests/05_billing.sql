-- pgTAP · D18 webhook ledger — the 8 fixtures of supabase/tests/fixtures/revenuecat
-- replayed in order (same JSON), plus dedupe / stale / unlinked / decision table.
-- Clock: events are in Oct–Dec 2026; entitlement_status() uses now(), so the
-- expected statuses below are asserted via the decision table on a state row
-- with controlled timestamps (section B), and section A checks the ledger fields.
begin;
select plan(28);

insert into auth.users (id, email) values ('aaaaaaaa-0000-4000-8000-000000000001', 'u1@test.local');
insert into public.profiles (user_id) values ('aaaaaaaa-0000-4000-8000-000000000001');
set local role service_role;

create or replace function pg_temp.ev(p_id text, p_type text, p_period text, p_ts bigint, p_exp bigint, p_grace bigint, p_conv boolean default null)
returns jsonb language sql as $$
  select jsonb_build_object('api_version', '1.0', 'event', jsonb_strip_nulls(jsonb_build_object(
    'id', p_id, 'type', p_type, 'app_user_id', 'aaaaaaaa-0000-4000-8000-000000000001', 'product_id', 'soongong_monthly',
    'period_type', p_period, 'event_timestamp_ms', p_ts, 'expiration_at_ms', p_exp, 'grace_period_expiration_at_ms', p_grace,
    'is_trial_conversion', p_conv, 'store', 'APP_STORE', 'environment', 'SANDBOX')))
$$;
grant execute on function pg_temp.ev(text, text, text, bigint, bigint, bigint, boolean) to service_role;
create or replace function pg_temp.state() returns table (expires_at timestamptz, grace timestamptz, will_renew boolean, trial_used boolean, period_type text, has_history boolean) language sql as $$
  select expires_at, grace_expires_at, will_renew, trial_used, period_type::text, has_history from public.subscription_state where user_id = 'aaaaaaaa-0000-4000-8000-000000000001'
$$;
grant execute on function pg_temp.state() to service_role;

-- A. fixtures 01–08 in order -------------------------------------------------------------------
select is(public.revenuecat_apply_event(pg_temp.ev('evt-0001', 'INITIAL_PURCHASE', 'TRIAL', 1759276800000, 1759881600000, null, false)) ->> 'outcome', 'applied', '01 INITIAL_PURCHASE/TRIAL applied');
select results_eq($$select will_renew, trial_used, period_type, has_history from pg_temp.state()$$, $$values (true, true, 'TRIAL'::text, true)$$, '01 trial_used · will_renew · history');
select is(public.revenuecat_apply_event(pg_temp.ev('evt-0001', 'INITIAL_PURCHASE', 'TRIAL', 1759276800000, 1759881600000, null, false)) ->> 'outcome', 'duplicate', '01 same event_id again → duplicate');
select is((select count(*) from public.subscription_events), 1::bigint, 'duplicate not stored twice');

select is(public.revenuecat_apply_event(pg_temp.ev('evt-0002', 'RENEWAL', 'NORMAL', 1759881600000, 1762560000000, null, true)) ->> 'outcome', 'applied', '02 RENEWAL (trial conversion)');
select results_eq($$select period_type, expires_at = to_timestamp(1762560000), will_renew from pg_temp.state()$$, $$values ('NORMAL'::text, true, true)$$, '02 period NORMAL · expires_at moved');
select is((select is_trial_conversion from public.subscription_events where event_id = 'evt-0002'), true, '02 is_trial_conversion stored (D15 G4)');

select is(public.revenuecat_apply_event(pg_temp.ev('evt-0003', 'CANCELLATION', 'NORMAL', 1760486400000, 1762560000000, null)) ->> 'outcome', 'applied', '03 CANCELLATION');
select results_eq($$select will_renew, expires_at = to_timestamp(1762560000) from pg_temp.state()$$, $$values (false, true)$$, '03 will_renew false, expires_at kept (cancelPending while period remains)');

select is(public.revenuecat_apply_event(pg_temp.ev('evt-0004', 'UNCANCELLATION', 'NORMAL', 1760572800000, 1762560000000, null)) ->> 'outcome', 'applied', '04 UNCANCELLATION');
select results_eq($$select will_renew from pg_temp.state()$$, $$values (true)$$, '04 will_renew back to true');

select is(public.revenuecat_apply_event(pg_temp.ev('evt-0006', 'BILLING_ISSUE', 'NORMAL', 1761955200000, 1762560000000, null)) ->> 'outcome', 'applied', '06 BILLING_ISSUE with grace null (period remaining)');
select results_eq($$select grace is null, expires_at = to_timestamp(1762560000), will_renew from pg_temp.state()$$, $$values (true, true, true)$$, '06 grace stays null, expires_at untouched → still entitled until expires_at');

select is(public.revenuecat_apply_event(pg_temp.ev('evt-0005', 'BILLING_ISSUE', 'NORMAL', 1762560000000, 1762560000000, 1763942400000)) ->> 'outcome', 'applied', '05 BILLING_ISSUE with grace');
select results_eq($$select grace = to_timestamp(1763942400) from pg_temp.state()$$, $$values (true)$$, '05 grace_expires_at set');

-- stale: an older event arriving late does not move the state
select is(public.revenuecat_apply_event(pg_temp.ev('evt-0003b', 'CANCELLATION', 'NORMAL', 1760486400001, 1762560000000, null)) ->> 'outcome', 'stale', 'older event_timestamp → stale (stored, state untouched)');
select results_eq($$select will_renew from pg_temp.state()$$, $$values (true)$$, 'stale event did not flip will_renew');

select is(public.revenuecat_apply_event(pg_temp.ev('evt-0007', 'EXPIRATION', 'NORMAL', 1763942400000, 1763942400000, null)) ->> 'outcome', 'applied', '07 EXPIRATION');
select results_eq($$select will_renew, grace is null, expires_at = to_timestamp(1763942400) from pg_temp.state()$$, $$values (false, true, true)$$, '07 will_renew false · grace cleared');

select is(public.revenuecat_apply_event(pg_temp.ev('evt-0008', 'INITIAL_PURCHASE', 'NORMAL', 1764547200000, 1767139200000, null, false)) ->> 'outcome', 'applied', '08 INITIAL_PURCHASE/NORMAL (direct paid)');
select results_eq($$select will_renew, period_type, trial_used from pg_temp.state()$$, $$values (true, 'NORMAL'::text, true)$$, '08 renewing · trial_used stays true');

-- unlinked / TEST events
select is(public.revenuecat_apply_event('{"event":{"id":"evt-anon","type":"INITIAL_PURCHASE","app_user_id":"$RCAnonymousID:abc","event_timestamp_ms":1764547200000}}'::jsonb) ->> 'outcome', 'stored_unlinked', 'anonymous app_user_id → stored_unlinked');
select is(public.revenuecat_apply_event(pg_temp.ev('evt-test', 'TEST', null, 1764547300000, null, null)) ->> 'outcome', 'stored', 'TEST event stored only');

-- B. decision table against now() ---------------------------------------------------------------------
update public.subscription_state set expires_at = now() + interval '10 days', will_renew = true, period_type = 'TRIAL', grace_expires_at = null where user_id = 'aaaaaaaa-0000-4000-8000-000000000001';
select results_eq($$select status, entitled from public.entitlement_status('aaaaaaaa-0000-4000-8000-000000000001')$$, $$values ('trial'::text, true)$$, 'D18: trial');
update public.subscription_state set period_type = 'NORMAL' where user_id = 'aaaaaaaa-0000-4000-8000-000000000001';
select results_eq($$select status, entitled from public.entitlement_status('aaaaaaaa-0000-4000-8000-000000000001')$$, $$values ('premium'::text, true)$$, 'D18: premium');
update public.subscription_state set will_renew = false where user_id = 'aaaaaaaa-0000-4000-8000-000000000001';
select results_eq($$select status, entitled from public.entitlement_status('aaaaaaaa-0000-4000-8000-000000000001')$$, $$values ('cancelPending'::text, true)$$, 'D18: cancelPending');
update public.subscription_state set expires_at = now() - interval '1 day', grace_expires_at = now() + interval '5 days' where user_id = 'aaaaaaaa-0000-4000-8000-000000000001';
select results_eq($$select status, entitled from public.entitlement_status('aaaaaaaa-0000-4000-8000-000000000001')$$, $$values ('grace'::text, true)$$, 'D18: grace');
update public.subscription_state set grace_expires_at = null where user_id = 'aaaaaaaa-0000-4000-8000-000000000001';
select results_eq($$select status, entitled from public.entitlement_status('aaaaaaaa-0000-4000-8000-000000000001')$$, $$values ('expired'::text, false)$$, 'D18: expired (history, nothing active)');

select * from finish();
rollback;
