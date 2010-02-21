#!/usr/bin/env python
import os, sys

USER = os.getlogin()
HOME = '/home/' + USER
BASE_DIR = HOME + '/git/configs'

COMMANDS = []

def mksym(src, dst):
    global COMMANDS
    assert "'" not in src
    assert "'" not in dst
    if not os.path.exists(src):
        print 'Error: %s does not exist' % src
        sys.exit(1)
    if os.path.exists(dst):
        COMMANDS += ["rm -rf '%s'" % dst]
    COMMANDS += ["ln -s '%s' '%s'" % (os.path.abspath(src), dst)]
    print '%s -> %s' % (src, dst)

def main():
    if not os.path.exists(BASE_DIR):
        print 'This script assumes that it and all config files are located in %s' % BASE_DIR
        print 'but this directory does not exist'
        sys.exit(1)

    mksym(BASE_DIR + '/bashrc', HOME + '/.bashrc')
    mksym(BASE_DIR + '/vimrc', HOME + '/.vimrc')
    mksym(BASE_DIR + '/vim', HOME + '/.vim')

    for c in COMMANDS:
        ret = os.system(c)
        if ret != 0:
            print 'Error: command "%s" failed' % c
            sys.exit(1)

    print 'Success'

if __name__ == '__main__':
    main()
