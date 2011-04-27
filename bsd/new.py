#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os, sys, optparse, time, hashlib

HOME = os.environ['HOME']
assert HOME.startswith('/home/')
LOCAL = os.path.join(HOME, '.local2')
KIT_DIR = os.path.join(LOCAL, 'kit')
DOWNLOADS_DIR = '/home/yoda/.tarballs' #os.path.join(KIT_DIR,'downloads')
INSTALL_DB_FILE = os.path.join(KIT_DIR, 'installed.txt')
BUILD_DIR = os.path.join(KIT_DIR,'builds')

class InstallationTree(object):
    def __init__(self):
        pass

def is_command_available(name):
    return os.system("which '%s' >/dev/null 2>/dev/null" % name) == 0

def sh(cmd):
    print cmd
    n = os.system(cmd)
    if n != 0:
        raise Exception('Command "%s" terminated with exit code %d' % (cmd, n))

def fill_build_environment(env):
    env['LOCAL'] = LOCAL
    env['PATH'] = LOCAL + '/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
    env['PKG_CONFIG_PATH'] = '%s/lib/pkgconfig:%s/share/pkgconfig' % (LOCAL, LOCAL)
    env['CPATH'] = LOCAL + '/include'
    env['LIBRARY_PATH'] = LOCAL + '/lib'
    env['LD_LIBRARY_PATH'] = LOCAL + '/lib'
    env['CFLAGS'] = '-pipe -O2 -mtune=native -march=native'
    env['CXXFLAGS'] = ''
    env['LDFLAGS'] = ''
    env['LIBS'] = ''
    env['LANG'] = 'en_US.UTF-8'
    env['TMPDIR'] = '/var/tmp'
    env['MAKE'] = 'make'
    env['PMAKE'] = env['MAKE'] + ' -j 10'

    for gcc, gxx in (('gcc44', 'g++44'), ('gcc', 'g++')):
        if is_command_available(gcc) and is_command_available(gxx):
            env['CC'] = gcc
            env['CXX'] = gxx
            break

def read_install_db():
    try:
        data = file(INSTALL_DB_FILE).read()
        return dict(eval(data))
    except:
        return {}

def write_install_db(db):
    data = '[' + ',\n'.join(map(repr, sorted(db.items(), key=lambda (k, v): v['seq_no']))) + ']\n'
    file(INSTALL_DB_FILE, 'w').write(data)

def get_file_md5(path):
    ctx = hashlib.md5()
    f = file(path, 'rb')
    while True:
        block = f.read(65536)
        if len(block) == 0:
            break
        else:
            ctx.update(block)
    return ctx.hexdigest()

def install_package(pkg):
    # TODO: lock
    db = read_install_db()
    if pkg.name in db:
        print '%s is already installed' % pkg.name
        return

    print
    print '=== Installing %s v. %s ===' % (pkg.name, pkg.version)
    print 'Downloads: ' % pkg.downloads
    print 'Script:'
    print pkg.script

    fill_build_environment(os.environ)

    for dir in (LOCAL, DOWNLOADS_DIR, BUILD_DIR):
        if not os.path.exists(dir):
            os.makedirs(dir)

    pkg_build_dir = os.path.join(BUILD_DIR, pkg.name)
    if os.path.exists(pkg_build_dir):
        sh("rm -rf '%s'" % pkg_build_dir)
    os.makedirs(pkg_build_dir)
    os.chdir(pkg_build_dir)

    download_start = time.time()

    for url, md5 in pkg.downloads:
        filename = os.path.basename(url)
        save_as = os.path.join(DOWNLOADS_DIR, filename)

        if not os.path.exists(save_as) or (md5 is not None and get_file_md5(save_as) != md5):
            attempt = 0
            while True:
                try:
                    sh("rm -f '%(filename)s.tmp' '%(save_as)s' && wget -O '%(filename)s.tmp' '%(url)s' && mv -f '%(filename)s.tmp' '%(save_as)s'" % locals())
                    if md5 is not None:
                        actual_md5 = get_file_md5(save_as)
                        if md5 != actual_md5:
                            raise Exception('File "%(save_as)s" downloaded from %(url)s has md5 %(actual_md5)s, expected md5 %(md5)s' % locals())
                    os.chmod(save_as, 0444)
                    break
                except:
                    attempt += 1
                    if attempt > 3:
                        raise
                    sys.stderr.write('Download attempt failed, retrying\n')

        sh("ln -s '%(save_as)s' '%(filename)s'" % locals())

    download_end = time.time()

    file('install.sh', 'w').write(pkg.script)
    os.chmod('install.sh', 0766)

    sh("./install.sh")

    build_end = time.time()

    sh("cd $LOCAL; rm -rf '%s'" % pkg_build_dir)

    db[pkg.name] = dict(
        installed=1,
        version=pkg.version,
        seq_no=len(db)+1,
        download_time=int(download_end - download_start + 0.5),
        build_time=int(build_end - download_end + 0.5)
    )
    write_install_db(db)

