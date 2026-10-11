#!/usr/bin/env python3
"""Harvest v2: one tree-API call for all paths, concurrent raw downloads, progressive save."""
import json, re, os, sys, time, urllib.request, concurrent.futures as cf

REPO_RAW = "https://raw.githubusercontent.com/DivinumOfficium/divinum-officium/master/web/www/missa/Espanol"
TREE_API = "https://api.github.com/repos/DivinumOfficium/divinum-officium/git/trees/master?recursive=1"
OUT = "tool/propers_es/raw_files.json"

def req(url, timeout=30):
    r = urllib.request.Request(url, headers={'User-Agent': 'fidelis-harvest'})
    return urllib.request.urlopen(r, timeout=timeout).read()

def main():
    tree = json.loads(req(TREE_API))
    paths = [t['path'] for t in tree.get('tree', [])
             if t['path'].startswith('web/www/missa/Espanol/') and t['type'] == 'blob'
             and t['path'].endswith('.txt')]
    print(f'found {len(paths)} Espanol txt files', flush=True)

    def fetch(rel):
        short = rel.replace('web/www/missa/Espanol/', '')
        try:
            txt = req(f"{REPO_RAW}/{short}").decode('utf-8', errors='replace')
            return (short, txt)
        except Exception as e:
            return (short, None)

    data = {}
    with cf.ThreadPoolExecutor(max_workers=12) as ex:
        for i, (k, v) in enumerate(ex.map(fetch, paths)):
            data[k] = v
            if (i+1) % 50 == 0:
                print(f'{i+1}/{len(paths)} fetched', flush=True)
                with open(OUT, 'w') as f:
                    json.dump(data, f)
    with open(OUT, 'w') as f:
        json.dump(data, f)
    ok = sum(1 for v in data.values() if v)
    print(f'done: {ok}/{len(paths)} fetched OK', flush=True)

main()
