-- S09d · purge_all(p_user, p_request_id): a client request id makes the purge
-- idempotent — the same id is replayed without a second purge or epoch bump,
-- a new id purges again, a null id keeps the legacy behaviour, and the served
-- id is readable on the profile (reconcile contract for a lost answer).
begin;
select plan(13);

insert into auth.users (id, email) values ('aaaaaaaa-0000-4000-8000-00000000000d', 'd@x.io');
insert into public.profiles (user_id, onboarding_done) values ('aaaaaaaa-0000-4000-8000-00000000000d', true);
insert into public.subjects (id, user_id, created_at, client_updated_at, device_id, server_seq, name, color_index)
  values ('70000000-0000-4000-8000-000000000001', 'aaaaaaaa-0000-4000-8000-00000000000d', '2026-10-01T00:00:00.000Z', '2026-10-01T00:00:00.000Z', 'dev-d',
          public.next_server_seq('aaaaaaaa-0000-4000-8000-00000000000d'), '수학', 1);

select has_column('public', 'profiles', 'purge_request_id', 'profiles.purge_request_id exists');
select is((select count(*) from pg_proc p join pg_namespace n on n.oid = p.pronamespace
           where n.nspname = 'public' and p.proname = 'purge_all'), 1::bigint,
  'one purge_all overload: (uuid, uuid default null) — the bare (uuid) call is the legacy path');

-- first request R1 ---------------------------------------------------------------------------------
select results_eq(
  $$select epoch, replayed from jsonb_to_record(public.purge_all('aaaaaaaa-0000-4000-8000-00000000000d', '90000000-0000-4000-8000-000000000001')) as x(epoch int, replayed bool)$$,
  $$values (1, false)$$, 'R1 → epoch 1, purged');
select is((select count(*) from public.subjects where user_id = 'aaaaaaaa-0000-4000-8000-00000000000d'), 0::bigint, 'R1 deleted the rows');
select is((select purge_request_id from public.profiles where user_id = 'aaaaaaaa-0000-4000-8000-00000000000d'),
  '90000000-0000-4000-8000-000000000001'::uuid, 'R1 remembered on the profile');

-- a row written after R1 (new epoch) then R1 again → replay: nothing deleted, epoch unchanged ------
insert into public.subjects (id, user_id, created_at, client_updated_at, device_id, server_seq, name, color_index, purge_epoch)
  values ('70000000-0000-4000-8000-000000000002', 'aaaaaaaa-0000-4000-8000-00000000000d', '2026-10-01T00:00:00.000Z', '2026-10-01T00:00:00.000Z', 'dev-d',
          public.next_server_seq('aaaaaaaa-0000-4000-8000-00000000000d'), '영어', 2, 1);
select results_eq(
  $$select epoch, replayed, jsonb_array_length(object_paths) from jsonb_to_record(public.purge_all('aaaaaaaa-0000-4000-8000-00000000000d', '90000000-0000-4000-8000-000000000001')) as x(epoch int, replayed bool, object_paths jsonb)$$,
  $$values (1, true, 0)$$, 'R1 again → replayed, epoch stays 1');
select is((select count(*) from public.subjects where user_id = 'aaaaaaaa-0000-4000-8000-00000000000d'), 1::bigint, 'replay deleted nothing');

-- a new id R2 purges again ---------------------------------------------------------------------------
select results_eq(
  $$select epoch, replayed from jsonb_to_record(public.purge_all('aaaaaaaa-0000-4000-8000-00000000000d', '90000000-0000-4000-8000-000000000002')) as x(epoch int, replayed bool)$$,
  $$values (2, false)$$, 'R2 → epoch 2, purged');
select is((select count(*) from public.subjects where user_id = 'aaaaaaaa-0000-4000-8000-00000000000d'), 0::bigint, 'R2 deleted the rows');
select is((select purge_request_id from public.profiles where user_id = 'aaaaaaaa-0000-4000-8000-00000000000d'),
  '90000000-0000-4000-8000-000000000002'::uuid, 'R2 is the served id now');
select results_eq(
  $$select epoch, replayed from jsonb_to_record(public.purge_all('aaaaaaaa-0000-4000-8000-00000000000d', '90000000-0000-4000-8000-000000000001')) as x(epoch int, replayed bool)$$,
  $$values (3, false)$$, 'an old id after a newer one is a new request, not a replay');

-- null id / bare (uuid) call: legacy, always purges, remembers nothing ---------------------------
select results_eq(
  $$select epoch, replayed from jsonb_to_record(public.purge_all('aaaaaaaa-0000-4000-8000-00000000000d')) as x(epoch int, replayed bool)$$,
  $$values (4, false)$$, 'bare (uuid) call → purged, epoch 4 (default null id)');
select is((select purge_request_id from public.profiles where user_id = 'aaaaaaaa-0000-4000-8000-00000000000d'), null, 'a null id clears the served id');

select * from finish();
rollback;
