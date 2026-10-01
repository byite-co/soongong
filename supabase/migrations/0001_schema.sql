-- =============================================================================
-- S03 · 0001_schema.sql — server schema (1:1 with docs/data-model.md v1 + §7)
--
-- Conventions (docs/data-model.md §0, decisions [S02]):
--   * sync-table ids are TEXT uuid v4 (lowercase); `activity_days`/`settings`
--     ids are deterministic uuid v5 (same namespaces as the client).
--   * timestamps on sync tables are ISO 8601 UTC TEXT with `Z`
--     (`2026-09-30T14:03:00.000Z`), exactly what drift stores. Server-only
--     tables use timestamptz. Helpers `iso_utc()` / `ts()` convert.
--   * enums are snake_case wire names, enforced with CHECK constraints.
--   * content columns are nullable + CHECK (deleted_at IS NOT NULL OR
--     <required content> IS NOT NULL) so a tombstone keeps only the common
--     fields + the table's keep keys (D2, data-model §3).
--   * JSON columns are jsonb on the server. On the wire (sync_push data /
--     sync_pull rows) they travel as JSON **text** — the client stores TEXT.
--   * No FKs between sync tables (children may arrive before parents).
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 0. domains + helpers
-- ---------------------------------------------------------------------------
create domain public.iso_utc as text
  check (value ~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,6})?Z$');
comment on domain public.iso_utc is 'ISO 8601 UTC text with Z suffix (client/server wire format for sync tables)';

