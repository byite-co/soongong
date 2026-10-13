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
import resource
import time
import unicodedata


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


def summarize(rows,kind):
    labeled=[r for r in rows if isinstance(r.get('ground_truth'),str)]
    times=[r['seconds'] for r in rows]
    out={'attempts':len(rows),'valid':sum(r.get('valid',False) for r in rows),
         'failures':sum(r.get('error') is not None for r in rows),'empty':sum(r.get('prediction')=='' for r in rows),
         'labeled':len(labeled),'p50_seconds':quantile(times,.5),'p95_seconds':quantile(times,.95),
         'max_child_rss_kib':max((r.get('child_rss_kib',0) for r in rows),default=0),
         'external_api_calls':0,'external_api_cost_krw':0,'infrastructure_cost_krw':None,
         'confirmed_documents':None,'human_correction_time':None}
    out['timeouts']=sum(r.get('error')=='TimeoutError' for r in rows)
    out['sequential_attempts_per_hour']=3600*len(rows)/sum(times) if times and sum(times)>0 else None
    out['valid_rate']=out['valid']/len(rows) if rows else None
    if kind=='math':
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


def run(args):
    from worker import execute,checked_models
    rows=json.loads(args.manifest.read_text(encoding='utf-8-sig'));validate_split(rows)
    root,revision=checked_models()
    if os.environ.get('WORKER_MODEL_ID')!=revision:raise ValueError('model_id_mismatch')
    # Protocol is recorded and hashed before any quality prediction.
    protocol=args.protocol.read_bytes();json.loads(protocol)
    report={'model':revision,'manifest_sha256':hashlib.sha256(args.manifest.read_bytes()).hexdigest(),
      'protocol_sha256':hashlib.sha256(protocol).hexdigest(),'mode':'cold isolated child per attempt','rows':[]}
    for row in rows:
        path=row['path']
        if os.name!='nt' and path.startswith('C:\\'):path='/mnt/c/'+path[3:].replace('\\','/')
        raw=Path(path).read_bytes()
        if hashlib.sha256(raw).hexdigest()!=row['sha256']:raise ValueError('input_hash_mismatch')
        entry=dict(row);start=time.perf_counter()
        try:
            result=execute({'operation':'ocr','kind':args.kind,'image':base64.b64encode(raw).decode()},timeout=50)
            entry['prediction']='\n'.join(b['text'] for b in result['blocks'])
            entry['result']=result;entry['valid']=bool(entry['prediction'].strip());entry['error']=None
        except Exception as error:
            entry['prediction']=None;entry['valid']=False;entry['error']=type(error).__name__
        entry['seconds']=time.perf_counter()-start
        entry['child_rss_kib']=resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss
        report['rows'].append(entry);report['summary']=summarize(report['rows'],args.kind)
        args.output.write_text(json.dumps(report,ensure_ascii=False,indent=2),encoding='utf-8')
        print(f"{len(report['rows'])}/{len(rows)} valid={entry['valid']} seconds={entry['seconds']:.2f}",flush=True)


if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--manifest',type=Path,required=True)
    parser.add_argument('--protocol',type=Path,required=True);parser.add_argument('--output',type=Path,required=True)
    parser.add_argument('--kind',choices=['text','math'],required=True);run(parser.parse_args())
