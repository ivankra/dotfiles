#!/usr/bin/env python
import sys, os

def main():
    path = './'
    svn = None
    result = None

    while True:
        if os.path.exists(path + '.svn'):
            svn = path
        elif svn is not None:
            result = svn
            break

        if svn is None and any(os.path.exists(path + s) for s in [ '.git', '.hg' ]):
            result = path
            break

        if os.path.abspath(path + '../') == os.path.abspath(path):
            break
        path += '../'

    if result is None:
        sys.stderr.write('Error: not in a repository\n')
        sys.exit(1)

    if len(result) > 2:
        result = result[2:]
    result = result.rstrip('/')

    print result

if __name__ == '__main__':
    main()
