"""Explicit provisioning only. Inference never imports this downloader."""
import argparse
import hashlib
import json
from pathlib import Path
import urllib.request
import urllib.parse


def provision(profile,destination):
    manifest=Path(__file__).with_name('models')/(profile+'.json')
    data=json.loads(manifest.read_text(encoding='utf-8-sig'))
    sources=data['sources']; prefixes=['model'] if profile=='unimernet-tiny' else ['detection','korean']
    mappings=dict(zip(prefixes,sources,strict=True))
    destination.mkdir(parents=True,exist_ok=True)
    for name,expected in data['files'].items():
        prefix,filename=name.split('/',1);source=mappings[prefix]
        target=destination/name
        if not target.resolve().is_relative_to(destination.resolve()) or target.is_symlink():raise ValueError('unsafe_model_path')
        target.parent.mkdir(parents=True,exist_ok=True)
        if target.exists():
            if hashlib.sha256(target.read_bytes()).hexdigest()!=expected:raise ValueError('existing_model_hash_mismatch')
            continue
        url=f"https://huggingface.co/{source['repository']}/resolve/{source['commit']}/{urllib.parse.quote(filename)}"
        part=target.with_name(target.name+'.part')
        urllib.request.urlretrieve(url,part)
        with part.open('rb') as stream:actual=hashlib.file_digest(stream,'sha256').hexdigest()
        if actual!=expected:raise ValueError('download_hash_mismatch')
        part.replace(target)
    (destination/'models.lock.json').write_text(json.dumps(data,indent=2),encoding='utf-8')


if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('profile',choices=['paddle-v3','paddle-v5','unimernet-tiny']);p.add_argument('destination',type=Path)
    args=p.parse_args();provision(args.profile,args.destination)
