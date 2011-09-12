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

def add_md5sum_check(script, funcname, title, filename):
    script.append(funcname + '() {\n')
    script.append('echo "%s"\n' % title)
    script.append('# ' + filename + '\n')
    script.append('md5sum -c --quiet <<END_OF_MD5SUMS\n')
    script.append(file(filename).read().rstrip())
    assert 'END_OF_MD5SUMS' not in script[-1]
    script.append('\nEND_OF_MD5SUMS\n\n')
    script.append('if [ $? -ne 0 ]; then\n  echo Files are corrupted. Aborting.\n  exit 1\nfi\n')
    script.append('}\n\n')

def get_file_md5(filename):
    out = os.popen("md5sum '%s'" % filename, 'r').read()
    assert out[32:].rstrip() == '  ' + filename
    return out[:32]

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

    add_md5sum_check(script, 'check_old', 'Checking existing files', sys.argv[1])
    add_md5sum_check(script, 'check_new', 'Checking files after update', sys.argv[2])

    script.append('remove_old() {\n')

    num_removed = 0
    for filename in sorted(old.keys()):
        if filename not in new:
            if num_removed == 0:
                script.append('\n# removed\n')
            script.append("rm -f '%s'\n" % filename)
            num_removed += 1
            #print 'D %s' % filename

    num_modified = 0
    for filename in sorted(old.keys()):
        if filename in new and old[filename] != new[filename]:
            if num_modified == 0:
                script.append('\n# modified\n')
            script.append("rm -f '%s'\n" % filename)
            num_modified += 1
            archive.append(filename)
            #print 'M %s' % filename

    num_new = 0
    for filename in sorted(new.keys()):
        if filename not in old:
            num_new += 1
            archive.append(filename)
            #print 'A %s' % filename

    script.append('}\n\n')

    archived_size = 0
    for filename in archive:
        if not os.path.exists(filename):
            sys.stderr.write('Error: %s does not exist\n' % filename)
            sys.exit(1)
        else:
            archived_size += os.path.getsize(filename)

    print '%d removed, %d modified, %d new files. To be archived: %.1lf MiB' % (
            num_removed, num_modified, num_new, archived_size / 1048576.0)

    if len(archive) == 0:
        sys.stderr.write('Error: nothing to archive\n')
        sys.exit(1)

    batch_size = 1000
    i = 0
    while i < len(archive):
        cmd = 'tar -cf ' if i == 0 else 'tar -rf '
        cmd += 'delta.tar'
        for j in xrange(i, min(i + batch_size, len(archive))):
            cmd += ' ' + pipes.quote(archive[j])

        if len(archive) > batch_size:
            print 'Packing files #%d..%d' % (i+1, min(i+batch_size, len(archive)))

        ret = os.system(cmd)
        if ret != 0:
            sys.stderr.write('Error: tar failed with exit code %d\n' % ret)
            os.unlink('delta.tar')
            sys.exit(1)

        i += batch_size

    print 'Created delta.tar'
    md5 = get_file_md5('delta.tar')

    script.append(
        'check_old\n\n'
        'echo Verifying delta.tar\n'
        'echo "' + md5 + '  delta.tar" | md5sum -c --quiet\n'
        'if [ $? -ne 0 ]; then\n'
        '  echo delta.tar is corrupted\n'
        '  exit 1\n'
        'fi\n\n'
        'remove_old\n\n'
        'echo Unpacking delta.tar\n'
        'tar -xf delta.tar\n'
        'if [ $? -ne 0 ]; then\n'
        '  echo Unpacking failed\n'
        '  exit 1\n'
        'fi\n\n'
        'check_new\n\n'
        'echo Done\n'
    )

    file('delta.sh', 'w').write(''.join(script))
    os.system('chmod a+rx delta.sh')
    print 'Created delta.sh'

if __name__ == '__main__':
    main()
