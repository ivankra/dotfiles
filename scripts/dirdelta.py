#!/usr/bin/env python
# Compares contents of a past snapshot of current directory with its current state,
# outputs a script and a tarball with files that are needed to update a past
# snapshot to directory's current state.
# Takes as input lists of past and present md5sums (find -type f | xargs md5sum)

import sys, pipes, os

def read_sums(filename):
    res = {}
    for line in file(filename):
        line = line.rstrip('\r\n')
        assert len(line) >= 35 and line[32:34] == '  ', line
        md5, name = line[:32], line[34:]
        if name.startswith('./'):
            name = name[2:]
        assert name not in res
        assert "'" not in name
        assert not name.endswith('/')
        res[name] = md5
    return res

def main():
    if len(sys.argv) != 3:
        print 'Usage: delta.py <old md5sums file> <new md5sums file>'
        print 'Produces delta.tar, delta.sh'
        return

    if os.path.exists('delta.sh') or os.path.exists('delta.tar'):
        sys.stderr.write('Error: delta.sh or delta.tar already exists\n')
        return

    script = [ '#!/bin/sh\n' ]
    archive = []

    old = read_sums(sys.argv[1])
    new = read_sums(sys.argv[2])

    num_removed = 0
    for filename in old.keys():
        if filename not in new:
            if num_removed == 0:
                script.append('\n# removed\n')
            script.append("rm -f '%s'\n" % filename)
            num_removed += 1
            #print 'D %s' % filename

    num_modified = 0
    for filename in old.iterkeys():
        if filename in new and old[filename] != new[filename]:
            if num_modified == 0:
                script.append('\n# modified\n')
            script.append("rm -f '%s'\n" % filename)
            num_modified += 1
            archive.append(filename)
            #print 'M %s' % filename

    num_new = 0
    for filename in new.iterkeys():
        if filename not in old:
            num_new += 1
            archive.append(filename)
            #print 'A %s' % filename

    print '%d removed, %d modified, %d new files' % (num_removed, num_modified, num_new)

    for filename in archive:
        if not os.path.exists(filename):
            print 'Error: %s does not exist' % filename
            return

    if num_modified + num_new > 0:
        script.append('\ntar xf delta.tar\n')
        cmd = 'tar cf delta.tar ' + ' '.join(pipes.quote(s) for s in archive)
        ret = os.system(cmd)
        if ret != 0:
            sys.stderr.write('Error: tar failed\n')
        else:
            sys.stderr.write('Created delta.tar\n')

    file('delta.sh', 'w').write(''.join(script))
    sys.stderr.write('Created delta.sh\n')

if __name__ == '__main__':
    main()
