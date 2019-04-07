#!/usr/bin/env python3

import collections
import os
import re
import shutil
import subprocess

from pathlib import Path


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

    cmd = ['sqlite3', str(profile_path / 'places.sqlite'),
           'DELETE FROM moz_bookmarks WHERE id IN (' +
           'SELECT moz_bookmarks.id ' +
           'FROM moz_bookmarks INNER JOIN moz_places ON moz_places.id = moz_bookmarks.fk ' +
           'WHERE url LIKE "%%mozilla.org/%%");']
    subprocess.check_call(cmd)


prefs = gen_prefs()
for profile_path in Path('~/.mozilla/firefox').expanduser().glob('*.default'):
    tweak_profile(profile_path, prefs)
