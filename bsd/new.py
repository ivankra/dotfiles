#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os, sys, optparse

HOME = os.environ['HOME']
assert HOME.startswith('/home/')
LOCAL = os.path.join(HOME, '.local2')
DOWNLOADS_DIR = os.path.join(LOCAL,'kit/downloads')
INSTALLED_FILE = os.path.join(LOCAL, 'kit/installed.txt')
BUILD_DIR = os.path.join(LOCAL,'kit/build')

def is_command_available(name):
    return os.system("which '%s' >/dev/null 2>/dev/null" % name) == 0

def sh(cmd):
    print cmd
    n = os.system(cmd)
    if n != 0:
        raise Exception('Command "%s" terminated with exit code %d' % (cmd, n))

def fill_build_environment(env):
    env['PATH'] = LOCAL + '/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
    env['PKG_CONFIG_PATH'] = '%s/lib/pkgconfig:%s/share/pkgconfig' % (LOCAL, LOCAL)
    env['CPATH'] = LOCAL + '/include'
    env['LIBRARY_PATH'] = LOCAL + '/lib'
    env['LD_LIBRARY_PATH'] = LOCAL + '/lib'
    env['CFLAGS'] = '-pipe -O2 -mtune=native -march=native'
    env['LDFLAGS'] = ''
    env['LIBS'] = ''
    env['LANG'] = 'en_US.UTF-8'
    env['TMPDIR'] = '/var/tmp'
    env['MAKE'] = 'make'
    env['PMAKE'] = 'make -j 10'

    for gcc, gxx in (('gcc44', 'g++44'), ('gcc', 'g++')):
        if is_command_available(gcc) and is_command_available(gxx):
            env['CC'] = gcc
            env['CXX'] = gxx
            break

def install_package(pkg):
    print '=== %s v. %s ===' % (pkg.name, pkg.version)
    print pkg.script
    print

    for dir in (LOCAL, DOWNLOADS_DIR, BUILD_DIR):
        if not os.path.exists(dir):
            os.makedirs(dir)

    pkg_build_dir = os.path.join(BUILD_DIR, pkg.name)
    if os.path.exists(pkg_build_dir):
        sh("rm -rf '%s'" % pkg_build_dir)
    os.makedirs(pkg_build_dir)
    os.chdir(pkg_build_dir)

    for url, md5 in pkg.downloads:
        sh("wget %s" % url)

    file('install.sh', 'w').write(pkg.script)
    os.chmod(0766, 'install.sh')
    sh("./install.sh")

class Package(object):
    def __init__(self, name, version=None, deps=[], downloads=[], script=''):
        self.name = name
        self.version = version
        self.deps = deps
        self.downloads = downloads  # list of (url, md5)
        self.script = script

def Tarball(urls, **kwargs):
    name, version, md5, deps, unpack, workdir, preconf, configure, conf_flags, postconf, make, postmake, install, postinst = [kwargs.get(s, None) for s in
        'name, version, md5, deps, unpack, workdir, preconf, configure, conf_flags, postconf, make, postmake, install, postinst'.split(', ')]

    if type(urls) is str:
        urls = [urls]
    if md5 is None or type(md5) is str:
        md5 = [md5]
    assert len(urls) == len(md5)

    filename = os.path.basename(urls[0])
    assert '.tar' in filename
    if unpack is None or workdir is None or name is None:
        ext = filename[filename.index('.tar'):]
    if name is None:
        name = filename[:filename.index('-')]
        version = filename[len(name)+1:-len(ext)]
    if unpack is None:
        if ext == '.tar.bz2':
            unpack = "tar -jxf '%s'" % filename
        elif ext == '.tar.gz':
            unpack = "tar -zxf '%s'" % filename
        else:
            raise Exception('Unknown extension: %s' % ext)
    if workdir is None:
        workdir = filename[:-len(ext)]
    if configure is None:
        configure = './configure --prefix=$LOCAL' + ('' if conf_flags is None else (' ' + conf_flags))
    if make is None:
        make = '$PMAKE'
    if install is None:
        install = '$MAKE install'

    script = [
        '#!/usr/bin/env bash\nset -e -o pipefail -x',
        unpack,
        preconf,
        ("cd '%s'" % workdir) if workdir != '.' else None,
        configure,
        postconf,
        make,
        postmake,
        install,
        postinst
    ]
    script = '\n'.join([ c for c in script if c is not None and c != '' ])

    return Package(name, version=version, deps=deps, downloads=[(urls[i], md5[i]) for i in range(len(urls))], script=script)

def Gnu(filename, **kwargs):
    name = filename[:filename.index('-')]
    return Tarball('http://mirrors.kernel.org/gnu/%s/%s' % (name, filename), **kwargs)

def the_packages():
    yield Gnu('make-3.82.tar.bz2')
    yield Gnu('wget-1.12.tar.bz2')
    yield Gnu('libiconv-1.13.1.tar.gz')
    yield Gnu('gettext-0.18.1.1.tar.gz')
    yield Gnu('ncurses-5.9.tar.gz')
    yield Gnu('gmp-5.0.1.tar.bz2')
    yield Gnu('tar-1.26.tar.bz2')
    yield Gnu('coreutils-8.9.tar.gz', postinst='mv -f $LOCAL/bin/{wc,wc.gnu}')  # native wc is so much faster without widechar support
    yield Tarball('http://tukaani.org/xz/xz-4.999.9beta.tar.bz2')
    yield Gnu('diffutils-3.0.tar.gz')
    yield Gnu('findutils-4.4.2.tar.gz')
    yield Gnu('patch-2.6.tar.bz2')
    yield Gnu('grep-2.7.tar.gz')
    yield Gnu('groff-1.20.1.tar.gz', conf_flags='--x-includes=$LOCAL/include --x-libraries=$LOCAL/lib')  # note: 1.21 is broken
    yield Gnu('m4-1.4.16.tar.bz2')
    yield Gnu('sed-4.2.1.tar.bz2')
    yield Gnu('gawk-3.1.8.tar.bz2')
    yield Gnu('bison-2.4.3.tar.bz2')
    yield Gnu('less-418.tar.gz')
    yield Tarball('http://ftp.twaren.net/Unix/NonGNU/man-db/man-db-2.5.5.tar.gz', postinst='chmod u-s $LOCAL/bin/{man,mandb}')
    yield Tarball('http://downloads.sourceforge.net/flex/flex-2.5.35.tar.bz2')
    yield Tarball('http://www.openssl.org/source/openssl-0.9.8n.tar.gz', name='openssl-static', version='0.9.8n', conf='./config --openssldir=$LOCAL/etc/ssl --prefix=$LOCAL')
    yield Tarball('http://www.openssl.org/source/openssl-0.9.8n.tar.gz', name='openssl-shared', version='0.9.8n', conf='./config --openssldir=$LOCAL/etc/ssl --prefix=$LOCAL shared')
    yield Tarball('http://curl.haxx.se/download/curl-7.21.4.tar.bz2')
    yield Gnu('gperf-3.0.4.tar.gz')
    #gnu('gdb/gdb-7.1.tar.bz2',  preconf="export CC=gcc CXX=g++"),  # gcc44 produced a binary that crashes with "Bad system call: 12"

def main():
    parser = optparse.OptionParser()
    parser.add_option('-q', dest='quiet')
    (options, args) = parser.parse_args()

    for pkg in the_packages():
        install_package(pkg)

if __name__ == '__main__':
    main()
