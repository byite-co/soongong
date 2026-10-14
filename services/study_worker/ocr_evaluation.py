"""Local-only, full-denominator evaluation. Raw reports must stay outside Git/CI.

Input manifest is a JSON list: path, sha256, source, split, type, ground_truth,
writer_id/document_id (null when not provided). No generated identity or label.
"""
import argparse
import base64
import hashlib
import json
import math
import os
from pathlib import Path
import platform
import subprocess
import time
import unicodedata
from functools import partial
from diagnostics import parent_children_usage
from paddle_adapter import DEFAULT_CPU_THREADS


def normalize(text, spaces=True):
    text=unicodedata.normalize('NFC',text)
    return text if spaces else ''.join(text.split())


def distance(a,b):
    row=list(range(len(b)+1))
    for i,x in enumerate(a,1):
        following=[i]
        for j,y in enumerate(b,1):
            following.append(min(following[-1]+1,row[j]+1,row[j-1]+(x!=y)))
        row=following
    return row[-1]


def quantile(values,p):
    return sorted(values)[max(0,math.ceil(len(values)*p)-1)] if values else None

def grading_metrics(rows):
    marks=['correct','wrong','partial','unsolved','guessed']; truth={}; predictions={}
    for index,row in enumerate(rows):
        if not isinstance(row.get('ground_truth'),list):continue
        for item in row['ground_truth']:
            key=(index,item['page_index'],item['number'])
            if key in truth or item['mark'] not in marks:raise ValueError('invalid_ground_truth')
            truth[key]=item['mark']
        for item in row.get('prediction') or []:
            key=(index,item['page_index'],item['number'])
            if key in predictions:raise ValueError('duplicate_prediction')
            predictions[key]=item.get('mark')
    per_mark={}; f1=[]
    for mark in marks:
        tp=sum(value==mark and truth.get(key)==mark for key,value in predictions.items())
        fp=sum(value==mark and truth.get(key)!=mark for key,value in predictions.items())
        fn=sum(value==mark and predictions.get(key)!=mark for key,value in truth.items())
        precision=tp/(tp+fp) if tp+fp else None;recall=tp/(tp+fn) if tp+fn else None
        score=2*tp/(2*tp+fp+fn) if 2*tp+fp+fn else None
        per_mark[mark]={'tp':tp,'fp':fp,'fn':fn,'precision':precision,'recall':recall,'f1':score}
        if score is not None:f1.append(score)
    noncorrect=sum(m!='correct' for m in truth.values())
    return {'ground_truth_items':len(truth),'detected_items':len(predictions),'per_mark':per_mark,
      'macro_f1':sum(f1)/5 if len(f1)==5 else None,
      'number_link_precision':sum(k in truth for k in predictions)/len(predictions) if predictions else None,
      'coverage':sum(k in predictions for k in truth)/len(truth) if truth else None,
      'unknown_fraction':sum(v is None for v in predictions.values())/len(predictions) if predictions else None,
      'noncorrect_as_correct_rate':sum(v!='correct' and predictions.get(k)=='correct' for k,v in truth.items())/noncorrect if noncorrect else None}


def summarize(rows,kind):
    labeled=[r for r in rows if isinstance(r.get('ground_truth'),str)]
    times=[r['seconds'] for r in rows]
    resources=[((r.get('diagnostics') or {}).get('child') or {}).get('resource', {}) for r in rows]
    out={'attempts':len(rows),'valid':sum(r.get('valid',False) for r in rows),
         'failures':sum(r.get('error') is not None for r in rows),'empty':sum(r.get('prediction')=='' for r in rows),
         'labeled':len(labeled),'p50_seconds':quantile(times,.5),'p95_seconds':quantile(times,.95),
         'max_reported_request_self_rss_bytes': max((r['max_rss_bytes'] for r in resources
             if r.get('max_rss_bytes') is not None), default=None),
         'request_resource_samples':sum(r.get('max_rss_bytes') is not None for r in resources),
         'complete_target_resource_samples':sum(r.get('complete_target_lifetime',False) for r in resources),
         'external_api_calls':0,'external_api_cost_krw':0,'infrastructure_cost_krw':None,
         'confirmed_documents':None,'human_correction_time':None}
    out['timeouts']=sum(r.get('error')=='TimeoutError' for r in rows)
    out['resource_scope'] = 'request_child_RUSAGE_SELF_excludes_descendants; inspect per-row completeness'
    out['legacy_rss_scope'] = 'child_rss_kib in old reports is parent RUSAGE_CHILDREN cumulative high-water, not request RSS'
    out['sequential_attempts_per_hour']=3600*len(rows)/sum(times) if times and sum(times)>0 else None
    out['valid_rate']=out['valid']/len(rows) if rows else None
    admitted=[r for r in rows if r.get('input_validation',{}).get('status')=='accepted']
    rejected=[r for r in rows if r.get('input_validation',{}).get('status')=='rejected']
    matched=sum(not r.get('valid',False) and
        (((r.get('diagnostics') or {}).get('child') or {}).get('input_rejection')==r['input_validation']['reason'])
        for r in rejected)
    out['input_policy']={'accepted_attempts':len(admitted),'accepted_valid':sum(r.get('valid',False) for r in admitted),
      'accepted_valid_rate':sum(r.get('valid',False) for r in admitted)/len(admitted) if admitted else None,
      'accepted_p95_seconds':quantile([r['seconds'] for r in admitted],.95),
      'expected_rejections':len(rejected),'matched_rejections':matched,
      'unclassified_attempts':len(rows)-len(admitted)-len(rejected),
      'classification':'pre-inference input validation; all attempts remain in the original denominator'}
    if kind=='reading':
        out.update(grading_metrics(rows))
    elif kind=='math':
        out['normalized_exact_match']=sum(r.get('valid',False) and normalize(r.get('prediction',''),False)==normalize(r['ground_truth'],False) for r in labeled)/len(labeled) if labeled else None
    else:
        for spaces in [True,False]:
            denominator=sum(len(normalize(r['ground_truth'],spaces)) for r in labeled)
            errors=sum(distance(normalize(r['ground_truth'],spaces),normalize(r.get('prediction') or '',spaces)) for r in labeled)
            out['cer_with_spaces' if spaces else 'cer_without_spaces']=errors/denominator if denominator else None
    return out


