#!/usr/bin/env python3
"""Harvest Spanish propers from DivinumOfficium repo (open-license project).
Downloads Espanol txt files -> parses rubric format -> builds propers_es bundle
for the Fidelis app (offline Lecturas in Spanish).
"""
import json, re, os, sys, time, urllib.request

REPO_RAW = "https://raw.githubusercontent.com/DivinumOfficium/divinum-officium/master/web/www/missa/Espanol"
API_LIST = "https://api.github.com/repos/DivinumOfficium/divinum-officium/contents/web/www/missa/Espanol"

MONTHS = {f"{m:02d}": ["", "Enero","Febrero","Marzo","Abril","Mayo","Junio","Julio",
    "Agosto","Septiembre","Octubre","Noviembre","Diciembre"][m] for m in range(1,13)}
DAYS = {1:'Lunes',2:'Martes',3:'Miércoles',4:'Jueves',5:'Viernes',6:'Sábado',7:'Domingo'}

SECTION_MAP = {
    'Introitus': 'Introito', 'Oratio': 'Colecta', 'Lectio': 'Epístola',
    'Graduale': 'Gradual', 'GradualeP': 'Gradual', 'Tractus': 'Tracto',
    'Evangelium': 'Evangelio', 'Offertorium': 'Ofertorio', 'Secreta': 'Secreto',
    'Prefatio': 'Prefacio', 'Communio': 'Comunión', 'Postcommunio': 'Postcomunión',
    'Credo': 'Credo', 'Super populum': 'Oración sobre el pueblo',
    'Adiutorium': 'Ayúdanos', 'Alleluja': 'Aleluya', 'Alleluia': 'Aleluya',
}

def list_dir(sub):
    req = urllib.request.Request(f"{API_LIST}/{sub}", headers={'User-Agent':'fidelis-harvest'})
    return [e['name'] for e in json.load(urllib.request.urlopen(req, timeout=30)) if e['type']=='file']

def fetch(path, tries=3):
    for t in range(tries):
        try:
            req = urllib.request.Request(f"{REPO_RAW}/{path}", headers={'User-Agent':'fidelis-harvest'})
            return urllib.request.urlopen(req, timeout=30).read().decode('utf-8', errors='replace')
        except Exception as e:
            if t == tries-1: return None
            time.sleep(1.5*(t+1))

def parse_txt(txt):
    """Parse DivinumOfficium format: [Section] name lines + content lines."""
    out = {'rank': '', 'rule': '', 'sections': []}
    cur = None
    buf = []
    for line in txt.split('\n'):
        m = re.match(r'^\[([A-Za-z \)\(\d]+)\]', line)
        if m:
            if cur and buf: out['sections'].append((cur, '\n'.join(buf).strip()))
            cur, buf = m.group(1).strip(), []
            meta = line[m.end():].strip()
            if meta: buf.append(meta)
        elif cur is not None:
            buf.append(line)
    if cur and buf: out['sections'].append((cur, '\n'.join(buf).strip()))
    return out

def harvest(subdirs=('Sancti','Tempora','Commune')):
    files = {}
    for sub in subdirs:
        names = list_dir(sub)
        print(f'{sub}: {len(names)} files')
        for name in names:
            txt = fetch(f'{sub}/{name}')
            if txt: files[f'{sub}/{name}'] = txt
        time.sleep(0.5)
    return files

if __name__ == '__main__':
    data = harvest()
    import pickle
    with open('tool/propers_es/raw_text.pkl','wb') as f:
        pickle.dump(data, f)
    print(f'harvested {len(data)} files total')
