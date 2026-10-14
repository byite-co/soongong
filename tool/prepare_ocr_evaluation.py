"""Explicit public evaluation download. Images/labels must remain outside Git.
Rights/source notices are retained; all data local-only, no API upload.
"""
import argparse
import hashlib
import json
from pathlib import Path
import urllib.parse
import urllib.request
import zipfile

KOREAN='HumynLabs/Korean_Handwritten_Notes_Dataset'
KREV='425a7a3cb6b8dd00ffb4b4cf998d37f4509ab154'
MATH='wanderkid/UniMER_Dataset'
MREV='2343ddd963290469da36ca83e3a56c66e068add9'
ZIP_SHA='9bf370b8cac868fee84835f40dec26c477430611253e3feb681356a8149a3a90'

def download(url, path):
    path.parent.mkdir(parents=True,exist_ok=True)
    if not path.exists():urllib.request.urlretrieve(url,path)
    return hashlib.sha256(path.read_bytes()).hexdigest()

def prepare(root):
    root=root.resolve();root.mkdir(parents=True,exist_ok=True)
    repo=Path(__file__).resolve().parents[1]
    if root.is_relative_to(repo):raise ValueError('dataset_must_be_outside_repository')
    info=json.load(urllib.request.urlopen(f'https://huggingface.co/api/datasets/{KOREAN}/revision/{KREV}'))
    korean=root/'korean-notes';rows=[]
    for entry in info['siblings']:
        name=entry['rfilename']
        if name=='.gitattributes':continue
        path=korean/name
        if not path.resolve().is_relative_to(korean):raise ValueError('invalid_source_path')
        source=f'https://huggingface.co/datasets/{KOREAN}/resolve/{KREV}/{urllib.parse.quote(name)}'
        digest=download(source,path)
        if path.suffix.lower() not in ('.jpg','.jpeg'):continue
        rows.append({'path':str(path),'sha256':digest,'source':KOREAN,'id':name,'split':'source_holdout',
          'type':'real_or_simulated_unknown','ground_truth':None,'writer_id':None,'document_id':None,
          'license':'CC-BY-4.0 with card restrictions; no individual style commercial reuse','local_only':True})
    (korean/'manifest.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2))
    # Explicit derivative for research; the product continues to reject MPO.
    from PIL import Image
    derived=[];folder=root/'korean-notes-first-frame';folder.mkdir(exist_ok=True)
    for row in rows:
        path=Path(row['path']);dest=folder/(path.stem+'.png')
        with Image.open(path) as im:
            frames=getattr(im,'n_frames',1);im.seek(0);im.convert('RGB').save(dest)
        derived.append({**row,'path':str(dest),'original_path':str(path),'original_sha256':row['sha256'],
          'sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),'transform':{'type':'explicit first frame of unsupported MPO container to RGB PNG','original_frames':frames,'frame_index':0}})
    (folder/'manifest.json').write_text(json.dumps(derived,ensure_ascii=False,indent=2))
    archive=root/'UniMER-Test.zip';url=f'https://huggingface.co/datasets/{MATH}/resolve/{MREV}/'
    if download(url+'UniMER-Test.zip',archive)!=ZIP_SHA:raise ValueError('archive_hash_mismatch')
    folder=root/'unimer-cpe-60';folder.mkdir(exist_ok=True)
    download(url+'README.md',folder/'README-source.md')
    with zipfile.ZipFile(archive) as z:
        names=sorted(n for n in z.namelist() if n.startswith('UniMER-Test/cpe/') and n.endswith('.png'))
        labels=z.read('UniMER-Test/cpe.txt').decode().splitlines()
        if len(names)!=len(labels) or any(Path(n).stem!=f'{i:07d}' for i,n in enumerate(names)):raise ValueError('label_file_alignment_changed')
        rows=[]
        for i,name in enumerate(names[:60]):
            dest=folder/Path(name).name;dest.write_bytes(z.read(name))
            rows.append({'id':dest.stem,'path':str(dest),'sha256':hashlib.sha256(dest.read_bytes()).hexdigest(),
              'ground_truth':labels[i],'source':'UniMER-Test/CPE','source_file':name,'label_file':'UniMER-Test/cpe.txt','label_line':i+1,
              'writer_id':None,'document_id':None,'type':'printed','split':'source_holdout','license':'Apache-2.0 as publisher card; original per-document license not supplied','local_only':True})
    (folder/'manifest.json').write_text(json.dumps(rows,ensure_ascii=False,indent=2))
    print(json.dumps({'root':str(root),'korean_regions':len(derived),'math_printed_regions':len(rows),'external_upload':False}))

if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('destination',type=Path);prepare(p.parse_args().destination)