def validate_split(rows):
    # Group by every PROVIDED identity, plus source. Missing IDs remain missing.
    groups={}; hashes={}
    for row in rows:
        for field in ['writer_id','document_id','source']:
            identity=row.get(field)
            if identity is None:continue
            key=(field,identity)
            if key in groups and groups[key]!=row['split']:raise ValueError('split_leakage')
            groups[key]=row['split']
        if row['sha256'] in hashes and hashes[row['sha256']]!=row['split']:raise ValueError('split_leakage')
        hashes[row['sha256']]=row['split']


def input_bytes(row):
    path=row['path']
    if os.name!='nt' and path.startswith('C:\\'):path='/mnt/c/'+path[3:].replace('\\','/')
    raw=Path(path).read_bytes()
    if hashlib.sha256(raw).hexdigest()!=row['sha256']:raise ValueError('input_hash_mismatch')
    return raw


def classify_input(raw):
    """Freeze policy eligibility before prediction; never relabel model EOF."""
    from worker import decode_image,ImageInputRejected
    from PIL import Image
    import io
    value={'bytes':len(raw),'format':None,'frames':None,'width_after_exif':None,'height_after_exif':None}
    try:
        image=decode_image(base64.b64encode(raw).decode())
        try:
            value.update(width_after_exif=image.width,height_after_exif=image.height,pixels=image.width*image.height)
        finally:image.close()
        with Image.open(io.BytesIO(raw)) as original:
            value.update(format=original.format,frames=getattr(original,'n_frames',1))
        value.update(status='accepted',reason=None)
    except ImageInputRejected as error:
        value.update(status='rejected',reason=error.reason)
    return value


def code_provenance():
    folder=Path(__file__).resolve().parent
    names=('worker.py','process_ipc.py','diagnostics.py','ocr_evaluation.py','paddle_adapter.py','unimernet_adapter.py')
    values={'files_sha256':{n:hashlib.sha256((folder/n).read_bytes()).hexdigest() for n in names}}
    try:
        values['commit']=subprocess.check_output(['git','rev-parse','HEAD'],cwd=folder,text=True,stderr=subprocess.DEVNULL).strip()
        values['tracked_changes']=bool(subprocess.check_output(['git','diff','HEAD','--name-only'],cwd=folder))
    except (OSError,subprocess.CalledProcessError):values['commit']=None
    return values


def paddle_evaluation_child(body, connection, *, cpu_threads):
    """Local evaluation override; the HTTP worker uses the adapter default.

    Spawned child mutation cannot affect the evaluator or a serving worker.
    All image validation, limits, process cleanup and receipt paths remain in
    worker.child. Requested native concurrency is not an observed thread count.
    """
    import paddle_adapter
    from worker import child
    original=paddle_adapter.load
    paddle_adapter.load=partial(original, cpu_threads=cpu_threads)
    try:child(body, connection)
    finally:paddle_adapter.load=original


