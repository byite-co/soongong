-- =============================================================================
-- S09e · 0013_purge_receipts.sql
--
-- 모든 기록 삭제 request receipts ([S09e], after the GPT re-review of [S09d]).
-- 0012 remembered ONE id per account (profiles.purge_request_id), so a served
-- request that arrived again after a newer one (R1 → R2 → R1) was taken for a
-- new purge: the rows written under the new epoch were deleted and the epoch
-- rose again. Now every handled request leaves a receipt keyed by
-- (account, request id), kept for the account's lifetime:
--
--   purge_all(p_user, p_request_id default null, p_expected_epoch default null)
--     · a receipt exists for (p_user, p_request_id) → REPLAY: nothing is
--       deleted, the epoch stays, {epoch: <current>, replayed: true,
--       superseded: <the receipt's outcome>}. The answer carries the account's
--       CURRENT epoch so a client converges forward, never back to the epoch
--       the request saw.
--     · p_expected_epoch given and ≠ the current epoch → the request was
--       formed against an older generation (another purge ran after the
--       client read the profile): nothing is deleted, a 'superseded' receipt
--       is written so a later resend answers the same way,
--       {epoch: <current>, replayed: false, superseded: true}.
--     · otherwise → purge (cancel active readings, delete sync rows +
--       receipts, epoch + 1), a 'served' receipt, {epoch: <new>, replayed:
--       false, superseded: false}. profiles.purge_request_id keeps the last
--       served id (informational only; the receipts are the contract).
--     · p_request_id null → legacy behaviour: purges (when the expected
--       epoch, if given, matches), no receipt, the last served id stays.
--   Receipts are never pruned — a pruned id could be reborn as a new purge —
--   and go with the account (auth.users cascade · delete_account_data). A
--   request id is scoped by account: the same uuid sent by another account is
--   that account's own request. Service functions (security definer) are the
--   only readers and writers: RLS enabled, no policies, no API-role grants.
--
-- Deployment: an environment that already ran 0012 gets the table, the
-- backfill (the remembered last id becomes a 'served' receipt at the current
-- epoch) and the new signature in this one file; a fresh environment runs
-- 0012 then 0013. The (uuid, uuid) signature is dropped — the Edge Function is
-- the only caller and now passes three arguments; a bare (uuid) call still
-- resolves through the defaults. Tests: tests/10_purge_request.sql ·
-- tests/11_purge_concurrency.sql.
-- =============================================================================

create table if not exists public.purge_receipts (
  user_id    uuid not null references auth.users(id) on delete cascade,
  request_id uuid not null,
  outcome    text not null check (outcome in ('served', 'superseded')),
  epoch      int  not null,
  created_at timestamptz not null default now(),
  primary key (user_id, request_id)
);
revoke all on table public.purge_receipts from public, anon, authenticated;
alter table public.purge_receipts enable row level security;

-- backfill: what 0012 remembered was served (at some epoch ≤ the current one)
insert into public.purge_receipts (user_id, request_id, outcome, epoch)
select user_id, purge_request_id, 'served', purge_epoch
  from public.profiles
 where purge_request_id is not null
on conflict (user_id, request_id) do nothing;

drop function if exists public.purge_all(uuid, uuid);

create or replace function public.purge_all(p_user uuid, p_request_id uuid default null, p_expected_epoch int default null)
returns jsonb language plpgsql security definer
set search_path = public, pg_temp
as $$
declare rec record; v_fin jsonb; v_paths jsonb := '[]'::jsonb; v_epoch int; v_outcome text; t text;
begin
  perform public.user_lock(p_user);
  select purge_epoch into v_epoch from public.profiles where user_id = p_user;
  if not found then
    raise exception 'no_profile' using errcode = 'P0001';
  end if;
  if p_request_id is not null then
    select outcome into v_outcome from public.purge_receipts where user_id = p_user and request_id = p_request_id;
    if found then
      return jsonb_build_object('epoch', v_epoch, 'object_paths', '[]'::jsonb, 'replayed', true, 'superseded', v_outcome = 'superseded');
    end if;
  end if;
  if p_expected_epoch is not null and p_expected_epoch <> v_epoch then
    if p_request_id is not null then
      insert into public.purge_receipts (user_id, request_id, outcome, epoch) values (p_user, p_request_id, 'superseded', v_epoch);
    end if;
    return jsonb_build_object('epoch', v_epoch, 'object_paths', '[]'::jsonb, 'replayed', false, 'superseded', true);
  end if;
  for rec in select request_id from public.reading_requests
             where user_id = p_user and deleted_at is null and status in ('processing','taking_long') loop
    v_fin := public.reading_finish(p_user, rec.request_id, 'cancelled', null, 'purge');
    v_paths := v_paths || coalesce(v_fin -> 'object_paths', '[]'::jsonb);
  end loop;
  -- pending queue rows of this user stay (the runner needs them); jobs of finished requests are gone.
  for t in select table_name from public.sync_tables loop
    execute format('delete from public.%I where user_id = $1', t) using p_user;
  end loop;
  delete from public.sync_mutations where user_id = p_user;
  update public.profiles
     set purge_epoch = purge_epoch + 1, purge_request_id = coalesce(p_request_id, purge_request_id)
   where user_id = p_user
   returning purge_epoch into v_epoch;
  if p_request_id is not null then
    insert into public.purge_receipts (user_id, request_id, outcome, epoch) values (p_user, p_request_id, 'served', v_epoch);
  end if;
  return jsonb_build_object('epoch', v_epoch, 'object_paths', v_paths, 'replayed', false, 'superseded', false);
end $$;

revoke execute on function public.purge_all(uuid, uuid, int) from public, anon, authenticated;
grant execute on function public.purge_all(uuid, uuid, int) to service_role;

-- account deletion removes the receipts with everything else (0010 body + one line)
create or replace function public.delete_account_data(p_user uuid)
returns jsonb language plpgsql security definer
set search_path = public, pg_temp
as $$
declare rec record; v_fin jsonb; v_paths jsonb := '[]'::jsonb; t text;
begin
  perform public.user_lock(p_user);
  for rec in select request_id from public.reading_requests
             where user_id = p_user and deleted_at is null and status in ('processing','taking_long') loop
    v_fin := public.reading_finish(p_user, rec.request_id, 'cancelled', null, 'account_deleted');
    v_paths := v_paths || coalesce(v_fin -> 'object_paths', '[]'::jsonb);
  end loop;
  select v_paths || coalesce(jsonb_agg(bucket_path), '[]'::jsonb) into v_paths
  from public.photo_delete_queue where user_id = p_user and status = 'pending';
  for t in select table_name from public.sync_tables loop
    execute format('delete from public.%I where user_id = $1', t) using p_user;
  end loop;
  delete from public.sync_mutations where user_id = p_user;
  delete from public.reading_jobs where user_id = p_user;
  delete from public.reading_quota where user_id = p_user;
  delete from public.subscription_events where user_id = p_user;
  delete from public.subscription_state where user_id = p_user;
  delete from public.review_due_snapshots where user_id = p_user;
  delete from public.inquiries where user_id = p_user;
  delete from public.signup_approvals where user_id = p_user;
  delete from public.purge_receipts where user_id = p_user;
  delete from public.profiles where user_id = p_user;
  delete from public.user_seq where user_id = p_user;
  return jsonb_build_object('object_paths', v_paths);
end $$;
revoke execute on function public.delete_account_data(uuid) from public, anon, authenticated;
grant execute on function public.delete_account_data(uuid) to service_role;
