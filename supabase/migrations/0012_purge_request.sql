-- =============================================================================
-- S09d · 0012_purge_request.sql
--
-- 모든 기록 삭제 with a client request id (D2 epoch · [S09d]):
--   purge_all(p_user, p_request_id)
--     · p_request_id = profiles.purge_request_id (the last request this
--       account's purge served) → REPLAY: nothing is deleted, the epoch stays,
--       {epoch, object_paths: [], replayed: true} is returned. A client whose
--       connection died before the answer re-sends the SAME id and converges
--       without a second purge / epoch bump.
--     · otherwise → purge as before (cancel active readings, delete sync
--       rows + receipts, epoch + 1) and remember the id.
--     · p_request_id null → legacy behaviour (always purges; nothing remembered).
--   profiles.purge_request_id is readable by the owner through the normal
--   profile select, so a client that lost the answer can tell "served" (id
--   matches) from "never reached the server" (id absent · epoch unchanged).
--
-- D27: new file only; the (uuid) signature is dropped — the Edge Function is
-- the only caller and passes two arguments. Tests: tests/10_purge_request.sql.
-- =============================================================================

alter table public.profiles add column if not exists purge_request_id uuid;

drop function if exists public.purge_all(uuid);

create or replace function public.purge_all(p_user uuid, p_request_id uuid default null)
returns jsonb language plpgsql security definer
set search_path = public, pg_temp
as $$
declare rec record; v_fin jsonb; v_paths jsonb := '[]'::jsonb; v_epoch int; v_last uuid; t text;
begin
  perform public.user_lock(p_user);
  select purge_epoch, purge_request_id into v_epoch, v_last from public.profiles where user_id = p_user;
  if not found then
    raise exception 'no_profile' using errcode = 'P0001';
  end if;
  if p_request_id is not null and v_last is not distinct from p_request_id then
    return jsonb_build_object('epoch', v_epoch, 'object_paths', '[]'::jsonb, 'replayed', true);
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
     set purge_epoch = purge_epoch + 1, purge_request_id = p_request_id
   where user_id = p_user
   returning purge_epoch into v_epoch;
  return jsonb_build_object('epoch', v_epoch, 'object_paths', v_paths, 'replayed', false);
end $$;

revoke execute on function public.purge_all(uuid, uuid) from public, anon, authenticated;
grant execute on function public.purge_all(uuid, uuid) to service_role;
