#!/usr/bin/env python3
"""Derive per-book Spanish chapter counts from the BUNDLED Torres Amat text.

books.json's `chapters` counts come from the English Douay-Rheims text
(dr_bible.json). The bundled Spanish Torres Amat text (sp_bible.json)
divides 19 books into MORE chapters, so Spanish navigation needs its own
per-book count. This script counts the chapters actually present in
sp_bible.json, book by book, and writes them into books.json as
`chapters_es` — never hand-typed from an external edition.

Run after any change to assets/bible/sp_bible.json:
    python3 tool/gen_spanish_chapter_counts.py

Guarded by test/bible_spanish_boundaries_test.dart, which re-counts the
bundled Spanish text and fails when books.json drifts from it.
"""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BOOKS = os.path.join(ROOT, 'assets', 'bible', 'books.json')
SPANISH = os.path.join(ROOT, 'assets', 'bible', 'sp_bible.json')


def main() -> int:
    with open(BOOKS, encoding='utf-8') as f:
        data = json.load(f)
    with open(SPANISH, encoding='utf-8') as f:
        spanish = json.load(f)

    changed = 0
    for book in data['books']:
        key = book['key']
        if key not in spanish:
            print(f'ERROR: {key} missing from sp_bible.json', file=sys.stderr)
            return 1
        bookData = spanish[key]
        # Count the chapter entries that are integer chapter numbers.
        count = sum(1 for k in bookData if k.isdigit())
        keys = sorted(int(k) for k in bookData if k.isdigit())
        if keys != list(range(1, count + 1)):
            print(f'ERROR: {key} chapter keys not contiguous 1..{count}',
                  file=sys.stderr)
            return 1
        if book.get('chapters_es') != count:
            book['chapters_es'] = count
            changed += 1

    with open(BOOKS, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=1, ensure_ascii=False)
        f.write('\n')
    print(f'books.json updated: {changed} book(s) changed, '
          f"{len(data['books'])} books total")
    return 0


if __name__ == '__main__':
    sys.exit(main())
