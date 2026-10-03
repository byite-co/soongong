-- =============================================================================
-- S03 · 0007_metrics_jobs.sql — D15 aggregation + D14 retention jobs
--
--   review_due_snapshot_run(week)  Monday 00:00 KST: freeze the week's due set
--   metrics_run(week)              Monday 01:00 KST: D15 formulas → metrics_weekly (upsert, idempotent)
--   draft_orphan_tombstone_run()   daily: unsubmitted drafts idle 30 days → tombstone
--   reading_expire_run()           daily (0005)
--   retention_run()                daily: 1y / 90d·180d / 7d / expired passes
--   daily_maintenance_run()        the three daily jobs in one cron command
-- metrics_weekly is anonymous aggregate (service_role only), never per user.
-- =============================================================================

-- KST calendar date of an ISO UTC text timestamp
create or replace function public.kst_date(p text)
returns date language sql immutable strict parallel safe
set search_path = public, pg_temp
as $$ select (public.ts(p) at time zone 'Asia/Seoul')::date $$;
revoke execute on function public.kst_date(text) from public, anon, authenticated;

create or replace function public.review_due_snapshot_run(p_week date default null)
returns int language plpgsql security definer
set search_path = public, pg_temp
as $$
declare v_week date := coalesce(p_week, public.kst_week_start(now())); n int;
begin
  insert into public.review_due_snapshots (week, user_id, wrong_item_id)
  select v_week, e.user_id, e.wrong_item_id
  from public.review_entries e
  join public.profiles p on p.user_id = e.user_id
  where e.deleted_at is null and public.kst_date(e.due_at) >= v_week and public.kst_date(e.due_at) < v_week + 7
  on conflict do nothing;
  get diagnostics n = row_count;
  return n;
end $$;
revoke execute on function public.review_due_snapshot_run(date) from public, anon, authenticated;
grant execute on function public.review_due_snapshot_run(date) to service_role;

create or replace function public.metrics_run(p_week date default null)
returns jsonb language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  w date := coalesce(p_week, public.kst_week_start(now()) - 7);   -- previous completed week
  w_end date;
  payload jsonb;
  -- G1
  g1_sessions int; g1_camera int; g1_corrections int;
  g1_w4_sessions int; g1_w4_camera int;
  -- G2
  g2_linked int; g2_planner_items int; g2_planner_users int;
  -- G3
  g3_cohort_week date; g3_cohort int; g3_d30 int; g3_active_users int; g3_four_days int; g3_streak_returns int;
  -- G4
  g4_trial_starts int; g4_direct_paid int; g4_trial_conversions int; g4_cohort_converted int;
  g4_unconfirmed_saves int; g4_review_due int; g4_review_done int;