create domain public.local_date as text check (value ~ '^\d{4}-\d{2}-\d{2}$');
create domain public.local_time as text check (value ~ '^\d{2}:\d{2}$');
create domain public.uuid_text as text
  check (value ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$');

create or replace function public.iso_utc(p timestamptz)
returns text language sql immutable strict parallel safe
set search_path = public, pg_temp
as $$ select to_char(p at time zone 'UTC', 'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"') $$;

create or replace function public.ts(p text)
returns timestamptz language sql immutable strict parallel safe
set search_path = public, pg_temp
as $$ select p::timestamptz $$;

-- KST month key used by the reading ledger (`yyyy-MM`, decisions [S02b]).
create or replace function public.kst_month(p timestamptz)
returns text language sql immutable strict parallel safe
set search_path = public, pg_temp
as $$ select to_char(p at time zone 'Asia/Seoul', 'YYYY-MM') $$;

-- Monday 00:00 KST of the week containing p (D15 week boundary).
create or replace function public.kst_week_start(p timestamptz)
returns date language sql immutable strict parallel safe
set search_path = public, pg_temp
as $$ select date_trunc('week', (p at time zone 'Asia/Seoul'))::date $$;

-- ---------------------------------------------------------------------------
-- 1. per-user sequence (D2): every server write goes through next_server_seq
-- ---------------------------------------------------------------------------
create table public.user_seq (
  user_id uuid primary key references auth.users(id) on delete cascade,
  last_seq bigint not null default 0
);

-- Takes the user advisory lock (same key as sync_push/reading_submit) and
-- returns the next sequence number. seq order == commit order per user.
create or replace function public.next_server_seq(p_user uuid)
returns bigint language plpgsql security definer
set search_path = public, pg_temp
as $$
declare v bigint;
begin
  perform pg_advisory_xact_lock(hashtext(p_user::text));
  insert into public.user_seq(user_id, last_seq) values (p_user, 1)
  on conflict (user_id) do update set last_seq = public.user_seq.last_seq + 1
  returning last_seq into v;
  return v;
end $$;

create or replace function public.user_lock(p_user uuid)
returns void language sql security definer
set search_path = public, pg_temp
as $$ select pg_advisory_xact_lock(hashtext(p_user::text)) $$;

-- ---------------------------------------------------------------------------
-- 2. sync tables (user-editable through sync_push; D24)
-- ---------------------------------------------------------------------------
create table public.subjects (
  id public.uuid_text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at public.iso_utc not null,
  client_updated_at public.iso_utc not null,
  deleted_at public.iso_utc,
  device_id text not null,
  purge_epoch int not null default 0,
  server_version int not null default 1,
  server_received_at timestamptz not null default now(),
  server_seq bigint not null,
  name text,
  color_index int,
  sort_order int,
  is_default boolean,
  constraint subjects_color check (color_index is null or color_index between 0 and 7),
  constraint subjects_tombstone check (deleted_at is not null or
    (name is not null and color_index is not null and sort_order is not null and is_default is not null))
);
create index subjects_user_sort on public.subjects (user_id, sort_order);
create index subjects_user_seq on public.subjects (user_id, server_seq);

create table public.sessions (
  id public.uuid_text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at public.iso_utc not null,
  client_updated_at public.iso_utc not null,
  deleted_at public.iso_utc,
  device_id text not null,
  purge_epoch int not null default 0,
  server_version int not null default 1,
  server_received_at timestamptz not null default now(),
  server_seq bigint not null,
  subject_id public.uuid_text,
  planner_item_id public.uuid_text,
  kind text check (kind in ('study','todo','self')),
  mode text check (mode in ('camera','manual')),
  started_at public.iso_utc,
  ended_at public.iso_utc,
  status text check (status in ('active','paused','interrupted','finished','discarded')),
  seated_seconds int check (seated_seconds is null or seated_seconds >= 0),
  sensitivity_level int check (sensitivity_level is null or sensitivity_level between 0 and 2),
  note text,
  constraint sessions_tombstone check (deleted_at is not null or
    (kind is not null and mode is not null and started_at is not null and status is not null
     and seated_seconds is not null and sensitivity_level is not null))
);
create index sessions_user_started on public.sessions (user_id, started_at);
create index sessions_user_status on public.sessions (user_id, status);
create index sessions_user_seq on public.sessions (user_id, server_seq);

create table public.session_segments (
  id public.uuid_text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at public.iso_utc not null,
  client_updated_at public.iso_utc not null,
  deleted_at public.iso_utc,
  device_id text not null,
  purge_epoch int not null default 0,
  server_version int not null default 1,
  server_received_at timestamptz not null default now(),
  server_seq bigint not null,
  session_id public.uuid_text not null,            -- keep key
  kind text check (kind in ('seated','away','manual','paused')),
  start_at public.iso_utc,
  end_at public.iso_utc,
  corrected boolean,
  constraint session_segments_tombstone check (deleted_at is not null or
    (kind is not null and start_at is not null and end_at is not null and corrected is not null))
);
create index session_segments_session_start on public.session_segments (session_id, start_at);
create index session_segments_user_seq on public.session_segments (user_id, server_seq);

create table public.corrections (
  id public.uuid_text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at public.iso_utc not null,
  client_updated_at public.iso_utc not null,
  deleted_at public.iso_utc,
  device_id text not null,
  purge_epoch int not null default 0,
  server_version int not null default 1,
  server_received_at timestamptz not null default now(),
  server_seq bigint not null,
  session_id public.uuid_text not null,            -- keep key
  segment_id public.uuid_text,
  from_kind text check (from_kind in ('seated','away','manual','paused')),
  to_kind text check (to_kind in ('seated','away','manual','paused')),
  at public.iso_utc,
  sensitivity_before int check (sensitivity_before is null or sensitivity_before between 0 and 2),
  sensitivity_after int check (sensitivity_after is null or sensitivity_after between 0 and 2),
  constraint corrections_tombstone check (deleted_at is not null or
    (segment_id is not null and from_kind is not null and to_kind is not null and at is not null
     and sensitivity_before is not null and sensitivity_after is not null))
);
create index corrections_user_at on public.corrections (user_id, at);
create index corrections_session on public.corrections (session_id);
create index corrections_user_seq on public.corrections (user_id, server_seq);

create table public.planner_items (
  id public.uuid_text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at public.iso_utc not null,
  client_updated_at public.iso_utc not null,
  deleted_at public.iso_utc,
  device_id text not null,
  purge_epoch int not null default 0,
  server_version int not null default 1,
  server_received_at timestamptz not null default now(),
  server_seq bigint not null,
  kind text check (kind in ('study','todo','self','event')),
  title text check (title is null or char_length(title) between 1 and 60),
  subject_id public.uuid_text,
  range_text text,
  target_minutes int check (target_minutes is null or target_minutes >= 0),
  date public.local_date,
  start_time public.local_time,
  end_time public.local_time,
  is_done boolean,
  done_at public.iso_utc,
  recurrence_id public.uuid_text,                  -- keep key
  band_start public.local_date,
  band_end public.local_date,
  sort_order int,
  constraint planner_items_tombstone check (deleted_at is not null or
    (kind is not null and title is not null and date is not null and is_done is not null and sort_order is not null))
);
create index planner_items_user_date on public.planner_items (user_id, date);
create index planner_items_user_band on public.planner_items (user_id, band_start, band_end);
create index planner_items_recurrence on public.planner_items (recurrence_id);
create index planner_items_user_seq on public.planner_items (user_id, server_seq);

create table public.recurrences (
  id public.uuid_text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at public.iso_utc not null,
  client_updated_at public.iso_utc not null,
  deleted_at public.iso_utc,
  device_id text not null,
  purge_epoch int not null default 0,
  server_version int not null default 1,
  server_received_at timestamptz not null default now(),
  server_seq bigint not null,
  title text,
  subject_id public.uuid_text,
  weekday_mask int check (weekday_mask is null or weekday_mask between 1 and 127),
  start_time public.local_time,
  end_time public.local_time,
  ends_on public.local_date,
  active boolean,
  constraint recurrences_tombstone check (deleted_at is not null or
    (title is not null and weekday_mask is not null and start_time is not null and end_time is not null and active is not null))
);
create index recurrences_user_seq on public.recurrences (user_id, server_seq);

create table public.reading_requests (
  id public.uuid_text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at public.iso_utc not null,
  client_updated_at public.iso_utc not null,
  deleted_at public.iso_utc,
  device_id text not null,
  purge_epoch int not null default 0,
  server_version int not null default 1,
  server_received_at timestamptz not null default now(),
  server_seq bigint not null,
  request_id public.uuid_text not null,            -- keep key (= id on the client)
  -- client columns (sync_push while `selecting`)
  subject_id public.uuid_text,
  range_text text check (range_text is null or char_length(range_text) between 1 and 40),
  session_id public.uuid_text,
  planner_item_id public.uuid_text,
  origin text check (origin in ('planner','wrongs','home')),
  -- server columns (never accepted from sync_push)
  payload_hash text,
  status text check (status in ('selecting','processing','taking_long','failed','cancelled',
                                'done_unsaved','saved','discarded','expired')),
  submitted_at public.iso_utc,
  completed_at public.iso_utc,
  quota_month text check (quota_month is null or quota_month ~ '^\d{4}-\d{2}$'),
  quota_charged boolean default false,
  result_json jsonb,
  marks_json jsonb,
  fail_reason text,
  constraint reading_requests_tombstone check (deleted_at is not null or
    (subject_id is not null and range_text is not null and origin is not null and status is not null)),
  constraint reading_requests_user_request unique (user_id, request_id)
);
create index reading_requests_user_status on public.reading_requests (user_id, status);
create index reading_requests_user_seq on public.reading_requests (user_id, server_seq);
-- D17: one active request and one unsaved result per account.
create unique index reading_requests_one_active on public.reading_requests (user_id)
  where status in ('processing','taking_long');
create unique index reading_requests_one_unsaved on public.reading_requests (user_id)
  where status = 'done_unsaved';

create table public.wrong_items (
  id public.uuid_text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at public.iso_utc not null,
  client_updated_at public.iso_utc not null,
  deleted_at public.iso_utc,
  device_id text not null,
  purge_epoch int not null default 0,
  server_version int not null default 1,
  server_received_at timestamptz not null default now(),
  server_seq bigint not null,
  request_id public.uuid_text not null,            -- keep key
  subject_id public.uuid_text,
  range_text text,
  page_index int check (page_index is null or page_index >= 0),
  number int check (number is null or number >= 0),
  mark text check (mark in ('wrong','partial','unsolved','guessed')),
  confidence real check (confidence is null or (confidence >= 0 and confidence <= 1)),
  user_confirmed boolean,
  status text check (status in ('open','resolved')),
  resolved_at public.iso_utc,
  constraint wrong_items_tombstone check (deleted_at is not null or
    (subject_id is not null and range_text is not null and page_index is not null and number is not null
     and mark is not null and confidence is not null and user_confirmed is not null and status is not null))
);
create index wrong_items_user_status on public.wrong_items (user_id, status);
create index wrong_items_request on public.wrong_items (request_id);
create index wrong_items_user_subject on public.wrong_items (user_id, subject_id);
create index wrong_items_user_seq on public.wrong_items (user_id, server_seq);

create table public.review_entries (
  id public.uuid_text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at public.iso_utc not null,
  client_updated_at public.iso_utc not null,
  deleted_at public.iso_utc,
  device_id text not null,
  purge_epoch int not null default 0,
  server_version int not null default 1,
  server_received_at timestamptz not null default now(),
  server_seq bigint not null,
  wrong_item_id public.uuid_text not null,         -- keep key
  due_at public.iso_utc,
  interval_days int check (interval_days is null or interval_days in (1,2,4,8,16,30)),
  consecutive_correct int check (consecutive_correct is null or consecutive_correct between 0 and 2),
  last_result text check (last_result in ('correct','partial','wrong')),
  constraint review_entries_tombstone check (deleted_at is not null or
    (due_at is not null and interval_days is not null and consecutive_correct is not null))
);
create index review_entries_user_due on public.review_entries (user_id, due_at);
create index review_entries_user_seq on public.review_entries (user_id, server_seq);
-- data-model §7 ③ — identical statement to the client's partial unique index.
create unique index review_entries_live_wrong_item on public.review_entries (wrong_item_id) where deleted_at is null;

create table public.retry_records (
  id public.uuid_text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at public.iso_utc not null,
  client_updated_at public.iso_utc not null,
  deleted_at public.iso_utc,
  device_id text not null,
  purge_epoch int not null default 0,
  server_version int not null default 1,
  server_received_at timestamptz not null default now(),
  server_seq bigint not null,
  wrong_item_id public.uuid_text not null,         -- keep key
  result text check (result in ('correct','partial','wrong')),
  at public.iso_utc,
  voided boolean,
  voided_at public.iso_utc,
  constraint retry_records_tombstone check (deleted_at is not null or
    (result is not null and at is not null and voided is not null))
);
create index retry_records_wrong_item_at on public.retry_records (wrong_item_id, at);
create index retry_records_user_seq on public.retry_records (user_id, server_seq);

create table public.settings (
  id public.uuid_text primary key,                 -- uuid v5(settingNamespace, user|key)
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at public.iso_utc not null,
  client_updated_at public.iso_utc not null,
  deleted_at public.iso_utc,
  device_id text not null,
  purge_epoch int not null default 0,
  server_version int not null default 1,
  server_received_at timestamptz not null default now(),
  server_seq bigint not null,
  key text,
  value_json jsonb,
  constraint settings_tombstone check (deleted_at is not null or (key is not null and value_json is not null)),
  constraint settings_user_key unique (user_id, key)
);
create index settings_user_seq on public.settings (user_id, server_seq);

create table public.activity_days (
  id public.uuid_text primary key,                 -- uuid v5(activityDayNamespace, user|date)
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at public.iso_utc not null,
  client_updated_at public.iso_utc not null,
  deleted_at public.iso_utc,
  device_id text not null,
  purge_epoch int not null default 0,
  server_version int not null default 1,
  server_received_at timestamptz not null default now(),
  server_seq bigint not null,
  date public.local_date not null,                 -- keep key
  constraint activity_days_user_date unique (user_id, date)
);
create index activity_days_user_seq on public.activity_days (user_id, server_seq);

-- ---------------------------------------------------------------------------
-- 3. sync registry: tables, keep keys, allowed push columns (D24 §7)
-- ---------------------------------------------------------------------------
create table public.sync_tables (
  table_name text primary key,
  keep_keys text[] not null default '{}',
  -- sync_push may insert a row the server does not have (false = creation
  -- happens only through server functions: wrong_items via reading-save).
  client_insert boolean not null default true
);
insert into public.sync_tables (table_name, keep_keys, client_insert) values
  ('subjects',          '{}',                  true),
  ('sessions',          '{}',                  true),
  ('session_segments',  '{session_id}',        true),
  ('corrections',       '{session_id}',        true),
  ('planner_items',     '{recurrence_id}',     true),
  ('recurrences',       '{}',                  true),
  ('reading_requests',  '{request_id}',        true),
  ('wrong_items',       '{request_id}',        false),
  ('review_entries',    '{wrong_item_id}',     true),
  ('retry_records',     '{wrong_item_id}',     true),
  ('settings',          '{}',                  true),
  ('activity_days',     '{date}',              true);

-- Allowed `data` keys per table. Anything else (server columns, user_id,
-- local-only columns) rejects the row with `invalid_columns`.
create table public.allowed_columns (
  table_name text not null references public.sync_tables(table_name),
  column_name text not null,
  primary key (table_name, column_name)
);
-- common push columns (data-model §1.1) for every table except wrong_items
insert into public.allowed_columns
select t.table_name, c
from public.sync_tables t
cross join unnest(array['created_at','client_updated_at','deleted_at','device_id','purge_epoch']) as c
where t.table_name <> 'wrong_items';
insert into public.allowed_columns (table_name, column_name) values
  ('subjects','name'),('subjects','color_index'),('subjects','sort_order'),('subjects','is_default'),
  ('sessions','subject_id'),('sessions','planner_item_id'),('sessions','kind'),('sessions','mode'),
  ('sessions','started_at'),('sessions','ended_at'),('sessions','status'),('sessions','seated_seconds'),
  ('sessions','sensitivity_level'),('sessions','note'),
  ('session_segments','session_id'),('session_segments','kind'),('session_segments','start_at'),
  ('session_segments','end_at'),('session_segments','corrected'),
  ('corrections','session_id'),('corrections','segment_id'),('corrections','from_kind'),('corrections','to_kind'),
  ('corrections','at'),('corrections','sensitivity_before'),('corrections','sensitivity_after'),
  ('planner_items','kind'),('planner_items','title'),('planner_items','subject_id'),('planner_items','range_text'),
  ('planner_items','target_minutes'),('planner_items','date'),('planner_items','start_time'),('planner_items','end_time'),
  ('planner_items','is_done'),('planner_items','done_at'),('planner_items','recurrence_id'),('planner_items','band_start'),
  ('planner_items','band_end'),('planner_items','sort_order'),
  ('recurrences','title'),('recurrences','subject_id'),('recurrences','weekday_mask'),('recurrences','start_time'),
  ('recurrences','end_time'),('recurrences','ends_on'),('recurrences','active'),
  -- reading_requests: client columns only (`selecting`); server columns are NOT listed
  ('reading_requests','request_id'),('reading_requests','subject_id'),('reading_requests','range_text'),
  ('reading_requests','session_id'),('reading_requests','planner_item_id'),('reading_requests','origin'),
  -- wrong_items (data-model §2.9 / §7 ②): 3 content columns + the 3 common ones
  ('wrong_items','subject_id'),('wrong_items','status'),('wrong_items','resolved_at'),
  ('wrong_items','client_updated_at'),('wrong_items','device_id'),('wrong_items','purge_epoch'),
  ('review_entries','wrong_item_id'),('review_entries','due_at'),('review_entries','interval_days'),
  ('review_entries','consecutive_correct'),('review_entries','last_result'),
  ('retry_records','wrong_item_id'),('retry_records','result'),('retry_records','at'),('retry_records','voided'),
  ('retry_records','voided_at'),
  ('settings','key'),('settings','value_json'),
  ('activity_days','date');

-- ---------------------------------------------------------------------------
-- 4. server-only tables (D24 "서버 원장"; RLS on, no user policies)
-- ---------------------------------------------------------------------------
create table public.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  onboarding_done boolean not null default false,
  consent_account_version text,
  consent_account_at timestamptz,
  consent_reading_version text,
  consent_reading_at timestamptz,
  consent_reading_revoked_at timestamptz,
  purge_epoch int not null default 0,
  created_at timestamptz not null default now()
  -- NO birth date column (D6 · D14). Age verification result lives only in signup_approvals.age_verified.
);

