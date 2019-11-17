#!/usr/bin/env python3
# Parse and convert user.js to json.
import collections
import json
import re
import subprocess
import sys


def read_user_js(filename: str) -> collections.OrderedDict:
    out = subprocess.check_output(['cpp', '-fpreprocessed', filename])
    prefs = collections.OrderedDict()

    for line in out.decode('utf-8').split('\n'):
        line = line.strip()
        if line == '' or line.startswith('#'): continue

        m = re.match(r'^(?:user_pref|lockPref|defaultPref)\("([^"]+)",\s*("(?:[^"\\]|\\"|\\n)*"|[^") ]+)\);(\s+//.*|)$', line)
        if m is None:
            raise Exception('Bad user.js line: %s' % line)

        key, val = m.group(1), json.loads(m.group(2))
        prefs[key] = val

    return prefs


if __name__ == '__main__':
    filename = '/dev/stdin' if len(sys.argv) == 1 else sys.argv[1]
    prefs = read_user_js(filename)
    print(json.dumps(prefs, indent=2, sort_keys=True))