def run(args):
    from worker import execute,checked_models
    rows=json.loads(args.manifest.read_text(encoding='utf-8-sig'));validate_split(rows)
    repetitions=getattr(args,'repetitions',1)
    if type(repetitions) is not int or not 1<=repetitions<=3:raise ValueError('invalid_repetitions')
    threads=getattr(args,'paddle_cpu_threads',None)
    if threads is not None and (type(threads) is not int or threads not in (1,2,4) or args.kind=='math'):
        raise ValueError('invalid_paddle_thread_comparison')
    destination=args.output.resolve()
    if destination.is_relative_to(Path(__file__).resolve().parents[2]):raise ValueError('raw_report_must_be_outside_repository')
    if args.output.exists():raise ValueError('report_already_exists')
    root,revision=checked_models()
    if os.environ.get('WORKER_MODEL_ID')!=revision:raise ValueError('model_id_mismatch')
    # Protocol is recorded and hashed before any quality prediction.
    protocol=args.protocol.read_bytes();json.loads(protocol)
    report={'model':revision,'manifest_sha256':hashlib.sha256(args.manifest.read_bytes()).hexdigest(),
      'protocol_sha256':hashlib.sha256(protocol).hexdigest(),'mode':'cold isolated child per attempt',
      'runtime': {'python': platform.python_version(), 'system': platform.system(), 'machine': platform.machine()},
      'resource_protocol': {'request': 'child RUSAGE_SELF sampled at stages and target return; excludes descendants',
        'parent': 'RUSAGE_CHILDREN cumulative waited-for children; CPU delta may include other children; RSS never differenced',
        'gpu': 'unmeasured'}, 'code':code_provenance(),
      'models_lock_sha256':hashlib.sha256((root/'models.lock.json').read_bytes()).hexdigest(),
      'repetitions':repetitions,'rows':[],
      'paddle_cpu_threads_requested':threads if threads is not None else DEFAULT_CPU_THREADS if args.kind!='math' else None,
      'native_active_threads':'unverified; requested constructor setting is not observed native concurrency'}
    # Validate every input and fix eligible/rejected strata before any attempt.
    # Repeat failures stay in their original stratum; no post-hoc exclusions.
    prepared=[{**row,'input_validation':classify_input(input_bytes(row))} for row in rows]
    report['preflight_inputs']=prepared
    attempts=[(row,repetition) for repetition in range(1,repetitions+1) for row in prepared]
    # Exclusive creation protects previous raw evidence. Keep this descriptor
    # for progress snapshots; no user-supplied path is passed to the worker.
    with args.output.open('x',encoding='utf-8') as stream:
      stream.write(json.dumps(report,ensure_ascii=False,indent=2));stream.flush()
      for row,repetition in attempts:
        raw=input_bytes(row)
        entry=dict(row);start=time.perf_counter()
        entry['repetition']=repetition
        diagnostics={}; usage_before=parent_children_usage()
        try:
            body={'operation':'reading','page_index':row.get('page_index',0)} if args.kind=='reading' else {'operation':'ocr','kind':args.kind}
            options={'_target':partial(paddle_evaluation_child,cpu_threads=threads)} if threads is not None else {}
            result=execute({**body,'image':base64.b64encode(raw).decode()},timeout=50,diagnostics=diagnostics,**options)
            if args.kind=='reading':
                entry['prediction']=[{'page_index':p['index'],**item} for p in result['pages'] for item in p['items']]
            else:entry['prediction']='\n'.join(b['text'] for b in result['blocks'])
            entry['result']=result;entry['valid']=bool(entry['prediction']);entry['error']=None
        except Exception as error:
            entry['prediction']=None;entry['valid']=False;entry['error']=type(error).__name__
        entry['seconds']=time.perf_counter()-start
        entry['diagnostics']=diagnostics
        usage_after=parent_children_usage()
        entry['parent_children_usage']={'scope':'all_terminated_reaped_children_of_evaluator',
          'user_cpu_delta_seconds':usage_after['user_cpu_seconds']-usage_before['user_cpu_seconds'],
          'system_cpu_delta_seconds':usage_after['system_cpu_seconds']-usage_before['system_cpu_seconds'],
          'cumulative_max_rss_bytes':usage_after['max_rss_bytes'],
          'request_attribution':False}
        report['rows'].append(entry);report['summary']=summarize(report['rows'],args.kind)
        stream.seek(0);stream.write(json.dumps(report,ensure_ascii=False,indent=2));stream.truncate();stream.flush()
        print(f"{len(report['rows'])}/{len(attempts)} valid={entry['valid']} seconds={entry['seconds']:.2f}",flush=True)


if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--manifest',type=Path,required=True)
    parser.add_argument('--protocol',type=Path,required=True);parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--kind',choices=['text','math','reading'],required=True)
    parser.add_argument('--repetitions',type=int,choices=(1,2,3),default=1)
    parser.add_argument('--paddle-cpu-threads',type=int,choices=(1,2,4),default=None)
    run(parser.parse_args())
