#!/usr/bin/env python3

import collections
import json
import os
import re
import shutil
import sqlite3
import subprocess

from lz4.block import compress as lz4_compress
from lz4.block import decompress as lz4_decompress
from pathlib import Path


def mozlz4_decompress(data):
    if len(data) < 8 or data[:8] != b'mozLz40\0':
        raise Exception('Invalid mozlz4 header')
    return lz4_decompress(data[8:])


def mozlz4_compress(data):
    return b'mozLz40\0' + lz4_compress(data)


def tweak_search(filename):
    with open(filename, 'rb') as fp:
        data = fp.read()

    data = json.loads(mozlz4_decompress(data))

    n = 2
    for e in data.get('engines', []):
        if 'Google' not in e.get('_name'):
            e['_metaData'] = {'order': n, 'alias': None, 'hidden': True}
            n += 1
            continue

        e['_metaData'] = {'order': 1}
        for u in e.get('_urls', []):
            client = False
            hl = False
            for p in u.get('params', []):
                if p.get('name', '') == 'client':
                    client = True
                if p.get('name', '') == 'hl':
                    hl = True

            if client and not hl:
                u.setdefault('params', []).append({'name': 'hl', 'value': 'en'})

    data = mozlz4_compress(json.dumps(data).encode('utf-8'))
    with open(filename, 'wb') as fp:
        fp.write(data)


def read_prefs(filename):
    out = subprocess.check_output(['cpp', '-fpreprocessed', filename])

    for line in out.decode('utf-8').split('\n'):
        line = line.strip()
        if line == '' or line.startswith('#'): continue

        m = re.match(r'^user_pref\("([^"]+)",\s+("(?:[^"\\]|\\")*"|[^") ]+)\);(\s+//.*|)$', line)
        if m is None:
            raise Exception('Bad pref line: %s' % line)

        key, val = m.group(1), m.group(2)
        yield key, val


def gen_prefs():
    prefs = collections.OrderedDict()

    downloads_path = Path('~/Downloads').expanduser().resolve()
    prefs['browser.download.dir'] = '"%s"' % downloads_path

    if os.environ.get('HIDPI') == '1':
        prefs['browser.uidensity'] = '1'
    else:
        prefs['browser.uidensity'] = '0'

    for filename in ['user.pyllyukko.js', 'user.ghacks.js', 'user.js']:
        print(filename)
        count = 0
        for key, val in read_prefs(filename):
            if key == '_user.js.parrot': continue

            if key in prefs:
                if prefs[key] == val:
                    if filename == 'user.js':
                        print('  redundant %s: %s' % (key, val))
                    continue
                print('  override %s: %s -> %s' % (key, prefs[key], val))
                prefs[key] = val
            else:
                prefs[key] = val
                count += 1

        print('  +%d prefs' % count)

    return prefs


def sanitize_cookies(cookies_sqlite_path):
    con = sqlite3.connect(cookies_sqlite_path)
    cur = con.cursor()

    def get_domains():
        return set(row[0] for row in
                   cur.execute('SELECT DISTINCT baseDomain FROM moz_cookies'))
    old_domains = get_domains()

    badcookies = [[line.strip()] for line in open('badcookies.txt')]
    cur.executemany('DELETE FROM moz_cookies WHERE baseDomain = ?;', badcookies)
    con.commit()

    new_domains = get_domains()
    if new_domains != old_domains:
        print('Removed cookies from domains: %s' %
              ' '.join(sorted(old_domains - new_domains)))

    if len(new_domains) > 0:
        print('\033[33mWARNING:\033[0m remaining cookie domains: %s' %
              ' '.join(sorted(new_domains)))


def tweak_profile(profile_path, prefs):
    with (profile_path / 'user.js').open('w') as fp:
        for key, val in prefs.items():
            fp.write('user_pref("%s", %s);\n' % (key, val))
    print('Wrote %s/user.js' % profile_path)

    shutil.copy('handlers.json', profile_path / 'handlers.json')
    print('Wrote %s/handlers.json' % profile_path)

    if (profile_path / 'search.json.mozlz4').exists():
        tweak_search(profile_path / 'search.json.mozlz4')
        print('Wrote %s/search.json.mozlz4' % profile_path)

    if (profile_path / 'places.sqlite').exists():
        con = sqlite3.connect((profile_path / 'places.sqlite').as_posix())
        con.execute('''
            DELETE FROM moz_bookmarks WHERE id IN (
                SELECT moz_bookmarks.id
                FROM moz_bookmarks
                INNER JOIN moz_places ON moz_places.id = moz_bookmarks.fk
                WHERE url LIKE "%%mozilla.org/%%"
            );
            ''')
        con.close()
        print('Cleaned bookmarks in %s/places.sqlite' % profile_path)

    if (profile_path / 'cookies.sqlite').exists():
        sanitize_cookies((profile_path / 'cookies.sqlite').as_posix())


prefs = gen_prefs()
for profile_path in Path('~/.mozilla/firefox').expanduser().glob('*.default*'):
    tweak_profile(profile_path, prefs)