begin
  w_end := w + 7;

  -- G1 ------------------------------------------------------------------
  with s as (
    select * from public.sessions
    where deleted_at is null and status in ('finished','interrupted') and seated_seconds >= 180
      and public.kst_date(started_at) >= w and public.kst_date(started_at) < w_end
  )
  select count(*), count(*) filter (where mode = 'camera') into g1_sessions, g1_camera from s;
  select count(*) into g1_corrections from public.corrections c
  where c.deleted_at is null and public.kst_date(c.at) >= w and public.kst_date(c.at) < w_end;
  with s as (
    select s.* from public.sessions s join public.profiles p on p.user_id = s.user_id
    where s.deleted_at is null and s.status in ('finished','interrupted') and s.seated_seconds >= 180
      and public.kst_date(s.started_at) >= w and public.kst_date(s.started_at) < w_end
      and public.kst_date(s.started_at) between (p.created_at at time zone 'Asia/Seoul')::date + 22
                                              and (p.created_at at time zone 'Asia/Seoul')::date + 28
  )
  select count(*), count(*) filter (where mode = 'camera') into g1_w4_sessions, g1_w4_camera from s;

  -- G2 ------------------------------------------------------------------
  select count(*) filter (where planner_item_id is not null) into g2_linked from public.sessions
  where deleted_at is null and status in ('finished','interrupted') and seated_seconds >= 180
    and public.kst_date(started_at) >= w and public.kst_date(started_at) < w_end;
  select count(*), count(distinct user_id) into g2_planner_items, g2_planner_users from public.planner_items
  where deleted_at is null and recurrence_id is null and public.kst_date(created_at) >= w and public.kst_date(created_at) < w_end;

  -- G3 ------------------------------------------------------------------
  g3_cohort_week := w - 35;   -- the cohort whose 30–36 day window closed before this week ended
  with cohort as (
    select user_id, (created_at at time zone 'Asia/Seoul')::date as d0 from public.profiles
    where (created_at at time zone 'Asia/Seoul')::date >= g3_cohort_week and (created_at at time zone 'Asia/Seoul')::date < g3_cohort_week + 7
  )
  select count(*),
         count(*) filter (where exists (select 1 from public.activity_days a where a.user_id = c.user_id and a.deleted_at is null
                                        and a.date::date between c.d0 + 30 and c.d0 + 36))
    into g3_cohort, g3_d30 from cohort c;
  with act as (
    select user_id, count(*) as days from public.activity_days
    where deleted_at is null and date::date >= w and date::date < w_end group by user_id
  )
  select count(*), count(*) filter (where days >= 4) into g3_active_users, g3_four_days from act;
  with sess as (
    select user_id, public.kst_date(started_at) as d from public.sessions
    where deleted_at is null and status in ('finished','interrupted') and seated_seconds >= 180
  ), ordered as (
    select user_id, d, lag(d) over (partition by user_id order by d) as prev_d from (select distinct user_id, d from sess) x
  )
  select count(distinct user_id) into g3_streak_returns from ordered
  where d >= w and d < w_end and prev_d is not null and d - prev_d between 2 and 8;

  -- G4 ------------------------------------------------------------------
  select count(*) filter (where type = 'INITIAL_PURCHASE' and period_type = 'TRIAL'),
         count(*) filter (where type = 'INITIAL_PURCHASE' and period_type = 'NORMAL'),
         count(*) filter (where type = 'RENEWAL' and is_trial_conversion)
    into g4_trial_starts, g4_direct_paid, g4_trial_conversions
  from public.subscription_events
  where (event_at at time zone 'Asia/Seoul')::date >= w and (event_at at time zone 'Asia/Seoul')::date < w_end;
  with cohort as (
    select distinct user_id, min(event_at) as t0 from public.subscription_events
    where type = 'INITIAL_PURCHASE' and period_type = 'TRIAL' and user_id is not null
      and (event_at at time zone 'Asia/Seoul')::date >= w and (event_at at time zone 'Asia/Seoul')::date < w_end
    group by user_id
  )
  select count(*) filter (where exists (select 1 from public.subscription_events e where e.user_id = c.user_id
                                        and e.type = 'RENEWAL' and e.is_trial_conversion and e.event_at > c.t0))
    into g4_cohort_converted from cohort c;
  select count(*) into g4_unconfirmed_saves from public.wrong_items
  where deleted_at is null and user_confirmed = false and public.kst_date(created_at) >= w and public.kst_date(created_at) < w_end;
  select count(*),
         count(*) filter (where exists (select 1 from public.retry_records r where r.wrong_item_id = sn.wrong_item_id
                                        and r.deleted_at is null and r.voided = false
                                        and public.kst_date(r.at) >= w and public.kst_date(r.at) < w_end))
    into g4_review_due, g4_review_done
  from public.review_due_snapshots sn where sn.week = w;

  payload := jsonb_build_object(
    'week', w, 'week_end_exclusive', w_end, 'computed_at', public.iso_utc(now()),
    'g1', jsonb_build_object('sessions', g1_sessions, 'camera_sessions', g1_camera,
        'camera_ratio', case when g1_sessions = 0 then null else round(g1_camera::numeric / g1_sessions, 4) end,
        'corrections', g1_corrections,
        'correction_rate', case when g1_camera = 0 then null else round(g1_corrections::numeric / g1_camera, 4) end,
        'week4_sessions', g1_w4_sessions, 'week4_camera_sessions', g1_w4_camera,
        'week4_camera_ratio', case when g1_w4_sessions = 0 then null else round(g1_w4_camera::numeric / g1_w4_sessions, 4) end),
    'g2', jsonb_build_object('linked_sessions', g2_linked,
        'link_ratio', case when g1_sessions = 0 then null else round(g2_linked::numeric / g1_sessions, 4) end,
        'planner_items_created', g2_planner_items, 'planner_users', g2_planner_users,
        'planner_items_per_user', case when g2_planner_users = 0 then null else round(g2_planner_items::numeric / g2_planner_users, 2) end),
    'g3', jsonb_build_object('d30_cohort_week', g3_cohort_week, 'd30_cohort', g3_cohort, 'd30_retained', g3_d30,
        'd30_ratio', case when g3_cohort = 0 then null else round(g3_d30::numeric / g3_cohort, 4) end,
        'active_users', g3_active_users, 'four_day_users', g3_four_days,
        'four_day_ratio', case when g3_active_users = 0 then null else round(g3_four_days::numeric / g3_active_users, 4) end,
        'streak_returns', g3_streak_returns),
    'g4', jsonb_build_object('trial_starts', g4_trial_starts, 'direct_paid', g4_direct_paid,
        'trial_conversions', g4_trial_conversions, 'trial_cohort_converted', g4_cohort_converted,
        'trial_conversion_ratio', case when g4_trial_starts = 0 then null else round(g4_cohort_converted::numeric / g4_trial_starts, 4) end,
        'unconfirmed_saves', g4_unconfirmed_saves,
        'review_due', g4_review_due, 'review_done', g4_review_done,
        'review_completion_ratio', case when g4_review_due = 0 then null else round(g4_review_done::numeric / g4_review_due, 4) end));

  insert into public.metrics_weekly (week, payload, computed_at) values (w, payload, now())
  on conflict (week) do update set payload = excluded.payload, computed_at = now();
  return payload;
