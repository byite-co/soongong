"""Real pinned models; synthetic grading smoke / warm math execution, not quality.
Run in the respective locked environment. All images/reports outside Git.
"""
import argparse
import base64
import hashlib
import json
import os
from pathlib import Path
import resource
import sys
import time
import threading
import urllib.request
from http.server import ThreadingHTTPServer
sys.path.insert(0,str(Path(__file__).resolve().parents[1]/'services/study_worker'))
from PIL import Image, ImageDraw, ImageFont
from worker import checked_models, execute, Handler

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--kind', choices=['grading','math'], required=True)
    args=parser.parse_args(); root, revision=checked_models(); out=Path('../next02-evaluation')
    if args.kind=='grading':
        image=Image.new('RGB',(1000,600),'white');draw=ImageDraw.Draw(image)
        font=ImageFont.truetype('/mnt/c/Windows/Fonts/malgun.ttf',42)
        for i in range(5):draw.text((150,30+i*110),f'{i+1}. 문항 확인',fill='black',font=font)
        draw.ellipse((50,25,110,85),outline='red',width=6)
        draw.line((50,135,110,195),fill='red',width=6);draw.line((50,195,110,135),fill='red',width=6)
        draw.polygon([(80,245),(48,303),(112,303)],outline='red',width=6)
        path=out/'synthetic-grading.png';image.save(path)
        body={'operation':'reading','page_index':0,'image':base64.b64encode(path.read_bytes()).decode()}
        os.environ['WORKER_SECRET']='synthetic-smoke-only-not-a-production-secret'
        envelope={'version':2,'attempt_id':'11111111-1111-4111-8111-111111111111','provider':'local','model':revision,'limits':{'max_input_tokens':1,'max_output_tokens':1,'max_attempts':1},'input':{'schema_version':1,'purge_epoch':0,'consent_version':'study-2026-10-13',**body}}
        server=ThreadingHTTPServer(('127.0.0.1',0),Handler);thread=threading.Thread(target=server.serve_forever,daemon=True);thread.start()
        start=time.perf_counter()
        try:
            req=urllib.request.Request(f'http://127.0.0.1:{server.server_port}/infer',data=json.dumps(envelope).encode(),headers={'Authorization':'Bearer '+os.environ['WORKER_SECRET'],'Content-Type':'application/json'})
            with urllib.request.urlopen(req,timeout=55) as response:result=json.load(response)
            assert result['usage']['images']==1 and result['result']['schema_version']==2
        finally: server.shutdown();server.server_close();thread.join()
        cold=time.perf_counter()-start
        from paddle_adapter import load, recognize, grading
        engine=load(root); warm=[]
        for _ in range(5):
            start=time.perf_counter();last=grading(image,recognize(image,engine),0);warm.append(time.perf_counter()-start)
    else:
        path=Path('../next02-datasets/unimer-cpe-60/manifest.json');rows=json.loads(path.read_text());path=Path('/mnt/c/'+rows[0]['path'][3:].replace('\\','/'))
        image=Image.open(path).convert('RGB')
        from unimernet_adapter import load, recognize
        start=time.perf_counter();engine=load(root);load_seconds=time.perf_counter()-start
        warm=[]
        for _ in range(5):
            start=time.perf_counter();last=recognize(image,root,engine);warm.append(time.perf_counter()-start)
        result={'model_load_seconds':load_seconds};cold=None
    report={'model':revision,'kind':args.kind,'input_sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'cold_seconds':cold,'warm_seconds':warm,'result':result,'warm_result':last,'parent_max_rss_kib':resource.getrusage(resource.RUSAGE_SELF).ru_maxrss,'child_max_rss_kib':resource.getrusage(resource.RUSAGE_CHILDREN).ru_maxrss,'external_api_calls':0}
    (out/(args.kind+'-smoke.json')).write_text(json.dumps(report,ensure_ascii=False,indent=2))
    print(json.dumps({k:v for k,v in report.items() if k not in ('result','warm_result')}))
if __name__=='__main__': main()