class Package(object):
    def __init__(self, name, version=None, deps=[], downloads=[], script=''):
        self.name = name
        self.version = version
        self.deps = deps
        self.downloads = downloads  # list of (url, md5)
        self.script = script

def parse_name_version(s):
    i = s.rfind('-')
    if i == -1:
        return [s, '']
    else:
        return [s[:i], s[i+1:]]

def parse_name_version_ext(filename):
    assert '.tar' in filename
    i = filename.rfind('.tar')
    if i == -1:
        return parse_name_version(filename[:i]) + ['']
    else:
        return parse_name_version(filename[:i]) + [filename[i:]]

def make_tarball_package(urls, **kwargs):
    flagnames = 'CFLAGS CXXFLAGS LDFLAGS CC CXX'.split(' ')
    argnames = 'name, version, md5, deps, unpack, workdir, preconf, conf, postconf, make, postmake, install, postinst, script, xflags'.split(', ')
    name, version, md5, deps, unpack, workdir, preconf, conf, postconf, make, postmake, install, postinst, script, xflags = [kwargs.get(s, None) for s in argnames]

    bad_keys = [key for key in kwargs.keys() if key not in argnames + flagnames]
    if len(bad_keys) > 0:
        raise Exception('Unknown parameter(s): %s' % ', '.join(bad_keys))

    if type(urls) is str:
        urls = [urls]
    if md5 is None:
        md5 = [None] * len(urls)
    elif type(md5) is str:
        md5 = [md5]
    assert len(urls) == len(md5)
    downloads = [(urls[i], md5[i]) for i in range(len(urls))]

    if deps is None:
        deps = []
    elif type(deps) is str:
        deps = deps.split()

    filename = None if len(urls) == 0 else os.path.basename(urls[0])

    if script is not None:
        if name is None:
            name = parse_name_version_ext(filename)[0]
        if version is None:
            version = parse_name_version_ext(filename)[1]
        return Package(name, version=version, deps=deps, downloads=downloads, script=script)

    if name is None:
        name = parse_name_version_ext(filename)[0]
    if version is None:
        version = parse_name_version_ext(filename)[1]
    ext = None
    if ext is None:
        ext = parse_name_version_ext(filename)[2]

    if unpack is None:
        if ext == '.tar.bz2':
            unpack = "tar -jxf '%s'" % filename
        elif ext == '.tar.gz':
            unpack = "tar -zxf '%s'" % filename
        else:
            raise Exception('Unknown extension: %s' % ext)
    if workdir is None:
        workdir = filename[:-len(ext)]
    if conf is None or conf.startswith(' '):
        conf = './configure --prefix=$LOCAL' + ('' if conf is None else conf)
    if make is None:
        make = '$PMAKE'
    if install is None:
        install = '$MAKE install'

    varz = ''
    for flag in flagnames:
        if flag in kwargs:
            varz += " %s='%s'" % (flag, kwargs[flag])
    if xflags is not None:
        for flag in 'CFLAGS CXXFLAGS LDFLAGS':
            if flag not in kwargs:
                varz += " %s='%s'" % (flag, xflags)
    if varz != '':
        varz = 'export' + varz

    script = [
        '#!/usr/bin/env bash\nset -e -o pipefail -x',
        varz,
        unpack,
        preconf,
        ("cd '%s'" % workdir) if workdir != '.' else None,
        conf,
        postconf,
        make,
        postmake,
        install,
        postinst
    ]
    script = '\n'.join([ c for c in script if c is not None and c != '' ]) + '\n'

    return Package(name, version=version, deps=deps, downloads=downloads, script=script)