-- Age-verified signup passes. Consumed = deleted (no consumed_at).
create table public.signup_passes (
  provider text not null,
  subject_hash text not null,                      -- hex sha256(sub) / sha256(lower(email))
  expires_at timestamptz not null,
  created_at timestamptz not null default now(),
  primary key (provider, subject_hash)
);
create index signup_passes_expires on public.signup_passes (expires_at);

create table public.signup_approvals (
  user_id uuid primary key references auth.users(id) on delete cascade,
  provider text not null,
  age_verified boolean not null,
  approved_at timestamptz not null default now()
);

-- Receipts (D2 step 1). Only codes — never learning content.
create table public.sync_mutations (
  user_id uuid not null references auth.users(id) on delete cascade,
  mutation_id uuid not null,
  table_name text not null,
  row_id text not null,
  server_version int,
  server_seq bigint,
  result text not null,                            -- 'accepted' only (rejections are re-evaluated)
  received_at timestamptz not null default now(),
  primary key (user_id, mutation_id)
);

create table public.subscription_state (
  user_id uuid primary key references auth.users(id) on delete cascade,
  status text not null default 'free'
    check (status in ('free','trial','premium','cancelPending','grace','expired','pendingApproval')),
  expires_at timestamptz,
  grace_expires_at timestamptz,
  period_type text,
  will_renew boolean not null default false,
  trial_used boolean not null default false,
  has_history boolean not null default false,
  last_event_at timestamptz,
  updated_at timestamptz not null default now()
);

