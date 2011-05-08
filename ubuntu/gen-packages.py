#!/usr/bin/env python
# Usage: packages.py [release version] [tags]
import os, sys, re

def get_sys_release():
    return os.popen('lsb_release -r -s', 'r').read()

def is_release_tag(s):
    return re.match('[0-9.]+', s) is not None

def read_package_list(filename):
    for line in file(filename):
        line = line.strip()
        if '#' in line:
            line = line[:line.index('#')].strip()

        if len(line) == 0:
            continue

        if '[' not in line:
            for package in line.split():
                yield package, []
        else:
            packages = line[:line.index('[')].split()
            assert line.endswith(']')
            tags_sets = line[line.index('[')+1:-1].split('] [')
            tags_sets = [ s.split() for s in tags_sets ]

            for package in packages:
                for tags in tags_sets:
                    yield package, tags

def main():
    filename = os.path.join(sys.path[0], 'packages.txt')
    package_list = list(read_package_list(filename))

    user_tags = set(sys.argv[1:])

    release_tags = filter(is_release_tag, user_tags)
    assert len(release_tags) <= 1, 'Please specify only one release'

    if len(release_tags) == 0:
        release_tag = get_sys_release()
    else:
        release_tag = release_tags[0]
        user_tags.remove(release_tag)

    known_tags = set()
    for package, tags in package_list:
        for tag in tags:
            known_tags.add(tag)

    for tag in known_tags:
        if tag.endswith('+') and is_release_tag(tag[:-1]) and float(release_tag) >= float(tag[:-1]) - 1e-9:
            user_tags.add(tag)

    for tag in user_tags:
        if tag not in known_tags:
            sys.stderr.write('Unknown tag: %s\n' % tag)
            sys.stderr.write('Available tags: %s\n' % ', '.join(tag for tag in known_tags if not is_release_tag(tag) and not is_release_tag(tag[:-1])))
            sys.exit(1)

    sys.stderr.write('Install script is written to ./packages.sh\nSelected tag(s): %s\n' % ' '.join(user_tags))
    outf = file('packages.sh', 'w')

    outf.write('#!/bin/bash\n')
    outf.write('if [ "`whoami`" != "root" ]; then\n  echo You must run this script under root.\n  exit 1\nfi\n\n')
    outf.write('echo "Selected tag(s): %s"\n\n' % ' '.join(user_tags))
    outf.write('set -e -x\n\n')

    install_packages = set()
    remove_packages = set()
    build_dep_packages = set()
    easy_install_packages = set()
    cran_packages = set()

    for package, tags in package_list:
        if len(tags) == 0 or all(tag in user_tags for tag in tags):
            if package.startswith('-'):
                remove_packages.add(package[1:])
            elif package.startswith('build-dep:'):
                build_dep_packages.add(package[10:])
            elif package.startswith('easy-install:') or package.startswith('easy_install:'):
                easy_install_packages.add(package[13:])
            elif package.startswith('cran:'):
                cran_packages.add(package[5:])
            else:
                install_packages.add(package)

    if len(install_packages) > 0:
        outf.write('apt-get install %s\n' % ' \\\n  '.join(sorted(install_packages)))
    if len(build_dep_packages) > 0:
        outf.write('apt-get build-dep %s\n' % ' \\\n  '.join(sorted(build_dep_packages)))
    if len(remove_packages) > 0:
        outf.write('apt-get remove %s\n' % ' \\\n  '.join(sorted(remove_packages)))
    if len(easy_install_packages) > 0:
        outf.write('easy_install %s\n' % ' '.join(sorted(easy_install_packages)))

    if len(cran_packages) > 0:
        for package in sorted(cran_packages):
            outf.write('''echo 'install.packages("%s", repos="http://cran.r-project.org");' | R --no-save --no-restore --quiet\n''' % package)

    outf.close()
    os.chmod('packages.sh', 0766)

if __name__ == '__main__':
    main()