def package_list():
    results = []

    def tb(*args, **kwargs):
        results.append(make_tarball_package(*args, **kwargs))
        if len(set([r.name for r in results])) != len(results):
            raise Exception('Duplicate package name in: %s' % args)

    def gnu(filename, **kwargs):
        name = filename[:filename.rindex('-')]
        tb('http://mirrors.kernel.org/gnu/%s/%s' % (name, filename), **kwargs)

    def sf(filename, **kwargs):
        name = filename[:filename.rindex('-')]
        tb('http://downloads.sourceforge.net/%s/%s' % (name, filename), **kwargs)

    gnu('make-3.82.tar.bz2')
    gnu('libiconv-1.13.1.tar.gz', CFLAGS='-fPIC')
    gnu('ncurses-5.9.tar.gz', CFLAGS='-fPIC')
    gnu('gettext-0.18.1.1.tar.gz')
    gnu('gmp-5.0.1.tar.bz2')
    gnu('tar-1.26.tar.bz2')
    gnu('coreutils-8.9.tar.gz', postinst='mv -f $LOCAL/bin/{wc,wc.gnu}')  # native BSD wc is so much faster without multibyte support
    tb('http://tukaani.org/xz/xz-5.0.2.tar.bz2')
    gnu('diffutils-3.0.tar.gz')
    gnu('findutils-4.4.2.tar.gz')
    gnu('patch-2.6.tar.bz2')   # 2.6.1 build fails: gl/lib/strnlen.o: No such file or directory
    gnu('grep-2.7.tar.gz')
    gnu('groff-1.20.1.tar.gz', conf=' --x-includes=$LOCAL/include --x-libraries=$LOCAL/lib')  # 1.21 breaks some x11 builds
    gnu('m4-1.4.16.tar.bz2')
    gnu('sed-4.2.1.tar.bz2')
    gnu('gawk-3.1.8.tar.bz2')
    gnu('bison-2.4.3.tar.bz2')
    gnu('less-443.tar.gz')
    tb('http://ftp.twaren.net/Unix/NonGNU/man-db/man-db-2.5.5.tar.gz', postinst='chmod u-s $LOCAL/bin/{man,mandb}')
    sf('flex-2.5.35.tar.bz2')
    tb('http://www.openssl.org/source/openssl-0.9.8r.tar.gz', name='openssl-static', version='0.9.8r',
       make='$PMAKE || $MAKE', conf='./config --openssldir=$LOCAL/etc/ssl --prefix=$LOCAL')
    tb('http://www.openssl.org/source/openssl-0.9.8r.tar.gz', name='openssl-shared', version='0.9.8r',
       make='$PMAKE || $MAKE', conf='./config --openssldir=$LOCAL/etc/ssl --prefix=$LOCAL shared')
    gnu('wget-1.12.tar.bz2')
    sf('expat-2.0.1.tar.gz')
    tb('http://curl.haxx.se/download/curl-7.21.6.tar.bz2', conf=' --enable-static --enable-shared --with-openssl=$LOCAL')
    gnu('gperf-3.0.4.tar.gz')
    #gnu('gdb-7.2.tar.bz2', CC='gcc', CXX='g++')  # gcc44 produced a binary that crashed with "Bad system call: 12"
    sf('netcat-0.7.1.tar.bz2', CFLAGS='-O2 -static', LDFLAGS='-O2 -static')
    tb('http://www.dest-unreach.org/socat/download/socat-1.7.1.2.tar.bz2')
    sf('ctags-5.8.tar.gz')
    sf('cscope-15.7a.tar.bz2')

    tb(
        'http://www.cpan.org/src/5.0/perl-5.8.9.tar.bz2',
        conf=(
            r'''set -x; cd hints; chmod u+rw *; echo -e '223c223\n< 		 exit 1\n---\n> 		 ldflags="-pthread $ldflags"\n' | patch freebsd.sh; cd ..; ''' +
            'sed -i -e "s/<command line>/<command-line>/" makedepend.SH; '
            './Configure -sde -Dprefix=$LOCAL -Dvendorprefix=$LOCAL ' +
            '-Dman1dir=$LOCAL/share/man/man1 -Dman3dir=$LOCAL/share/man/man3 ' +
            '-Dsiteman1dir=$LOCAL/share/man/man1 -Dsiteman3dir=$LOCAL/share/man/man3 ' +
            '"-Dpager=$LOCAL/bin/less -isR"'
            '-Darchlib=$LOCAL/lib/perl5/5.8.9/mach ' +
            '-Dprivlib=$LOCAL/lib/perl5/5.8.9 ' +
            '-Dsitearchlib=$LOCAL/lib/perl5/site_perl/5.8.9/mach ' +
            '-Dsitelib=$LOCAL/lib/perl5/site_perl/5.8.9 ' +
            '-Ui_malloc -Ui_iconv -Dcc=cc -Duseshrplib ' +  # gcc 4.2.1 ?
            '"-Doptimize=-O2 -fno-strict-aliasing -pipe -mtune=native" -Ud_dosuid -Ui_gdbm -Dusethreads=y -Dusemymalloc=n -Duse64bitint'
            # -Dinc_version_list=none -Uinstallusrbinperl -Dscriptdir=/usr/local/bin
            #'-Dccflags=-DAPPLLIB_EXP="/usr/local/lib/perl5/5.8.9/BSDPAN" '
        )
    )

    sf('pcre-8.12.tar.bz2')
    sf('swig-2.0.3.tar.gz', conf=' --with-pcre-prefix=$LOCAL', LDFLAGS='-lpcre')
    tb('http://www.sqlite.org/sqlite-amalgamation-3.6.13.tar.gz', workdir='sqlite-3.6.13')
    tb('http://www.webdav.org/neon/neon-0.29.5.tar.gz', conf=' --with-ssl=openssl', postinst='rm -rf $LOCAL/share/doc/neon-0.29.5')
    tb(['http://subversion.tigris.org/downloads/subversion-1.6.16.tar.bz2',
        'http://www.apache.org/dist/apr/apr-1.4.2.tar.bz2',
        'http://www.apache.org/dist/apr/apr-util-1.3.10.tar.bz2'],
        preconf='tar -jxf ../apr-1.4.2.tar.bz2 && mv apr-1.4.2 apr && tar -jxf ../apr-util-1.3.10.tar.bz2 && mv apr-util-1.3.10 apr-util',
        conf=' --with-ssl --enable-swig-bindings=perl --with-neon=$LOCAL',
        postinst='$MAKE swig-pl && $MAKE check-swig-pl && $MAKE install-swig-pl')

    tb('http://www.kernel.org/pub/software/scm/git/git-1.7.5.tar.bz2',
        preconf='export PYTHON_PATH=$(which python)',
        conf=' --with-openssl --with-expat --with-curl',
        postinst=r"sed -i -e 's/^#![/]usr[/]bin[/]perl/^#\/usr\/bin\/env perl/' $LOCAL/libexec/git-core/git-*")
    tb('http://www.kernel.org/pub/software/scm/git/git-manpages-1.7.5.tar.bz2',
        script='cat git-manpages-*.tar.bz2 | (cd $LOCAL/man && tar -jx)')

    tb('http://xmlsoft.org/sources/libxml2-2.7.8.tar.gz')
    tb('http://xmlsoft.org/sources/libxslt-1.1.26.tar.gz')
    tb('http://pkgconfig.freedesktop.org/releases/pkg-config-0.25.tar.gz')
    tb('http://ftp.gnome.org/pub/gnome/sources/glib/2.28/glib-2.28.6.tar.bz2', conf=' --disable-dtrace')
    tb('http://www.fontconfig.org/release/fontconfig-2.8.0.tar.gz')
    sf('freetype-2.4.4.tar.bz2')
    sf('libpng-1.4.7.tar.bz2')
    tb('http://www.ijg.org/files/jpegsrc.v8c.tar.gz', name='libjpeg', version='8c', workdir='jpeg-8c')
    tb('http://download.osgeo.org/libtiff/tiff-3.9.5.tar.gz')  #'ftp://ftp.remotesensing.org/pub/libtiff/tiff-3.9.2.tar.gz',


    return results


def main():
    parser = optparse.OptionParser()
    parser.add_option('-q', dest='quiet')
    (options, args) = parser.parse_args()

    for pkg in package_list():
        install_package(pkg)

if __name__ == '__main__':
    main()
