-- =============================================================================
-- S03 · 0002_permissions.sql — D24 permission boundary
--
--   * default privileges: functions created by the migration role (postgres)
--     get NO EXECUTE for PUBLIC / anon / authenticated — globally AND for
--     schema public (schema-only would leave the global PUBLIC EXECUTE).
--   * tables: anon/authenticated/service_role lose the Supabase default table
--     grants; users get SELECT only on their own rows through RLS (and only
--     while a `profiles` row exists). No insert/update/delete policies —
--     every write goes through a security definer RPC / Edge function.
--   * ledger tables: `subscription_state` · `reading_quota` select-only;
--     everything else RLS on + no user policy (service_role bypasses RLS).
--   * functions created in 0001 are revoked per signature here; later
--     migrations revoke/grant each function right after creating it.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. default privileges for the migration role
-- ---------------------------------------------------------------------------
alter default privileges for role postgres revoke execute on functions from public, anon, authenticated;
alter default privileges for role postgres in schema public revoke execute on functions from public, anon, authenticated;
alter default privileges for role postgres in schema public revoke all on tables from anon, authenticated;
alter default privileges for role postgres in schema public revoke all on sequences from anon, authenticated;

-- Existing (Supabase default) table grants on the S03 tables → remove.
do $$
declare t text;
begin
  foreach t in array array[
    'subjects','sessions','session_segments','corrections','planner_items','recurrences',
    'reading_requests','wrong_items','review_entries','retry_records','settings','activity_days',
    'sync_tables','allowed_columns','profiles','signup_passes','signup_approvals','user_seq',
    'sync_mutations','subscription_state','subscription_events','reading_quota','reading_jobs',
    'photo_delete_queue','review_due_snapshots','metrics_weekly','inquiries','server_config']
  loop
    execute format('revoke all on table public.%I from public, anon, authenticated', t);
    execute format('alter table public.%I enable row level security', t);
  end loop;
end $$;
revoke all on sequence public.photo_delete_queue_id_seq from public, anon, authenticated;

-- ---------------------------------------------------------------------------
-- 2. user-visible tables: SELECT own rows, only with a profile (D6 backstop)
-- ---------------------------------------------------------------------------
create or replace function public.has_profile()
returns boolean language sql stable security definer
set search_path = public, pg_temp
as $$ select exists (select 1 from public.profiles p where p.user_id = auth.uid()) $$;
revoke execute on function public.has_profile() from public, anon, authenticated, service_role;
grant execute on function public.has_profile() to authenticated;

do $$
declare t text;
begin
  foreach t in array array[
    'subjects','sessions','session_segments','corrections','planner_items','recurrences',
    'reading_requests','wrong_items','review_entries','retry_records','settings','activity_days',
    'subscription_state','reading_quota','profiles']
  loop
    execute format('grant select on table public.%I to authenticated', t);
    execute format(
      'create policy %I on public.%I for select to authenticated using (user_id = auth.uid() and public.has_profile())',
      t || '_select_own', t);
  end loop;
end $$;

-- ---------------------------------------------------------------------------
-- 3. functions created in 0001 — revoke per signature (D24)
-- ---------------------------------------------------------------------------
revoke execute on function public.iso_utc(timestamptz)        from public, anon, authenticated;
revoke execute on function public.ts(text)                    from public, anon, authenticated;
revoke execute on function public.kst_month(timestamptz)      from public, anon, authenticated;
revoke execute on function public.kst_week_start(timestamptz) from public, anon, authenticated;
revoke execute on function public.next_server_seq(uuid)       from public, anon, authenticated, service_role;
revoke execute on function public.user_lock(uuid)             from public, anon, authenticated, service_role;
revoke execute on function public.server_config_get(text)     from public, anon, authenticated, service_role;
revoke execute on function public.invoke_edge(text, jsonb)    from public, anon, authenticated, service_role;

-- ---------------------------------------------------------------------------
-- 4. auth hook / trigger role
-- ---------------------------------------------------------------------------
grant usage on schema public to supabase_auth_admin;