create table public.subscription_events (
  event_id text primary key,
  user_id uuid references auth.users(id) on delete cascade,
  type text not null,
  period_type text,
  is_trial_conversion boolean,
  grace_period_expiration_at timestamptz,
  expiration_at timestamptz,
  event_at timestamptz not null,
  raw jsonb not null,
  received_at timestamptz not null default now()
);
create index subscription_events_user_at on public.subscription_events (user_id, event_at);

create table public.reading_quota (
  user_id uuid not null references auth.users(id) on delete cascade,
  month text not null check (month ~ '^\d{4}-\d{2}$'),
  used int not null default 0 check (used >= 0),
  reserved int not null default 0 check (reserved >= 0),
  quota_limit int not null default 20 check (quota_limit >= 0),   -- JSON key `limit` ([S02])
  primary key (user_id, month)
);

create table public.reading_jobs (
  request_id public.uuid_text primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  deadline timestamptz not null,
  lease_until timestamptz,
  attempts int not null default 0,
  object_paths text[] not null default '{}',       -- storage objects of this request
  created_at timestamptz not null default now()
);
create index reading_jobs_pick on public.reading_jobs (created_at) where attempts < 2;

create table public.photo_delete_queue (
  id bigserial primary key,
  request_id public.uuid_text,
  user_id uuid,
  bucket_path text not null,
  status text not null default 'pending' check (status in ('pending','done')),
  attempts int not null default 0,
  next_at timestamptz not null default now(),
  completed_at timestamptz,
  created_at timestamptz not null default now()
);
create index photo_delete_queue_pending on public.photo_delete_queue (next_at) where status = 'pending';

