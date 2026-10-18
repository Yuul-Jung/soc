#!/usr/bin/env python3
"""(추가) 표준 라이브러리로 배포 파일 정합성을 검사한다. 하드웨어 검증 아님."""
from pathlib import Path
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
import hashlib
import json
import zipfile

class Page(HTMLParser):
    def __init__(self, text):
        super().__init__(convert_charrefs=True)
        self.ids = set()
        self.duplicate_ids = []
        self.refs = []
        self.feed(text)
    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        key = attrs.get('id')
        if key:
            if key in self.ids:
                self.duplicate_ids.append(key)
            self.ids.add(key)
        for key in ('href', 'src'):
            if attrs.get(key):
                self.refs.append(attrs[key])
    handle_startendtag = handle_starttag

def main():
    root = Path(__file__).resolve().parent.parent
    errors = []
    sums = root / '00_overview/SHA256SUMS.txt'
    files = 0
    for line in sums.read_text(encoding='utf-8').splitlines():
        if not line.strip():
            continue
        digest, name = line.split('  ', 1)
        file = root / name
        if not file.is_file() or hashlib.sha256(file.read_bytes()).hexdigest() != digest:
            errors.append(f'hash: {name}')
        files += 1
    pages = {}
    for p in root.rglob('*.html'):
        try:
            text = p.read_text(encoding='utf-8')
            if '\ufffd' in text:
                errors.append(f'encoding: {p.relative_to(root)}')
            pages[p.resolve()] = Page(text)
        except (UnicodeError, ValueError) as exc:
            errors.append(f'HTML: {p.relative_to(root)}: {exc}')
    refs = 0
    for p, page in pages.items():
        errors.extend(f'duplicate id: {p.relative_to(root)}#{key}' for key in page.duplicate_ids)
        for ref in page.refs:
            url = urlsplit(ref)
            if url.scheme or url.netloc:
                continue
            target = (p.parent / unquote(url.path)).resolve() if url.path else p
            refs += 1
            if not target.exists():
                errors.append(f'link: {p.relative_to(root)} -> {ref}')
            elif url.fragment and target in pages and unquote(url.fragment) not in pages[target].ids:
                errors.append(f'anchor: {p.relative_to(root)} -> {ref}')
    archives = 0
    for p in (root / 'packages').rglob('*.zip'):
        try:
            with zipfile.ZipFile(p) as z:
                failed = z.testzip()
                if failed:
                    errors.append(f'ZIP CRC: {p.name}: {failed}')
        except zipfile.BadZipFile:
            errors.append(f'ZIP format: {p.name}')
        archives += 1
    print(json.dumps({'status': 'FAIL' if errors else 'PASS', 'hashed_files': files,
                      'html_pages': len(pages), 'local_references': refs,
                      'zip_archives': archives, 'errors': errors,
                      'scope': 'distribution only; not target build or board verification'},
                     ensure_ascii=False, indent=2))
    return 1 if errors else 0

if __name__ == '__main__':
    raise SystemExit(main())
