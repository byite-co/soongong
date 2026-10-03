-- =============================================================================
-- S03 · 0008_cron.sql — pg_cron schedules + pg_net
--
-- Times are UTC (pg_cron). Monday 00:00 KST = Sunday 15:00 UTC.
-- Edge job functions are reached through invoke_edge() (pg_net) and need
-- server_config.functions_base_url + job_secret; until those are set the
-- SQL-side jobs still run and the Edge calls are skipped (worker/photo runner
-- then wait for the next configured sweep). prod registration: S15 cutover.
-- =============================================================================
create extension if not exists pg_cron;
do $$
begin
  if exists (select 1 from pg_available_extensions where name = 'pg_net') then
    create extension if not exists pg_net;
  end if;
end $$;

create or replace function public.cron_upsert(p_name text, p_schedule text, p_command text)
returns void language plpgsql security definer
set search_path = public, pg_temp
as $$
begin
  if exists (select 1 from cron.job where jobname = p_name) then
    perform cron.unschedule(p_name);
  end if;
  perform cron.schedule(p_name, p_schedule, p_command);
end $$;
revoke execute on function public.cron_upsert(text, text, text) from public, anon, authenticated, service_role;

select public.cron_upsert('soongong-reading-reaper', '* * * * *',
  $$select public.reading_reaper_run();$$);

select public.cron_upsert('soongong-reading-worker-sweep', '* * * * *',
  $$select public.invoke_edge('reading-worker', '{"source":"cron"}'::jsonb)
    where exists (select 1 from public.reading_jobs
                  where (lease_until is null or lease_until <= now()) and deadline > now() and attempts < 2);$$);

select public.cron_upsert('soongong-photo-delete-runner', '*/5 * * * *',
  $$select public.invoke_edge('photo-delete-runner', '{"source":"cron"}'::jsonb)
    where exists (select 1 from public.photo_delete_queue where status = 'pending' and next_at <= now());$$);

-- 00:30 KST daily: reading_expire · orphan drafts · retention
select public.cron_upsert('soongong-daily-maintenance', '30 15 * * *',
  $$select public.daily_maintenance_run();$$);

-- Monday 00:00 KST: freeze this week's review due set
select public.cron_upsert('soongong-review-due-snapshot', '0 15 * * 0',
  $$select public.review_due_snapshot_run(null);$$);

-- Monday 01:00 KST: previous week's metrics
select public.cron_upsert('soongong-metrics-weekly', '0 16 * * 0',
  $$select public.metrics_run(null);$$);
