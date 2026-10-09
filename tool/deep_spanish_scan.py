#!/usr/bin/env python3
"""Deep scan: find remaining English UI strings in Fidelis screens.

Walks lib/**/*.dart screen files, extracts user-facing string literals,
and flags those that read as English (common-EN words, no Spanish marks).
Data/config files are skipped — their strings are intentional content.
Output: file:line  string  (the fix-list for the sweep).
"""
import re, glob, sys

DATA_FILES = (
    'app_strings', 'prayer_translations', 'rosary_prayers', 'rosary_controller',
    'chaplet_prayers', 'chaplet_data', 'mystery_data', 'novena_data',
    'missal_service', 'usccb_service', 'missal_cache', 'bible_books',
    'litany_of_loreto', 'constants', 'routes', 'theme', 'main', 'app',
    'notification_service', 'stations_data', 'rosary_state', 'novena_storage',
    'reflection_service', 'litany_reader_screen',
)
UI_CONTEXT = re.compile(
    r"""(?:Text\(\s*|label:\s*|title:\s*|tooltip:\s*|hintText:\s*|labelText:\s*"""
    r"""|subtile:\s*|subtitle:\s*|content:\s*|body:\s*|child:\s*)(r?'([^']{3,200})'|\"([^\"]{3,200})\")"""
)
EN_WORD = re.compile(
    r"""\b(the|and|of|to|in|is|it|for|on|with|my|your|his|her|our|you|we|are|was|not|Jesus|Mary|God|prayer|pray|day|night|Holy|Cross|Heart|Lord|name|Rosary|be|have|mercy|grace|peace|soul|Christ|church|mass|readings|settings|home|today|please|will|this|that|from|enter|save|leave|stay|exit|complete|progress|reminder|time|hours|minutes|search|no|data|available|date|check|connection|try|again|unable|load|error)\b"""
)
ES_MARK = re.compile(r"[áéíóúñ¿¡ÁÉÍÓÚÑ]")

def is_englishish(s: str) -> bool:
    if ES_MARK.search(s):
        return False
    return len(EN_WORD.findall(s)) >= 2

def main():
    report = []
    for path in sorted(glob.glob('lib/**/*.dart', recursive=True)):
        short = path.replace('lib/', '').replace('.dart', '')
        if any(part in short for part in DATA_FILES):
            continue
        src = open(path, encoding='utf-8').read()
        for i, line in enumerate(src.split('\n'), 1):
            if line.strip().startswith('//') or 'import' in line[:12]:
                continue
            for m in UI_CONTEXT.finditer(line):
                lit = next((g for g in m.groups()[1:] if g), None)
                if not lit:
                    continue
                lit = lit.lstrip('r').strip('"') or lit.lstrip('r').strip("'")
                if "''' " in line or "'''" in line:
                    continue
                if any(p in lit for p in ('assets/', 'http', '.cfm', '0x', '{{')):
                    continue
                if re.fullmatch(r"[0-9.]+[A-Za-z:]*", lit):
                    continue
                if is_englishish(lit):
                    report.append(f"{short}.dart:{i}: {lit[:110]}")
    print(f"ENGLISH REMNANTS: {len(report)}")
    for r in report:
        print(r)

main()
