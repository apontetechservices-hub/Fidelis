#!/usr/bin/env python3
"""Parse harvested DivinumOfficium Espanol txt files -> propers_es.json bundle
in the app's Proper format (info + sections with [label, english-pair-body]).
The English slot[0] will carry the SPANISH text (it's the primary display slot);
Latin stays as slot[1] from the Latin folder lookups at display-time.
"""
import json, re, os

SRC = 'tool/propers_es/raw_files.json'
OUT = 'assets/propers_es.json'

SECTION_LABELS = {
    'Introitus': 'Introito', 'IntroitusP': 'Introito', 'Oratio': 'Colecta',
    'Oratio Jesus Serviens': 'Colecta', 'Lectio': 'Ep\u00edstola', 'LectioL': 'Ep\u00edstola',
    'Graduale': 'Gradual', 'GradualeP': 'Gradual', 'Tractus': 'Tracto',
    'Evangelium': 'Evangelio', 'EvangeliumP': 'Evangelio',
    'Offertorium': 'Ofertorio', 'OffertoriumP': 'Ofertorio',
    'Secreta': 'Secreto', 'Prefatio': 'Prefacio', 'Communio': 'Comuni\u00f3n',
    'Postcommunio': 'Postcomuni\u00f3n', 'Super populum': 'Oraci\u00f3n sobre el pueblo',
}

def parse_txt(txt):
    rank = ''
    title = ''
    colors = []
    rule = set()
    sections = []
    cur_key = None
    cur_buf = []
    def flush():
        nonlocal cur_key, cur_buf
        if cur_key and cur_buf:
            text = '\n'.join(cur_buf).strip()
            if text:
                sections.append({'key': cur_key, 'text': text})
        cur_key, cur_buf = None, []
    for line in txt.split('\n'):
        m = re.match(r'^\[([A-Za-z ]+)\]', line)
        if m:
            flush()
            cur_key = m.group(1).strip()
            continue
        if cur_key == 'Rank' and line.strip() and not rank:
            rank = line.strip()
        elif cur_key == 'Info':
            if line.startswith('!') and not title:
                title = line.lstrip('!').strip()
            elif '::' in line:
                continue
        elif cur_key in ('Rule', 'Regla'):
            rule.add(line.strip())
    flush()
    return {'rank': rank, 'title': title, 'sections': sections, 'rules': sorted(rule)}

def main():
    raw = json.load(open(SRC))
    out = {}
    for path, txt in raw.items():
        if not txt: continue
        kind, _, name = path.partition('/')
        keyname = name[:-4] if name.endswith('.txt') else name
        full = f'{kind}/{keyname}'  # e.g. Sancti/01-06
        parsed = parse_txt(txt)
        if parsed['sections']:
            out[full] = parsed
    data = {
        'generated': 'from DivinumOfficium divinum-officium (Espanol) — open-license liturgy project',
        'entries': out,
    }
    os.makedirs('assets', exist_ok=True)
    with open(OUT, 'w', encoding='utf-8') as f:
        json.dump(data, f, ensure_ascii=False, separators=(',', ':'))
    print(f'bundle: {len(out)} entries -> {OUT} ({os.path.getsize(OUT)//1024} KB)')

main()
