"""Capture dependency/license metadata without credentials or user inputs."""
import argparse
import importlib.metadata as md
import json
import platform
from pathlib import Path

if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('output',type=Path);args=parser.parse_args()
    packages=[]
    for dist in md.distributions():
        meta=dist.metadata
        packages.append({'name':meta['Name'],'version':dist.version,
          'license_expression':meta.get('License-Expression'),
          'license_declared':(meta.get('License') or '')[:200],
          'license_classifiers':[v for v in (meta.get_all('Classifier') or []) if v.startswith('License ::')],
          'home_page':meta.get('Home-page')})
    args.output.write_text(json.dumps({'python':platform.python_version(),'system':platform.platform(),
      'scope':'Installed distribution metadata; not legal approval of redistribution; preserve each license file.',
      'packages':sorted(packages,key=lambda p:p['name'].lower())},indent=2))
