-- Development reading uploads need the real private bucket, not console-only setup.
insert into storage.buckets(id,name,public) values('reading-photos','reading-photos',false) on conflict(id) do nothing;
create policy "next02_reading_insert_owned" on storage.objects for insert to authenticated
with check(bucket_id='reading-photos' and split_part(name,'/',1)=auth.uid()::text
 and name ~ '^[0-9a-f-]{36}/[0-9a-f-]{36}/p([0-9]|1[0-9])[.]jpg$');

-- Owner-scoped status snapshots can reconstruct a missing local request after
-- active_exists. This does not add a general S13 sync or resurrect tombstones.
create or replace function public.reading_request_json(r public.reading_requests)
returns jsonb language sql immutable set search_path=public,pg_temp as $$
 select jsonb_build_object(
  'id',r.id,'user_id',r.user_id,'created_at',r.created_at,'client_updated_at',r.client_updated_at,
  'device_id',r.device_id,'purge_epoch',r.purge_epoch,'deleted_at',r.deleted_at,
  'request_id',r.request_id,'status',r.status,'server_version',r.server_version,'server_seq',r.server_seq,
  'submitted_at',r.submitted_at,'completed_at',r.completed_at,'fail_reason',r.fail_reason,
  'quota_month',r.quota_month,'quota_charged',coalesce(r.quota_charged,false),'payload_hash',r.payload_hash,
  'subject_id',r.subject_id,'range_text',r.range_text,'origin',r.origin,'session_id',r.session_id,'planner_item_id',r.planner_item_id,
  'result_json',case when r.status in ('done_unsaved','saved') then r.result_json else null end,
  'marks_json',case when r.status='saved' then r.marks_json else null end)
$$;
