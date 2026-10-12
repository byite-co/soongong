-- S09d · S09e · purge_all(p_user, p_request_id, p_expected_epoch): every handled
-- request leaves a receipt per (account, id) — a served id is replayed forever
-- (no second purge, no epoch bump, even after a newer request or a legacy
-- call ran in between: R1 → R2 → new row → R1), a request formed against an
-- older epoch is superseded (nothing deleted, recorded), a null id keeps the
-- legacy behaviour, the same id from another account is that account's own
-- request, and the receipts go with the account.
begin;
select plan(36);

insert into auth.users (id, email) values
  ('aaaaaaaa-0000-4000-8000-00000000000d', 'd@x.io'),
  ('aaaaaaaa-0000-4000-8000-00000000000f', 'f@x.io');
insert into public.profiles (user_id, onboarding_done) values
  ('aaaaaaaa-0000-4000-8000-00000000000d', true),
  ('aaaaaaaa-0000-4000-8000-00000000000f', true);
create or replace function pg_temp.row_at(p_id text, p_user uuid, p_epoch int) returns void language sql as $$
  insert into public.subjects (id, user_id, created_at, client_updated_at, device_id, server_seq, name, color_index, sort_order, is_default, purge_epoch)
  values (p_id, p_user, '2026-10-01T00:00:00.000Z', '2026-10-01T00:00:00.000Z', 'dev-d', public.next_server_seq(p_user), '과목', 1, 0, false, p_epoch)
$$;
create or replace function pg_temp.rows_of(p_user uuid) returns bigint language sql as $$
  select count(*) from public.subjects where user_id = p_user
$$;
create or replace function pg_temp.call(p_user uuid, p_id uuid, p_expected int) returns text language sql as $$
  select format('%s|%s|%s', r ->> 'epoch', r ->> 'replayed', r ->> 'superseded') from public.purge_all(p_user, p_id, p_expected) as r
$$;
select pg_temp.row_at('70000000-0000-4000-8000-000000000001', 'aaaaaaaa-0000-4000-8000-00000000000d', 0);

-- shape --------------------------------------------------------------------------------------------
select has_table('public', 'purge_receipts', 'purge_receipts exists');
select has_column('public', 'profiles', 'purge_request_id', 'profiles.purge_request_id still exists (informational)');
select is((select string_agg(pg_get_function_identity_arguments(p.oid), ';') from pg_proc p join pg_namespace n on n.oid = p.pronamespace
           where n.nspname = 'public' and p.proname = 'purge_all'),
  'p_user uuid, p_request_id uuid, p_expected_epoch integer', 'one purge_all overload: (uuid, uuid default null, int default null)');
select ok(not has_table_privilege('authenticated', 'public.purge_receipts', 'select')
          and not has_table_privilege('anon', 'public.purge_receipts', 'select'), 'purge_receipts is not readable by API roles');

-- R1 served, replayed ---------------------------------------------------------------------------------
select is(pg_temp.call('aaaaaaaa-0000-4000-8000-00000000000d', '90000000-0000-4000-8000-000000000001', 0), '1|false|false', 'R1 (expected 0) → epoch 1, purged');
select is(pg_temp.rows_of('aaaaaaaa-0000-4000-8000-00000000000d'), 0::bigint, 'R1 deleted the rows');
select results_eq($$select outcome, epoch from public.purge_receipts where user_id = 'aaaaaaaa-0000-4000-8000-00000000000d' and request_id = '90000000-0000-4000-8000-000000000001'$$,
  $$values ('served'::text, 1)$$, 'R1 has a served receipt at epoch 1');
select is((select purge_request_id from public.profiles where user_id = 'aaaaaaaa-0000-4000-8000-00000000000d'),
  '90000000-0000-4000-8000-000000000001'::uuid, 'R1 is the last served id on the profile');
select pg_temp.row_at('70000000-0000-4000-8000-000000000002', 'aaaaaaaa-0000-4000-8000-00000000000d', 1);
select is(pg_temp.call('aaaaaaaa-0000-4000-8000-00000000000d', '90000000-0000-4000-8000-000000000001', 0), '1|true|false', 'R1 again → replayed, epoch stays 1');
select is(jsonb_array_length(public.purge_all('aaaaaaaa-0000-4000-8000-00000000000d', '90000000-0000-4000-8000-000000000001', 0) -> 'object_paths'), 0, 'a replay returns no object paths');
select is(pg_temp.rows_of('aaaaaaaa-0000-4000-8000-00000000000d'), 1::bigint, 'the replay deleted nothing');

-- R2, then the delayed R1 (the S09e reproduction) -------------------------------------------------------
select is(pg_temp.call('aaaaaaaa-0000-4000-8000-00000000000d', '90000000-0000-4000-8000-000000000002', 1), '2|false|false', 'R2 (expected 1) → epoch 2, purged');
select is(pg_temp.rows_of('aaaaaaaa-0000-4000-8000-00000000000d'), 0::bigint, 'R2 deleted the epoch-1 row');
select pg_temp.row_at('70000000-0000-4000-8000-000000000003', 'aaaaaaaa-0000-4000-8000-00000000000d', 2);
select is(pg_temp.call('aaaaaaaa-0000-4000-8000-00000000000d', '90000000-0000-4000-8000-000000000001', 0), '2|true|false', 'delayed R1 after R2 → replayed with the CURRENT epoch 2, not a new purge');
select is(pg_temp.rows_of('aaaaaaaa-0000-4000-8000-00000000000d'), 1::bigint, 'the row written after R2 survives the delayed R1');
select is(pg_temp.call('aaaaaaaa-0000-4000-8000-00000000000d', '90000000-0000-4000-8000-000000000001', 0)
       || ' ' || pg_temp.call('aaaaaaaa-0000-4000-8000-00000000000d', '90000000-0000-4000-8000-000000000001', 0)
       || ' ' || pg_temp.call('aaaaaaaa-0000-4000-8000-00000000000d', '90000000-0000-4000-8000-000000000001', 0),
  '2|true|false 2|true|false 2|true|false', 'R1 re-sent three more times → the same answer every time');
