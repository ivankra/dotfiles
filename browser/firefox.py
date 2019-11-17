#!/usr/bin/env python3
import argparse
import base64
import hashlib
import json
import os
import shutil
import sqlite3
import sys

from lz4.block import compress as lz4_compress
from lz4.block import decompress as lz4_decompress
from pathlib import Path


def mozlz4_decompress(data):
    if len(data) < 8 or data[:8] != b'mozLz40\0':
        raise Exception('Invalid mozlz4 header')
    return lz4_decompress(data[8:])


def mozlz4_compress(data):
    return b'mozLz40\0' + lz4_compress(data)


# c.f. getVerificationHash in
# https://hg.mozilla.org/mozilla-central/file/tip/toolkit/components/search/SearchEngine.jsm
def get_verification_hash(name, profile_basename, app_name='Firefox'):
    boilerplate = (
        "{profile_basename}{name}By modifying this file, I agree that I"
        " am doing so only within {app_name} itself, using official, us"
        "er-driven search engine selection processes, and in a way whic"
        "h does not circumvent user consent. I acknowledge that any att"
        "empt to change this file from outside of {app_name} is a malic"
        "ious act, and will be responded to accordingly."
    )
    text = boilerplate.format(**locals())
    digest = hashlib.sha256(text.encode('utf-8')).digest()
    res = base64.encodebytes(digest).decode('utf-8').strip()
    return res


def configure_search(path):
    with open(path, 'rb') as fp:
        data = fp.read()

    data = json.loads(mozlz4_decompress(data))

    visible = ['Google', 'Bing', 'DuckDuckGo']
    n = 0

    for name in visible:
        for engine in data.get('engines', []):
            if engine.get('_name') == name:
                if name == 'Google':
                    configure_search_google(engine)
                n += 1
                engine.setdefault('_metaData', {})
                engine['_metaData']['order'] = n

    for engine in data.get('engines', []):
        if engine.get('_name') not in visible:
            n += 1
            engine['_metaData'] = {'order': n, 'alias': None, 'hidden': True}

    data.setdefault('metaData', {}).update({
        'private': 'DuckDuckGo',
        'privateHash': get_verification_hash('DuckDuckGo', path.parent.name),
    })

    data = mozlz4_compress(json.dumps(data).encode('utf-8'))
    with open(path, 'wb') as fp:
        fp.write(data)


def configure_search_google(engine_json):
    engine_json['_metaData'] = {'order': 1}
    for u in engine_json.get('_urls', []):
        client = False
        hl = False
        for p in u.get('params', []):
            if p.get('name', '') == 'client':
                client = True
            if p.get('name', '') == 'hl':
                hl = True

        if client and not hl:
            u.setdefault('params', []).append({'name': 'hl', 'value': 'en'})


def configure_installation(path):
    print('\nConfiguring installation %s' % path)

    try:
        if (path / 'distribution' / 'policies.json').read_text() == Path('gen/policies.json').read_text():
            print('policies.json up to date')
            return
    except:
        pass

    try:
        os.makedirs(path / 'distribution', exist_ok=True)
        shutil.copy('gen/policies.json', path / 'distribution' / 'policies.json')
        print('Created %s/distribution/policies.json' % path)
    except:
        print('\033[31mWarning: failed to create or overwrite %s/distribution/policies.json\033[m' % path)

        if str(path).startswith('/usr'):
            cmd = 'sudo dpkg -i gen/firefox-policies-json_1.0_all.deb'
            print('Installing policies.json with: %s' % cmd)
            os.system(cmd)


def configure_profile(path):
    print('\nConfiguring profile %s' % path)

    shutil.copy('gen/user.js', path / 'user.js')
    print('Wrote %s/user.js' % path)

    shutil.copy('gen/handlers.json', path / 'handlers.json')
    print('Wrote %s/handlers.json' % path)

    if (path / 'search.json.mozlz4').exists():
        configure_search(path / 'search.json.mozlz4')
        print('Wrote %s/search.json.mozlz4' % path)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('-i', '--installation', action='append', default=[],
                        help='Installation directories to configure')
    parser.add_argument('-p', '--profile', action='append', default=[],
                        help='Profile directories to configure')
    args = parser.parse_args()

    if len(args.installation) == 0:
        check = [
            '/usr/lib/firefox',
            '/usr/lib/firefox-esr',
            '~/.firefox',
            '~/.local/firefox',
            '~/.local/lib/firefox',
            '~/.mozilla/firefox',
        ]
        for path in check:
            path = Path(path).expanduser()
            if (path / 'omni.ja').exists() and (path / 'browser' / 'omni.ja').exists():
                print('Found installation %s' % path)
                args.installation.append(path)

    if len(args.profile) == 0:
        for path in Path('~/.mozilla/firefox').expanduser().glob('*/prefs.js'):
            path = path.parent
            print('Found profile %s' % path)
            args.profile.append(path)

    if len(args.installation) == 0:
        print('Warning: no firefox installation detected, specify path with -i')

    if len(args.profile) == 0:
        print(
            'Warning: no firefox profiles found. '
            'Run firefox to create one or specify explicit path with -p.'
        )

    for path in args.installation:
        configure_installation(path)

    for path in args.profile:
        configure_profile(path)


if __name__ == '__main__':
    main()