create table public.review_due_snapshots (
  week date not null,
  user_id uuid not null,
  wrong_item_id public.uuid_text not null,
  primary key (week, user_id, wrong_item_id)
);

create table public.metrics_weekly (
  week date primary key,
  payload jsonb not null,
  computed_at timestamptz not null default now()
);

create table public.inquiries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  body text not null check (char_length(body) between 1 and 2000),
  reply_email text,
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);
create index inquiries_user_created on public.inquiries (user_id, created_at);

-- Runtime configuration read by SQL jobs (pg_net targets). Human-set in the
-- console (docs/handoff/S03.md). Never readable by users.
create table public.server_config (
  key text primary key,
  value text not null,
  updated_at timestamptz not null default now()
);
comment on table public.server_config is
  'keys: functions_base_url (https://<ref>.supabase.co/functions/v1), job_secret (shared with Edge job functions), hook_fixtures_capture (on|off)';

create or replace function public.server_config_get(p_key text)
returns text language sql security definer stable
set search_path = public, pg_temp
as $$ select value from public.server_config where key = p_key $$;

-- Posts to an Edge job function via pg_net when configured. Returns true when
-- a request was queued. Never raises (pg_net failures are swept by cron).
create or replace function public.invoke_edge(p_name text, p_body jsonb default '{}'::jsonb)
returns boolean language plpgsql security definer
set search_path = public, pg_temp
as $$
declare
  v_url text := public.server_config_get('functions_base_url');
  v_secret text := public.server_config_get('job_secret');
begin
  if v_url is null or v_secret is null then
    return false;
  end if;
  if to_regprocedure('net.http_post(text,jsonb,jsonb,jsonb,integer)') is null then
    return false;
  end if;
  begin
    perform net.http_post(
      url := rtrim(v_url, '/') || '/' || p_name,
      body := p_body,
      headers := jsonb_build_object('Content-Type', 'application/json', 'x-job-secret', v_secret),
      timeout_milliseconds := 5000);
  exception when others then
    return false;
  end;
  return true;
end $$;