select is(pg_temp.rows_of('aaaaaaaa-0000-4000-8000-00000000000d'), 1::bigint, 'repeated resends delete nothing');
select is((select purge_epoch from public.profiles where user_id = 'aaaaaaaa-0000-4000-8000-00000000000d'), 2, 'epoch stays 2 through the resends');
select is((select count(*) from public.purge_receipts where user_id = 'aaaaaaaa-0000-4000-8000-00000000000d'), 2::bigint, 'two receipts (R1 · R2), none added by replays');

-- legacy null-id call, then R1 again --------------------------------------------------------------------
select results_eq($$select epoch, replayed, superseded from jsonb_to_record(public.purge_all('aaaaaaaa-0000-4000-8000-00000000000d')) as x(epoch int, replayed bool, superseded bool)$$,
  $$values (3, false, false)$$, 'bare (uuid) call → purged, epoch 3 (legacy)');
select is(pg_temp.rows_of('aaaaaaaa-0000-4000-8000-00000000000d'), 0::bigint, 'the legacy call deleted the rows');
select is((select count(*) from public.purge_receipts where user_id = 'aaaaaaaa-0000-4000-8000-00000000000d'), 2::bigint, 'a null id leaves no receipt');
select is((select purge_request_id from public.profiles where user_id = 'aaaaaaaa-0000-4000-8000-00000000000d'),
  '90000000-0000-4000-8000-000000000002'::uuid, 'a null id keeps the last served id');
select pg_temp.row_at('70000000-0000-4000-8000-000000000004', 'aaaaaaaa-0000-4000-8000-00000000000d', 3);
select is(pg_temp.call('aaaaaaaa-0000-4000-8000-00000000000d', '90000000-0000-4000-8000-000000000001', 0), '3|true|false', 'R1 after the legacy call → still a replay (epoch 3)');
select is(pg_temp.rows_of('aaaaaaaa-0000-4000-8000-00000000000d'), 1::bigint, 'the row written after the legacy call survives');

-- a request formed against an older epoch is superseded, and stays so ------------------------------------
select is(pg_temp.call('aaaaaaaa-0000-4000-8000-00000000000d', '90000000-0000-4000-8000-000000000003', 1), '3|false|true', 'R3 (expected 1, current 3) → superseded, not executed');
select is(pg_temp.rows_of('aaaaaaaa-0000-4000-8000-00000000000d'), 1::bigint, 'a superseded request deletes nothing');
select results_eq($$select outcome, epoch from public.purge_receipts where user_id = 'aaaaaaaa-0000-4000-8000-00000000000d' and request_id = '90000000-0000-4000-8000-000000000003'$$,
  $$values ('superseded'::text, 3)$$, 'R3 has a superseded receipt');
select is(pg_temp.call('aaaaaaaa-0000-4000-8000-00000000000d', '90000000-0000-4000-8000-000000000003', 3), '3|true|true', 'R3 re-sent, even with a matching epoch → replay of the superseded receipt, never a new purge');
select results_eq($$select epoch, replayed, superseded from jsonb_to_record(public.purge_all('aaaaaaaa-0000-4000-8000-00000000000d', null, 1)) as x(epoch int, replayed bool, superseded bool)$$,
  $$values (3, false, true)$$, 'a null id with a stale expected epoch is superseded too (no receipt possible)');
select is(pg_temp.rows_of('aaaaaaaa-0000-4000-8000-00000000000d'), 1::bigint, 'still nothing deleted');

-- the same id from another account is that account''s own request ---------------------------------------
select pg_temp.row_at('70000000-0000-4000-8000-0000000000f1', 'aaaaaaaa-0000-4000-8000-00000000000f', 0);
select is(pg_temp.call('aaaaaaaa-0000-4000-8000-00000000000f', '90000000-0000-4000-8000-000000000001', 0), '1|false|false', 'account F sends R1 (same uuid) → F''s own purge, epoch 1');
select is(pg_temp.rows_of('aaaaaaaa-0000-4000-8000-00000000000d') || '/' || pg_temp.rows_of('aaaaaaaa-0000-4000-8000-00000000000f'), '1/0', 'only F''s rows went; D''s row stays');
select is(pg_temp.call('aaaaaaaa-0000-4000-8000-00000000000d', '90000000-0000-4000-8000-000000000001', 0), '3|true|false', 'D''s R1 is still D''s replay');

-- unknown account · receipts go with the account -----------------------------------------------------------
select throws_ok($$select public.purge_all('aaaaaaaa-0000-4000-8000-0000000000ee', '90000000-0000-4000-8000-000000000009', 0)$$, 'P0001', 'no_profile', 'no profile → no_profile');
delete from auth.users where id = 'aaaaaaaa-0000-4000-8000-00000000000f';
select is((select count(*) from public.purge_receipts where user_id = 'aaaaaaaa-0000-4000-8000-00000000000f'), 0::bigint, 'F''s receipts went with the account (cascade)');

select * from finish();
rollback;
