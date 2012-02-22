#!/usr/bin/env python
import sys, os

STOPFILES = [ '.git', '.hg', '.p4config' ]
MAINDIRS = os.environ.get('SCM_MAINDIR', '').split()

def main():
    path = './'
    svn = None
    result = None

    while True:
        # stop at the top directory with .svn
        if os.path.exists(path + '.svn'):
            svn = path
        elif svn is not None:
            result = svn
            break

        # stop at the first directory with .git, etc
        if svn is None and any(os.path.exists(path + s) for s in STOPFILES):
            result = path
            break

        if os.path.abspath(path + '../') == os.path.abspath(path):
            break
        path += '../'

    if result is None and any(os.path.exists(s) for s in MAINDIRS):
        result = './'

    if result is not None:
        for s in MAINDIRS:
            if os.path.exists(result + s):
                result += s
                break
    else:
        path = './'
        while True:
            if any(os.path.samefile(path, path + '../' + s) for s in MAINDIRS):
                result = path
                break
            if os.path.abspath(path + '../') == os.path.abspath(path):
                break
            path += '../'

    if result is None:
        sys.stderr.write('Error: not in a repository\n')
        sys.exit(1)

    if result.startswith('./') and len(result) > 2:
        result = result[2:]
    result = result.rstrip('/')

    print result

if __name__ == '__main__':
    main()
