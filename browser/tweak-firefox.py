#!/usr/bin/env python3

import collections
import json
import os
import re
import shutil
import subprocess
import sys

from pathlib import Path

try:
    from lz4.block import compress as lz4_compress
    from lz4.block import decompress as lz4_decompress
except:
    lz4_compress = None
    lz4_decompress = None
    sys.stderr.write('Warning: lz4 python module missing, install python3-lz4\n')


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

        m = re.match(r'^user_pref\("([^"]+)",\s+(.*)\);(\s+//.*|)$', line)
        if m is None:
            raise Exception('Bad pref line: %s' % line)

        key, val = m.group(1), m.group(2)
        yield key, val


def gen_prefs():
    prefs = collections.OrderedDict()
    prefs['browser.download.dir'] = '"%s"' % Path('~/Downloads').expanduser().resolve()

    for filename in ['user.pyllyukko.js', 'user.ghacks.js', 'user.js']:
        print(filename)
        for key, val in read_prefs(filename):
            if key == '_user.js.parrot': continue

            if key in prefs:
                if prefs[key] == val:
                    if filename == 'user.js':
                        print('  redundant %s: %s' % (key, val))
                    continue
                print('  override %s: %s -> %s' % (key, prefs[key], val))

            prefs[key] = val

    return prefs


def tweak_profile(profile_path, prefs):
    with (profile_path / 'user.js').open('w') as fp:
        for key, val in prefs.items():
            fp.write('user_pref("%s", %s);\n' % (key, val))
    print('Wrote %s/user.js' % profile_path)

    shutil.copy('handlers.json', profile_path / 'handlers.json')
    print('Wrote %s/handlers.json' % profile_path)

    if lz4_compress is not None:
        tweak_search(profile_path / 'search.json.mozlz4')
        print('Wrote %s/search.json.mozlz4' % profile_path)

    cmd = ['sqlite3', str(profile_path / 'places.sqlite'),
           'DELETE FROM moz_bookmarks WHERE id IN (' +
           'SELECT moz_bookmarks.id ' +
           'FROM moz_bookmarks INNER JOIN moz_places ON moz_places.id = moz_bookmarks.fk ' +
           'WHERE url LIKE "%%mozilla.org/%%");']
    subprocess.check_call(cmd)


prefs = gen_prefs()
for profile_path in Path('~/.mozilla/firefox').expanduser().glob('*.default*'):
    tweak_profile(profile_path, prefs)
