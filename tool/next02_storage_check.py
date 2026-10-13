"""Disposable local Supabase Auth/Storage/Edge integration. Never prints credentials.
Run in WSL with the isolated stack described in NEXT-02.md; no hosted target.
"""
import base64
import datetime as dt
import json
import secrets
import subprocess
import time
import urllib.error
import urllib.request
import uuid
from pathlib import Path

STACK = '/var/tmp/soongong-next02-stack'
CLI = '/var/tmp/soongong-next02-supabase/supabase'
DB = 'supabase_db_soongong-next02-local'

def sql(s):
    p = subprocess.run(['docker', 'exec', '-i', DB, 'psql', '-U', 'postgres', '-d', 'postgres', '-XAtq', '-v', 'ON_ERROR_STOP=1'], input=s, text=True, capture_output=True)
    if p.returncode:
        raise RuntimeError('local_fixture_sql_failed: ' + p.stderr[:400])
    return p.stdout.strip()

def main():
    for attempt in range(30):
        status = subprocess.run([CLI, 'status', '--workdir', STACK, '-o', 'json'], capture_output=True, text=True)
        if status.returncode == 0:
            settings = json.loads(status.stdout)
            break
        time.sleep(1)
    else:
        raise RuntimeError('local_stack_unavailable: ' + status.stderr[:400])
    url = settings['API_URL']
    assert url in ('http://127.0.0.1:54321', 'http://localhost:54321')
    admin = settings['SERVICE_ROLE_KEY']
    anon = settings['ANON_KEY']
    checks = []
    users = []
    def http(path, token=admin, body=None, method=None, raw=False):
        headers = {'apikey': anon, 'Authorization': 'Bearer ' + token}
        if body is not None:
            headers['Content-Type'] = 'image/png' if raw else 'application/json'
        data = body if raw else (None if body is None else json.dumps(body).encode())
        req = urllib.request.Request(url + path, data=data, headers=headers, method=method)
        try:
            with urllib.request.urlopen(req, timeout=30) as response:
                payload = response.read()
                return response.status, payload if raw else json.loads(payload or b'null')
        except urllib.error.HTTPError as e:
            payload = e.read()
            if raw: return e.code, payload
            try: return e.code, json.loads(payload)
            except ValueError: return e.code, None
    def check(label, success):
        checks.append({'check': label, 'pass': bool(success)})
        print(label, 'PASS' if success else 'FAIL', flush=True)
        if not success:
            raise AssertionError(label)
    def rpc(name, args, token=admin):
        code, value = http('/rest/v1/rpc/' + name, token, args)
        if code != 200 and code != 204:
            raise RuntimeError('local_rpc_failed_' + name + '_' + str(code))
        return value
    try:
        for _ in range(2):
            email = 'fixture-' + uuid.uuid4().hex + '@example.invalid'
            password = secrets.token_urlsafe(32)
            sql("insert into public.signup_passes(provider,subject_hash,expires_at) values('email',public.subject_hash('%s'),now()+interval '10 minutes');" % email)
            status, user = http('/auth/v1/admin/users', body={'email': email, 'password': password, 'email_confirm': True})
            if status not in (200, 201): print('Auth fixture error', status, user, flush=True)
            check('Auth admin fixture creation', status in (200, 201))
            uid = user['id']; users.append(uid)
            sql("insert into public.profiles(user_id,consent_account_at,consent_reading_at) values('%s',now(),now()) on conflict(user_id) do update set consent_account_at=now(),consent_reading_at=now();" % uid)
            status, login = http('/auth/v1/token?grant_type=password', anon, {'email': email, 'password': password})
            check('Auth password session', status == 200)
            if len(users) == 1: a, ta = uid, login['access_token']
            else: b, tb = uid, login['access_token']
        # Actual clocks, no wall-clock mutation; only this disposable asset has a short TTL.
        doc, asset = str(uuid.uuid4()), str(uuid.uuid4())
        rpc('study_save_v1', {'p_epoch':0,'p_id':doc,'p_expected_revision':None,'p_kind':'text','p_title':'synthetic','p_text':'synthetic fixture','p_transcription':{'schema_version':1,'kind':'text','engine':'fixture','blocks':[]}}, ta)
        first = rpc('study_photo_register_v1', {'p_epoch':0,'p_document':doc,'p_asset':asset}, ta)
        again = rpc('study_photo_register_v1', {'p_epoch':0,'p_document':doc,'p_asset':asset}, ta)
        check('Registration retry does not extend retention', first == again)
        sql("update public.study_photo_assets set first_stored_at=now()-interval '30 days'+interval '14 seconds',expires_at=now()+interval '14 seconds' where id='%s';" % asset)
        path = sql("select object_path from public.study_photo_assets where id='%s';" % asset)
        payload = base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+aX1cAAAAASUVORK5CYII=')
        status, _ = http('/storage/v1/object/study-restore/' + path, body=payload, method='POST', raw=True)
        check('Actual synthetic object upload', status == 200)
        check('B direct object denied', http('/storage/v1/object/authenticated/study-restore/' + path, tb, raw=True)[0] != 200)
        req = {'version':1,'purge_epoch':0,'asset_id':asset}
        check('B Edge asset access denied', http('/functions/v1/study-photo', tb, req)[0] != 200)
        status, grant = http('/functions/v1/study-photo', ta, req)
        check('A real Edge URL grant', status == 200)
        expiry = dt.datetime.fromisoformat(grant['expires_at'].replace('Z','+00:00')).timestamp()
        asset_expiry = float(sql("select extract(epoch from expires_at) from public.study_photo_assets where id='%s';" % asset))
        check('Signed exp within asset and 60s', time.time() < expiry <= min(asset_expiry, time.time()+60))
        # Local Edge returns its internal gateway URL; only replace that known origin.
        signed = grant['url'].replace('http://kong:8000', url).replace('http://supabase_kong_soongong-next02-local:8000', url)
        assert signed.startswith(url + '/storage/v1/')
        with urllib.request.urlopen(signed, timeout=20) as r:
            check('Signed GET before expiry returns exact bytes', r.status == 200 and r.read() == payload)
        before = sql("select first_stored_at::text||'|'||expires_at::text from public.study_photo_assets where id='%s';" % asset)
        rpc('study_photo_register_v1', {'p_epoch':0,'p_document':doc,'p_asset':asset}, ta)
        check('Read and retry keep first_stored_at/expires_at', before == sql("select first_stored_at::text||'|'||expires_at::text from public.study_photo_assets where id='%s';" % asset))
        time.sleep(max(0, expiry-time.time()+2))
        try:
            urllib.request.urlopen(signed, timeout=20).close(); expired = False
        except urllib.error.HTTPError: expired = True
        check('Actual signed GET after expiry rejected', expired)
        rpc('study_delete_v1', {'p_epoch':0,'p_id':doc}, ta)
        check('Late new URL after document delete denied', http('/functions/v1/study-photo', ta, req)[0] != 200)
        rows = rpc('study_object_claim', {'p_limit':100})
        row = next(x for x in rows if x['object_path'] == path)
        # Force a genuine Storage authorization failure; do not acknowledge bytes deletion.
        status, _ = http('/storage/v1/object/study-restore', tb, {'prefixes':[path]}, method='DELETE')
        # Some Storage versions deliberately return []/200 for unauthorized objects.
        check('Deletion failure leaves bytes present', http('/storage/v1/object/authenticated/study-restore/' + path, raw=True)[0] == 200)
        check('Pending obligation has backoff', sql("select status='pending' and attempts=1 and next_at>now() from public.study_object_deletions where id='%s';" % row['id']) == 't')
        check('Immediate retry cannot claim backoff', not any(x['id'] == row['id'] for x in rpc('study_object_claim', {'p_limit':100})))
        sql("update public.study_object_deletions set next_at=now() where id='%s';" % row['id'])
        rows = rpc('study_object_claim', {'p_limit':100})
        check('Due retry claimed', any(x['id'] == row['id'] for x in rows))
        status, _ = http('/storage/v1/object/study-restore', body={'prefixes':[path]}, method='DELETE')
        check('Service retry removes actual bytes', status == 200 and http('/storage/v1/object/authenticated/study-restore/' + path, raw=True)[0] != 200)
        rpc('study_object_done', {'p_ids':[row['id']]})
        check('Completion after Storage acknowledgement', sql("select status from public.study_object_deletions where id='%s';" % row['id']) == 'done')
        check('Storage metadata absent', sql("select count(*) from storage.objects where bucket_id='study-restore' and name='%s';" % path) == '0')
        doc2, asset2 = str(uuid.uuid4()), str(uuid.uuid4())
        rpc('study_save_v1', {'p_epoch':0,'p_id':doc2,'p_expected_revision':None,'p_kind':'text','p_title':'synthetic','p_text':'account deletion fixture','p_transcription':{'schema_version':1,'kind':'text','engine':'fixture','blocks':[]}}, ta)
        rpc('study_photo_register_v1', {'p_epoch':0,'p_document':doc2,'p_asset':asset2}, ta)
        path2 = sql("select object_path from public.study_photo_assets where id='%s';" % asset2)
        check('Account deletion fixture actual upload', http('/storage/v1/object/study-restore/' + path2, body=payload, method='POST', raw=True)[0] == 200)
        sql("select public.delete_account_data('%s');" % a)
        check('Deleted account late URL denied', http('/functions/v1/study-photo', ta, {'version':1,'purge_epoch':0,'asset_id':asset2})[0] != 200)
        row2 = next(x for x in rpc('study_object_claim', {'p_limit':100}) if x['object_path'] == path2)
        check('Account deletion obligation survives', row2['status'] == 'pending')
        check('Account deletion actual bytes removed', http('/storage/v1/object/study-restore', body={'prefixes':[path2]}, method='DELETE')[0] == 200 and http('/storage/v1/object/authenticated/study-restore/' + path2, raw=True)[0] != 200)
        rpc('study_object_done', {'p_ids':[row2['id']]})
    finally:
        for uid in users:
            http('/auth/v1/admin/users/' + uid, method='DELETE')
        Path('../next02-evaluation/storage-report.json').write_text(json.dumps({'environment':'disposable local Supabase Auth/Storage/Edge PostgreSQL17','checks':checks}, indent=2))

if __name__ == '__main__':
    main()
