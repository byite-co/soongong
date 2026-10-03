-- pgTAP · D6 signup gate: hook (check only), identities trigger (consume +
-- approve, backstop, linking, dev failure injection), complete-signup,
-- consent, onboarding RPC, inquiries.
begin;
select plan(33);

-- hook ---------------------------------------------------------------------------------
select is(public.before_user_created_hook('{"user":{"email":"new@x.io","app_metadata":{"provider":"email"}}}'::jsonb) -> 'error' ->> 'http_code',
  '400', 'hook: no pass → 400');
select is(public.before_user_created_hook('{"user":{"email":"new@x.io","app_metadata":{"provider":"email"}}}'::jsonb) -> 'error' ->> 'message',
  '가입 확인이 필요합니다', 'hook: rejection message');
set local role service_role;
select is(public.signup_pass_upsert('email', 'New@X.io', 600) ? 'expires_at', true, 'issue-pass: email pass upserted (case-insensitive)');
select public.signup_pass_upsert('google', 'g-sub-1', 600);
reset role;
select is(public.before_user_created_hook('{"user":{"email":"NEW@x.io","app_metadata":{"provider":"email"}}}'::jsonb), '{}'::jsonb, 'hook: email pass found → allow');
select is(public.before_user_created_hook('{"user":{"email":"g@x.io","app_metadata":{"provider":"google","providers":["google"]},"user_metadata":{"sub":"g-sub-1","provider_id":"g-sub-1","email":"g@x.io"}}}'::jsonb), '{}'::jsonb,
  'hook: social pass by user_metadata.sub → allow');
select is(public.before_user_created_hook('{"user":{"email":"g@x.io","app_metadata":{"provider":"google"},"user_metadata":{"provider_id":"g-sub-1"}}}'::jsonb), '{}'::jsonb,
  'hook: social fallback to user_metadata.provider_id');
select is(public.before_user_created_hook('{"user":{"email":"g@x.io","app_metadata":{"provider":"google"},"user_metadata":{}}}'::jsonb) -> 'error' ->> 'http_code', '400',
  'hook: social without sub → reject');
select is((select count(*) from public.signup_passes), 2::bigint, 'hook wrote nothing (passes untouched)');

-- trigger: backstop ---------------------------------------------------------------------------
select throws_ok($$
  with u as (insert into auth.users (id, email) values ('bbbbbbbb-0000-4000-8000-000000000001', 'nopass@x.io') returning id)
  insert into auth.identities (provider_id, user_id, identity_data, provider)
  select 'bbbbbbbb-0000-4000-8000-000000000001', id, '{"sub":"bbbbbbbb-0000-4000-8000-000000000001","email":"nopass@x.io"}', 'email' from u$$,
  'P0001', 'signup_pass_required', 'trigger: identity without pass → signup_pass_required');
select is((select count(*) from auth.users where email = 'nopass@x.io'), 0::bigint, 'trigger: user insert rolled back with the identity');

-- trigger: consume + approve --------------------------------------------------------------------
insert into auth.users (id, email) values ('bbbbbbbb-0000-4000-8000-000000000002', 'new@x.io');
insert into auth.identities (provider_id, user_id, identity_data, provider)
values ('bbbbbbbb-0000-4000-8000-000000000002', 'bbbbbbbb-0000-4000-8000-000000000002', '{"sub":"bbbbbbbb-0000-4000-8000-000000000002","email":"new@x.io"}', 'email');
select results_eq($$select provider::text, age_verified from public.signup_approvals where user_id = 'bbbbbbbb-0000-4000-8000-000000000002'$$,
  $$values ('email'::text, true)$$, 'trigger: approval inserted with the real user_id');
select is((select count(*) from public.signup_passes where provider = 'email'), 0::bigint, 'trigger: pass consumed (deleted)');

-- trigger: linking an identity to an approved user needs no pass ---------------------------------------
insert into auth.identities (provider_id, user_id, identity_data, provider)
values ('apple-sub-9', 'bbbbbbbb-0000-4000-8000-000000000002', '{"sub":"apple-sub-9","email":"new@x.io"}', 'apple');
select is((select count(*) from public.signup_approvals where user_id = 'bbbbbbbb-0000-4000-8000-000000000002'), 1::bigint, 'linking: still exactly one approval');
select is((select count(*) from public.signup_passes), 1::bigint, 'linking: no pass consumed (google pass still there)');