end $$;
revoke execute on function public.metrics_run(date) from public, anon, authenticated;
grant execute on function public.metrics_run(date) to service_role;

-- Unsubmitted drafts idle for 30 days → tombstone (seq per user; clients receive it by pull).
create or replace function public.draft_orphan_tombstone_run()
returns int language plpgsql security definer
set search_path = public, pg_temp
as $$
declare rec record; n int := 0;
begin
  for rec in
    select id, user_id from public.reading_requests
    where status = 'selecting' and submitted_at is null and deleted_at is null
      and public.ts(client_updated_at) < now() - interval '30 days'
  loop
    perform public.user_lock(rec.user_id);
    if public.sync_tombstone('reading_requests', rec.user_id, rec.id) then n := n + 1; end if;
  end loop;
  return n;
end $$;
revoke execute on function public.draft_orphan_tombstone_run() from public, anon, authenticated;
grant execute on function public.draft_orphan_tombstone_run() to service_role;

create or replace function public.retention_run()
returns jsonb language plpgsql security definer
set search_path = public, pg_temp
as $$
declare n_act int; n_snap int; n_met int; n_inq int; n_pass int; n_jobs int; n_queue int;
begin
  delete from public.activity_days where date::date < (now() at time zone 'Asia/Seoul')::date - 365;
  get diagnostics n_act = row_count;
  delete from public.review_due_snapshots where week < (now() at time zone 'Asia/Seoul')::date - 365;
  get diagnostics n_snap = row_count;
  delete from public.metrics_weekly where week < (now() at time zone 'Asia/Seoul')::date - 365;
  get diagnostics n_met = row_count;
  delete from public.inquiries where (resolved_at is not null and resolved_at < now() - interval '90 days')
                                  or (resolved_at is null and created_at < now() - interval '180 days');
  get diagnostics n_inq = row_count;
  delete from public.signup_passes where expires_at < now();
  get diagnostics n_pass = row_count;
  delete from public.reading_jobs where deadline < now() - interval '7 days';
  get diagnostics n_jobs = row_count;
  delete from public.photo_delete_queue where status = 'done' and completed_at < now() - interval '7 days';
  get diagnostics n_queue = row_count;
  return jsonb_build_object('activity_days', n_act, 'review_due_snapshots', n_snap, 'metrics_weekly', n_met,
                            'inquiries', n_inq, 'signup_passes', n_pass, 'reading_jobs', n_jobs, 'photo_delete_queue', n_queue);
end $$;
revoke execute on function public.retention_run() from public, anon, authenticated;
grant execute on function public.retention_run() to service_role;

create or replace function public.daily_maintenance_run()
returns jsonb language plpgsql security definer
set search_path = public, pg_temp
as $$
begin
  return jsonb_build_object(
    'expired', public.reading_expire_run(),
    'orphan_drafts', public.draft_orphan_tombstone_run(),
    'retention', public.retention_run());
end $$;
revoke execute on function public.daily_maintenance_run() from public, anon, authenticated;
grant execute on function public.daily_maintenance_run() to service_role;
