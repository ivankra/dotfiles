#!/usr/bin/env python
import os, sys, pwd

def check_symlink(src, dst):
    try:
        return os.readlink(src) == dst
    except:
        return False

def sh(cmd):
    ret = os.system(cmd)
    if ret != 0:
        sys.stderr.write('Error: command "%s" terminated with exit code %d.\n' % (cmd, ret))
        sys.exit(1)

def main():
    home = os.environ['HOME']
    assert home.startswith('/')

    base = home + '/git/configs'
    if not os.path.exists(os.path.join(base, 'setup-symlinks.py')):
        sys.stderr.write(
            "This script assumes that it and all config files " +
            "are located in %s, but this directory does not exist " +
            "or doesn't contain what we expect.\n" % base)
        sys.exit(1)

    actions = []
    actions.append([home + '/.bashrc', base + '/bashrc'])
    actions.append([home + '/.vimrc', base + '/vimrc'])
    actions.append([home + '/.vim', base + '/vim'])
    actions.append([home + '/.gdbinit', base + '/gdbinit'])

    items_str = []
    for src, dst in actions:
        if not os.path.exists(dst):
            sys.stderr.write('Error: "%s" does not exist.\n' % dst)
            sys.exit(1)

        if os.path.exists(src) and check_symlink(src, dst):
            continue

        if os.path.exists(src):
            items_str.append('Replace "%s" by a symlink to "%s"' % (src, dst))
        else:
            items_str.append('Create symlink "%s" to "%s"' % (src, dst))

    if len(items_str) == 0:
        sys.stdout.write('This script has already been executed. Nothing to do.\n')
        sys.exit(0)

    sys.stdout.write('The following actions will be taken:\n')
    for s in items_str:
        sys.stdout.write('  * %s\n' % s)
    sys.stdout.write('Confirm (yes/no)? ')
    sys.stdout.flush()

    if sys.stdin.readline().strip().lower() != 'yes':
        sys.stdout.write('Aborted.\n')
        sys.exit(0)

    for src, dst in actions:
        assert "'" not in src and "'" not in dst
        if os.path.exists(src):
            sh("rm -rf '%s'" % src)
        sh("ln -s '%s' '%s'" % (os.path.abspath(dst), src))

    sys.stdout.write('Finished successfully.\n')

if __name__ == '__main__':
    main()