-- trigger: expired pass does not count --------------------------------------------------------------------
update public.signup_passes set expires_at = now() - interval '1 second' where provider = 'google';
select throws_ok($$
  with u as (insert into auth.users (id, email) values ('bbbbbbbb-0000-4000-8000-000000000003', 'g@x.io') returning id)
  insert into auth.identities (provider_id, user_id, identity_data, provider)
  select 'g-sub-1', id, '{"sub":"g-sub-1","email":"g@x.io"}', 'google' from u$$,
  'P0001', 'signup_pass_required', 'trigger: expired pass → signup_pass_required');
update public.signup_passes set expires_at = now() + interval '10 minutes' where provider = 'google';

-- dev-only failure injection (supabase/dev/0001): consumed → RAISE → everything rolls back, pass stays
select set_config('app.test_trigger_fail', 'on', true);
select throws_ok($$
  with u as (insert into auth.users (id, email) values ('bbbbbbbb-0000-4000-8000-000000000003', 'g@x.io') returning id)
  insert into auth.identities (provider_id, user_id, identity_data, provider)
  select 'g-sub-1', id, '{"sub":"g-sub-1","email":"g@x.io"}', 'google' from u$$,
  'P0001', 'test_trigger_fail', 'dev: trigger fails after consumption');
select is((select count(*) from auth.users where email = 'g@x.io'), 0::bigint, 'dev: user not created');
select is((select count(*) from public.signup_approvals where provider = 'google'), 0::bigint, 'dev: no approval');
select is((select count(*) from public.signup_passes where provider = 'google'), 1::bigint, 'dev: pass remains (statement rolled back)');
select set_config('app.test_trigger_fail', 'off', true);

-- social signup succeeds with the pass
insert into auth.users (id, email) values ('bbbbbbbb-0000-4000-8000-000000000003', 'g@x.io');
insert into auth.identities (provider_id, user_id, identity_data, provider)
values ('g-sub-1', 'bbbbbbbb-0000-4000-8000-000000000003', '{"sub":"g-sub-1","email":"g@x.io"}', 'google');
select results_eq($$select provider::text from public.signup_approvals where user_id = 'bbbbbbbb-0000-4000-8000-000000000003'$$, $$values ('google'::text)$$, 'social signup approved');

-- complete-signup / consent / onboarding ---------------------------------------------------------------------
set local role service_role;
select throws_ok($$select public.complete_signup('bbbbbbbb-0000-4000-8000-000000000009', 'a1')$$, 'P0001', 'not_approved', 'complete-signup without approval → not_approved');
select is(public.complete_signup('bbbbbbbb-0000-4000-8000-000000000002', 'a1') ->> 'consent_account_version', 'a1', 'complete-signup creates the profile with consent ①');
select is(public.complete_signup('bbbbbbbb-0000-4000-8000-000000000002', 'a1') ->> 'consent_account_version', 'a1', 'complete-signup is idempotent');
select is((select count(*) from public.profiles where user_id = 'bbbbbbbb-0000-4000-8000-000000000002'), 1::bigint, 'exactly one profile');
select is(public.update_consent('bbbbbbbb-0000-4000-8000-000000000002', 'r1', true) ->> 'consent_reading_active', 'true', 'consent ② granted');
select is(public.update_consent('bbbbbbbb-0000-4000-8000-000000000002', 'r1', false) ->> 'consent_reading_active', 'false', 'consent ② revoked');
select is(public.auth_email_exists('NEW@x.io'), true, 'check-email: existing (case-insensitive)');
select is(public.auth_email_exists('nobody@x.io'), false, 'check-email: missing');
reset role;
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"bbbbbbbb-0000-4000-8000-000000000002","role":"authenticated"}', true);
select is(public.profile_set_onboarding_done() ->> 'onboarding_done', 'true', 'profile_set_onboarding_done() as the user');
reset role;

-- inquiries ---------------------------------------------------------------------------------------------------------
set local role service_role;
select is(jsonb_typeof(public.submit_inquiry('bbbbbbbb-0000-4000-8000-000000000002', '문의합니다', 'me@x.io') -> 'id'), 'string', 'inquiry stored');
select throws_ok($$select public.submit_inquiry('bbbbbbbb-0000-4000-8000-000000000002', repeat('a', 2001), null)$$, 'P0001', 'invalid_body', 'inquiry > 2000 chars refused');
select lives_ok($$select public.submit_inquiry('bbbbbbbb-0000-4000-8000-000000000002', 'x', null) from generate_series(1, 9)$$, 'inquiries up to 10 a day');
select throws_ok($$select public.submit_inquiry('bbbbbbbb-0000-4000-8000-000000000002', '11th', null)$$, 'P0001', 'rate_limited', '11th inquiry of the day refused');
reset role;

select * from finish();
rollback;
