#!/usr/bin/env python
# Compiles gnu tools, x11 libraries, gvim and more, installs into home directory. For FreeBSD.
# Assumes that a working gcc compiler is present.

import os, sys, optparse, time, hashlib

HOME = os.environ['HOME']
assert HOME.startswith('/home/')
LOCAL = os.path.join(HOME, '.local')
KIT_DIR = os.path.join(LOCAL, 'kit')
DOWNLOADS_DIR = '/home/yoda/.tarballs' #os.path.join(KIT_DIR,'downloads')
INSTALL_DB_FILE = os.path.join(KIT_DIR, 'installed.txt')
BUILD_DIR = os.path.join(KIT_DIR,'builds')
IGNORE_MISSING_MD5 = 0

# TODO: installation tree monitoring, create .tar packages with all modified files; discover dependencies with ldd

def is_command_available(name):
    return os.system("which '%s' >/dev/null 2>/dev/null" % name) == 0

def sh(cmd):
    print cmd
    sys.stdout.flush()
    n = os.system(cmd)
    if n != 0:
        raise Exception('Command "%s" terminated with exit code %d' % (cmd, n))

def fill_build_environment(env):
    env['HOME'] = HOME
    env['LOCAL'] = LOCAL
    env['PATH'] = LOCAL + '/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
    env['PKG_CONFIG_PATH'] = '%s/lib/pkgconfig:%s/share/pkgconfig' % (LOCAL, LOCAL)
    env['CPATH'] = LOCAL + '/include'
    env['LIBRARY_PATH'] = LOCAL + '/lib'
    env['LD_LIBRARY_PATH'] = LOCAL + '/lib'
    env['CFLAGS'] = '-pipe -O2 -mtune=native -march=native'
    env['LDFLAGS'] = '-Wl,-rpath=' + LOCAL + '/lib'
    for flag in ('CXXFLAGS',  'LIBS', 'LIB'):
        if flag in env:
            del env[flag]
    env['LANG'] = 'en_US.UTF-8'
    env['TMPDIR'] = '/var/tmp'

    env['MAKE'] = 'make'
    local_make = os.path.join(LOCAL, 'bin/make')
    if os.path.exists(local_make):
        env['MAKE'] = local_make
    elif is_command_available('gmake'):
        env['MAKE'] = 'gmake'
    else:
        env['MAKE'] = 'make'

    env['PMAKE'] = env['MAKE'] + ' -j 10'

    for gcc, gxx in (('gcc44', 'g++44'), ('gcc', 'g++')):
        if is_command_available(gcc) and is_command_available(gxx):
            env['CC'] = gcc
            env['CXX'] = gxx
            break

    if is_command_available('gfortran44'):
        env['FC'] = 'gfortran44'
        env['F77'] = 'gfortran44'

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

    for dep in pkg.deps:
        if dep not in db or db[dep]['installed'] != 1:
            raise Exception("Can't install %s: unsatisfied dependency %s" % (pkg.name, dep))

    print
    print '=== Installing %s %s ===' % (pkg.name, pkg.version)
    print pkg.script
    sys.stdout.flush()

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
                    sh("rm -f '%(filename)s.tmp' '%(save_as)s'" % locals())
                    if is_command_available('wget'):
                        sh("wget -O '%(filename)s.tmp' '%(url)s'" % locals())
                    elif is_command_available('curl'):
                        sh("curl '%(url)s'  >'%(filename)s.tmp'" % locals())
                    else:
                        sh("fetch -q -o '%(filename)s.tmp' '%(url)s'" % locals())
                    sh("mv -f '%(filename)s.tmp' '%(save_as)s'" % locals())
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

    script = pkg.script
    if not script.startswith('#!'):
        script = '#!/usr/bin/env bash\nset -e -o pipefail -x\n' + script
    file('install.sh', 'w').write(script)
    os.chmod('install.sh', 0766)

    sh("./install.sh")
    sh("cd $LOCAL; rm -rf '%s'" % pkg_build_dir)

    build_end = time.time()

    db[pkg.name] = dict(
        installed=1,
        version=pkg.version,
        seq_no=max([0] + [p['seq_no'] for p in db.itervalues()]) + 1,
        download_time=int(download_end - download_start + 0.5),
        build_time=int(build_end - download_end + 0.5)
    )
    write_install_db(db)

class Package(object):
    def __init__(self, name, version=None, deps=[], downloads=[], script='', skippable=0):
        self.name = name
        self.version = version
        self.deps = deps
        self.downloads = downloads  # list of (url, md5)
        self.script = script
        self.skippable = skippable

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

def get_database_md5s(urls):
    db_file = os.path.join(sys.path[0], 'md5.txt')

    if not os.path.exists(db_file):
        sys.stderr.write('md5 hashes database is missing, aborting. Create an empty database to ignore.\n')
        sys.exit(1)

    if os.path.getsize(db_file) == 0:
        return [None] * len(urls)

    db = {}
    for line in file(db_file):
        line = line.rstrip('\n')
        assert line.count('  ') == 1
        md5, filename = line.split('  ')
        assert filename not in db or db[filename] == md5
        db[filename] = md5

    res = []
    for url in urls:
        filename = os.path.basename(url)
        if filename not in db:
            sys.stderr.write('md5 hash for file %s (%s) is missing from the database.\n' % (filename, url))
            if IGNORE_MISSING_MD5:
                res.append(None)
        else:
            res.append(db[filename])
    if len(res) != len(urls):
        sys.exit(1)
    return res

def make_tarball_package(urls, **kwargs):
    flagnames = 'CFLAGS CXXFLAGS LDFLAGS CC CXX CPATH'.split(' ')
    argnames = 'name, version, md5, deps, unpack, workdir, preconf, conf, postconf, make, postmake, install, postinst, script, skippable'.split(', ')
    name, version, md5, deps, unpack, workdir, preconf, conf, postconf, make, postmake, install, postinst, script, skippable = [kwargs.get(s, None) for s in argnames]

    valid_keys = argnames + flagnames + ['EXTRA_' + flag for flag in flagnames]
    bad_keys = [key for key in kwargs.keys() if key not in valid_keys]
    if len(bad_keys) > 0:
        raise Exception('Unknown parameter(s): %s' % ', '.join(bad_keys))

    if type(urls) is str:
        urls = [urls]
    if md5 is None:
        md5 = get_database_md5s(urls)
    elif type(md5) is str:
        md5 = [md5]
    assert len(urls) == len(md5)
    downloads = [(urls[i], md5[i]) for i in range(len(urls))]

    if deps is None:
        deps = []
    elif type(deps) is str:
        deps = deps.split()

    filename = None
    if len(urls) > 0:
        filename = os.path.basename(urls[0])

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
        if conf is None:
            conf = ''
        conf = './configure --prefix=$LOCAL' + conf
    if make is None:
        make = '$PMAKE'
    if install is None:
        install = '$MAKE install'

    varz = ''
    for flag in flagnames:
        if flag in kwargs:
            if kwargs[flag] is None:
                del kwargs[flag]
            else:
                varz += " %s='%s'" % (flag, kwargs[flag])
        if 'EXTRA_' + flag in kwargs:
            value = kwargs['EXTRA_' + flag]
            if value is not None:
                varz += ' %s="$%s %s"' % (flag, flag, value)
    if varz != '':
        varz = 'export' + varz

    cd_workdir = None
    if workdir != '.':
        cd_workdir = "cd '%s'" % workdir

    script = [
        varz,
        unpack,
        cd_workdir,
        preconf,
        conf,
        postconf,
        make,
        postmake,
        install,
        postinst
    ]
    script = '\n'.join([ c for c in script if c is not None and c != '' ]) + '\n'

    return Package(name, version=version, deps=deps, downloads=downloads, script=script, skippable=skippable)

def package_list():
    results = []

    def tarball(*args, **kwargs):
        results.append(make_tarball_package(*args, **kwargs))
        if len(set([r.name for r in results])) != len(results):
            raise Exception('Duplicate package name in: %s' % args)

    def gnu(filename, **kwargs):
        name = filename[:filename.rindex('-')]
        tarball('http://mirrors.kernel.org/gnu/%s/%s' % (name, filename), **kwargs)

    def sourceforge(filename, **kwargs):
        if '/' not in filename:
            filename = filename[:filename.rindex('-')] + '/' + filename
        tarball('http://downloads.sourceforge.net/%s' % filename, **kwargs)

    gnu('make-3.82.tar.bz2', make='./build.sh', install='./make install')
    sourceforge('libpng/zlib-1.2.5.tar.bz2')
    gnu('libiconv-1.13.1.tar.gz', EXTRA_CFLAGS='-fPIC')
    gnu('ncurses-5.9.tar.gz', EXTRA_CFLAGS='-fPIC')
    gnu('gettext-0.18.1.1.tar.gz')
    gnu('m4-1.4.16.tar.bz2')
    gnu('gmp-5.0.1.tar.bz2', deps=['m4'])
    gnu('tar-1.26.tar.bz2')
    gnu('coreutils-8.9.tar.gz', postinst='mv -f $LOCAL/bin/{wc,wc.gnu}')  # native BSD wc is so much faster without multibyte support
    gnu('readline-6.2.tar.gz')
    gnu('bash-4.2.tar.gz')
    gnu('autoconf-2.68.tar.bz2')
    gnu('automake-1.11.1.tar.bz2')
    tarball('http://tukaani.org/xz/xz-5.0.2.tar.bz2')
    gnu('diffutils-3.0.tar.gz')
    gnu('findutils-4.4.2.tar.gz')
    gnu('patch-2.6.tar.bz2', skippable=1)   # 2.6.1 build fails: gl/lib/strnlen.o: No such file or directory
    gnu('grep-2.7.tar.gz', EXTRA_LDFLAGS='-liconv')
    gnu('groff-1.20.1.tar.gz', conf=' --without-x')  # 1.21 breaks some x11 builds
    gnu('sed-4.2.1.tar.bz2')
    gnu('gawk-3.1.8.tar.bz2')
    gnu('bison-2.4.3.tar.bz2')
    gnu('less-443.tar.gz')
    gnu('gdbm-1.8.3.tar.gz', postconf='sed -i -e "s/-o .(BINOWN.*BINGRP)//" Makefile')
    tarball('http://ftp.twaren.net/Unix/NonGNU/man-db/man-db-2.5.5.tar.gz', postinst='chmod u-s $LOCAL/bin/{man,mandb}', EXTRA_LDFLAGS='-liconv', deps=['gdbm', 'less'])
    sourceforge('flex-2.5.35.tar.bz2')

    openssl_patch = 'sed -i -e "s/ *if (.stddev...outdev .. .stdino...outino);//" crypto/perlasm/x86_64-xlate.pl'
    tarball('http://www.openssl.org/source/openssl-0.9.8r.tar.gz', name='openssl-static', version='0.9.8r',
        preconf=openssl_patch, make='$PMAKE || $MAKE', conf='./config --openssldir=$LOCAL/etc/ssl --prefix=$LOCAL')
    tarball('http://www.openssl.org/source/openssl-0.9.8r.tar.gz', name='openssl-shared', version='0.9.8r',
        preconf=openssl_patch, make='$PMAKE || $MAKE', conf='./config --openssldir=$LOCAL/etc/ssl --prefix=$LOCAL shared')

    gnu('wget-1.12.tar.bz2')
    sourceforge('expat-2.0.1.tar.gz')
    tarball('http://curl.haxx.se/download/curl-7.21.6.tar.bz2', conf=' --enable-static --enable-shared --with-openssl=$LOCAL')
    gnu('gperf-3.0.4.tar.gz')
    #gnu('gdb-7.2.tar.bz2', CC='gcc', CXX='g++')  # gcc44 produced a binary that crashed with "Bad system call: 12"
    sourceforge('netcat-0.7.1.tar.bz2', EXTRA_CFLAGS='-static', EXTRA_LDFLAGS='-static')
    tarball('http://www.dest-unreach.org/socat/download/socat-1.7.1.2.tar.bz2')
    sourceforge('ctags-5.8.tar.gz')
    sourceforge('cscope-15.7a.tar.bz2', preconf='export CPATH=$CPATH:$LOCAL/include/ncurses', conf=' --with-ncurses=$LOCAL')

    tarball('http://www.python.org/ftp/python/2.6.7/Python-2.6.7.tar.bz2', name='python', deps=['gdbm'], conf=' --enable-shared')  # 2.7.1 has a bug in distutils preventing mercual build
    tarball('http://ipython.scipy.org/dist/0.10.2/ipython-0.10.2.tar.gz',
            conf='', make='./setup.py build -v', install='./setup.py install -v --prefix $LOCAL', deps=['python'])
    tarball('http://mercurial.selenic.com/release/mercurial-1.8.4.tar.gz',
        script='tar xf mercurial-1.?.?.tar.gz && cd mercurial-1.?.? && $MAKE build && python ./setup.py install  --home=$LOCAL --force',
        deps=['python'])

    tarball(
        'http://www.cpan.org/src/5.0/perl-5.8.9.tar.bz2',
        preconf=(
            '''cd hints; chmod u+w freebsd.sh; echo -e '223c223\\n< \t\t exit 1\n---\n> \t\t ldflags="-pthread $ldflags"\\n' | patch freebsd.sh; cd ..; ''' +
            'sed -i -e "s/<command line>/<command-line>/" makedepend.SH;'
        ),
        conf=(
            './Configure -sde '
            '-Dprefix=$LOCAL '
            '-Dsiteprefix=$LOCAL '
            '-Dvendorprefix=$LOCAL '
            '-Dman1dir=$LOCAL/share/man/man1 '
            '-Dman3dir=$LOCAL/share/man/man3 '
            '-Dsiteman1dir=$LOCAL/share/man/man1 '
            '-Dsiteman3dir=$LOCAL/share/man/man3 '
            '-Darchlib=$LOCAL/lib/perl5/5.8.9/mach '
            '-Dprivlib=$LOCAL/lib/perl5/5.8.9 '
            '-Dsitearchlib=$LOCAL/lib/perl5/site_perl/5.8.9/mach '
            '-Dsitelib=$LOCAL/lib/perl5/site_perl/5.8.9 '
            '"-Dpager=$LOCAL/bin/less -isR" '
            '-Dcc=$CC '
            '"-Doptimize=-O2 -fno-strict-aliasing -pipe -march=native -mtune=native" '
            '-Dusethreads=y '
            '-Dusemymalloc=n '
            '-Duse64bitall'
            '-Duseshrplib '
            '-Ui_malloc -Ui_iconv -Ud_dosuid -Ui_gdbm '
            # -Dinc_version_list=none
            #'-Accflags=-DAPPLLIB_EXP="/usr/local/lib/perl5/5.8.9/BSDPAN" '
        )
    )

    sourceforge('pcre-8.12.tar.bz2', conf=' --enable-utf8 --enable-unicode-properties')
    sourceforge('swig-2.0.3.tar.gz', conf=' --with-pcre-prefix=$LOCAL', EXTRA_LDFLAGS='-lpcre')
    tarball('http://www.sqlite.org/sqlite-amalgamation-3.6.13.tar.gz', workdir='sqlite-3.6.13')
    tarball('http://www.webdav.org/neon/neon-0.29.5.tar.gz', conf=' --with-ssl=openssl', postinst='rm -rf $LOCAL/share/doc/neon-0.29.5')
    tarball(['http://subversion.tigris.org/downloads/subversion-1.6.17.tar.bz2',
        'http://www.apache.org/dist/apr/apr-1.4.5.tar.bz2',
        'http://www.apache.org/dist/apr/apr-util-1.3.12.tar.bz2'],
        preconf='tar -jxf ../apr-1.?.?.tar.bz2 && mv apr-1.?.? apr && tar -jxf ../apr-util-1.?.??.tar.bz2 && mv apr-util-1.?.?? apr-util',
        conf=' --with-ssl --enable-swig-bindings=perl --with-neon=$LOCAL',
        postinst='$MAKE swig-pl && $MAKE check-swig-pl && $MAKE install-swig-pl; rm -rf $LOCAL/build-1')

    tarball('http://www.kernel.org/pub/software/scm/git/git-1.7.5.4.tar.bz2',
        preconf='export PYTHON_PATH=$(which python)',
        conf=' --with-openssl --with-expat --with-curl',
        postinst=r"sed -i -e 's/^#![/]usr[/]bin[/]perl/#!\/usr\/bin\/env perl/' $LOCAL/libexec/git-core/git-*")
    tarball('http://www.kernel.org/pub/software/scm/git/git-manpages-1.7.5.4.tar.bz2',
        script='cat git-manpages-*.tar.bz2 | (cd $LOCAL/man && tar -jx)')

    tarball('http://xmlsoft.org/sources/libxml2-2.7.8.tar.gz')
    tarball('http://xmlsoft.org/sources/libxslt-1.1.26.tar.gz')
    tarball('http://pkgconfig.freedesktop.org/releases/pkg-config-0.25.tar.gz')
    tarball('http://ftp.gnome.org/pub/gnome/sources/glib/2.28/glib-2.28.6.tar.bz2',
            preconf=r"echo -e '611a612,614\n> #ifdef HAVE_SYS_PARAM_H\n> # include <sys/param.h>\n> #endif' | patch configure",  # sys/param.h is required for sys/mount.h on freebsd 6.3
            conf=' --disable-dtrace --with-threads=posix --with-pcre=system --with-libiconv=gnu')
    sourceforge('freetype-2.4.4.tar.bz2')
    tarball('http://www.fontconfig.org/release/fontconfig-2.8.0.tar.gz', deps=['freetype'])
    sourceforge('libpng-1.4.7.tar.bz2')
    tarball('http://www.ijg.org/files/jpegsrc.v8c.tar.gz', name='libjpeg', version='8c', workdir='jpeg-8c')
    tarball('http://download.osgeo.org/libtiff/tiff-3.9.5.tar.gz')  #'ftp://ftp.remotesensing.org/pub/libtiff/tiff-3.9.2.tar.gz',

    X11R75 = '''
        proto/applewmproto-1.4.1.tar.bz2
        proto/bigreqsproto-1.1.0.tar.bz2
        proto/compositeproto-0.4.1.tar.bz2
        proto/damageproto-1.2.0.tar.bz2
        proto/dmxproto-2.3.tar.bz2
        proto/dri2proto-2.1.tar.bz2
        proto/fixesproto-4.1.1.tar.bz2
        proto/fontsproto-2.1.0.tar.bz2
        proto/glproto-1.4.10.tar.bz2
        proto/inputproto-2.0.tar.bz2
        proto/kbproto-1.0.4.tar.bz2
        proto/randrproto-1.3.1.tar.bz2
        proto/recordproto-1.14.tar.bz2
        proto/renderproto-0.11.tar.bz2
        proto/resourceproto-1.1.0.tar.bz2
        proto/scrnsaverproto-1.2.0.tar.bz2
        proto/videoproto-2.3.0.tar.bz2
        proto/windowswmproto-1.0.4.tar.bz2
        proto/xcmiscproto-1.2.0.tar.bz2
        proto/xextproto-7.1.1.tar.bz2
        proto/xf86bigfontproto-1.2.0.tar.bz2
        proto/xf86dgaproto-2.1.tar.bz2
        proto/xf86driproto-2.1.0.tar.bz2
        proto/xf86vidmodeproto-2.3.tar.bz2
        proto/xineramaproto-1.2.tar.bz2
        proto/xproto-7.0.16.tar.bz2
        lib/xtrans-1.2.5.tar.bz2
        lib/libXau-1.0.5.tar.bz2
        lib/libXdmcp-1.0.3.tar.bz2
        http://xcb.freedesktop.org/dist/xcb-proto-1.5.tar.bz2
        http://xcb.freedesktop.org/dist/libpthread-stubs-0.1.tar.bz2
        http://xcb.freedesktop.org/dist/libxcb-1.4.tar.bz2
        http://xcb.freedesktop.org/dist/xcb-util-0.3.6.tar.bz2
        lib/libX11-1.3.2.tar.bz2
        lib/libXext-1.1.1.tar.bz2
        lib/libdmx-1.1.0.tar.bz2
        lib/libfontenc-1.0.5.tar.bz2
        lib/libFS-1.0.2.tar.bz2
        lib/libICE-1.0.6.tar.bz2
        lib/libSM-1.1.1.tar.bz2
        lib/libXt-1.0.7.tar.bz2
        lib/libXmu-1.0.5.tar.bz2
        lib/libXpm-3.5.8.tar.bz2
        lib/libXaw-1.0.7.tar.bz2
        lib/libXfixes-4.0.4.tar.bz2
        lib/libXcomposite-0.4.1.tar.bz2
        lib/libXrender-0.9.5.tar.bz2
        lib/libXdamage-1.1.2.tar.bz2
        lib/libXcursor-1.1.10.tar.bz2
        lib/libXfont-1.4.1.tar.bz2
        lib/libXft-2.1.14.tar.bz2
        lib/libXi-1.3.tar.bz2
        lib/libXinerama-1.1.tar.bz2
        lib/libxkbfile-1.0.6.tar.bz2
        lib/libXrandr-1.3.0.tar.bz2
        lib/libXres-1.0.4.tar.bz2
        lib/libXScrnSaver-1.2.0.tar.bz2
        lib/libXtst-1.1.0.tar.bz2
        lib/libXv-1.0.5.tar.bz2
        lib/libXvMC-1.0.5.tar.bz2
        lib/libXxf86dga-1.1.1.tar.bz2
        lib/libXxf86vm-1.1.0.tar.bz2
        lib/libpciaccess-0.10.9.tar.bz2
        app/xauth-1.0.4.tar.bz2
        app/xdpyinfo-1.1.0.tar.bz2
    '''.split()
    X11R75 = [ s if s.startswith('http://') else ('http://www.x.org/releases/X11R7.5/src/' + s) for s in X11R75 ]

    X11R76 = '''
        proto/applewmproto-1.4.1.tar.bz2
        proto/bigreqsproto-1.1.1.tar.bz2
        proto/compositeproto-0.4.2.tar.bz2
        proto/damageproto-1.2.1.tar.bz2
        proto/dmxproto-2.3.tar.bz2
        proto/dri2proto-2.3.tar.bz2
        proto/fixesproto-4.1.2.tar.bz2
        proto/fontsproto-2.1.1.tar.bz2
        proto/glproto-1.4.12.tar.bz2
        proto/inputproto-2.0.1.tar.bz2
        proto/kbproto-1.0.5.tar.bz2
        proto/randrproto-1.3.2.tar.bz2
        proto/recordproto-1.14.1.tar.bz2
        proto/renderproto-0.11.1.tar.bz2
        proto/resourceproto-1.1.1.tar.bz2
        proto/scrnsaverproto-1.2.1.tar.bz2
        proto/videoproto-2.3.1.tar.bz2
        proto/windowswmproto-1.0.4.tar.bz2
        proto/xcmiscproto-1.2.1.tar.bz2
        proto/xextproto-7.1.2.tar.bz2
        proto/xf86bigfontproto-1.2.0.tar.bz2
        proto/xf86dgaproto-2.1.tar.bz2
        proto/xf86driproto-2.1.0.tar.bz2
        proto/xf86vidmodeproto-2.3.tar.bz2
        proto/xineramaproto-1.2.tar.bz2
        proto/xproto-7.0.20.tar.bz2
        lib/xtrans-1.2.6.tar.bz2
        lib/libXau-1.0.6.tar.bz2
        lib/libXdmcp-1.1.0.tar.bz2
        http://xcb.freedesktop.org/dist/xcb-proto-1.6.tar.bz2
        http://xcb.freedesktop.org/dist/libpthread-stubs-0.3.tar.bz2
        http://xcb.freedesktop.org/dist/libxcb-1.7.tar.bz2
        http://xcb.freedesktop.org/dist/xcb-util-0.3.6.tar.bz2
        lib/libX11-1.4.0.tar.bz2
        lib/libXext-1.2.0.tar.bz2
        lib/libdmx-1.1.1.tar.bz2
        lib/libfontenc-1.1.0.tar.bz2
        lib/libFS-1.0.3.tar.bz2
        lib/libICE-1.0.7.tar.bz2
        lib/libSM-1.2.0.tar.bz2
        lib/libXt-1.0.9.tar.bz2
        lib/libXmu-1.1.0.tar.bz2
        lib/libXpm-3.5.9.tar.bz2
        lib/libXaw-1.0.8.tar.bz2
        lib/libXfixes-4.0.5.tar.bz2
        lib/libXcomposite-0.4.3.tar.bz2
        lib/libXrender-0.9.6.tar.bz2
        lib/libXdamage-1.1.3.tar.bz2
        lib/libXcursor-1.1.11.tar.bz2
        lib/libXfont-1.4.3.tar.bz2
        lib/libXft-2.2.0.tar.bz2
        lib/libXi-1.4.0.tar.bz2
        lib/libXinerama-1.1.1.tar.bz2
        lib/libxkbfile-1.0.7.tar.bz2
        lib/libXrandr-1.3.1.tar.bz2
        lib/libXres-1.0.5.tar.bz2
        lib/libXScrnSaver-1.2.1.tar.bz2
        lib/libXtst-1.2.0.tar.bz2
        lib/libXv-1.0.6.tar.bz2
        lib/libXvMC-1.0.6.tar.bz2
        lib/libXxf86dga-1.1.2.tar.bz2
        lib/libXxf86vm-1.1.1.tar.bz2
        lib/libpciaccess-0.12.0.tar.bz2
        app/xauth-1.0.5.tar.bz2
        app/xdpyinfo-1.2.0.tar.bz2
    '''.split()
    X11R76 = [ s if s.startswith('http://') else ('http://www.x.org/releases/X11R7.6/src/' + s) for s in X11R76 ]

    for url in X11R76:
        tarball(url, EXTRA_LDFLAGS=('-lpthread' if 'xcb.freedesktop.org' in url else None))

    # X11 apps
    tarball('http://www.x.org/releases/individual/app/xclock-1.0.4.tar.bz2')
    tarball('http://www.x.org/releases/individual/app/xeyes-1.1.0.tar.bz2')
    tarball('http://www.x.org/releases/individual/app/twm-1.0.4.tar.bz2')
    tarball('http://www.x.org/releases/individual/app/xlsfonts-1.0.2.tar.bz2')

    tarball('http://dist.schmorp.de/rxvt-unicode/Attic/rxvt-unicode-9.07.tar.bz2', conf=' --enable-everything')
    tarball('http://www.kfish.org/software/xsel/download/xsel-1.2.0.tar.gz', preconf="sed -i -e 's/-Werror/-Wno-error/' ./configure")

    # Cairo & GTK
    tarball('http://cairographics.org/releases/pixman-0.20.2.tar.gz')
    tarball('http://cairographics.org/releases/cairo-1.10.2.tar.gz')
    tarball('http://ftp.gnome.org/pub/gnome/sources/atk/1.33/atk-1.33.6.tar.bz2')
    tarball('http://ftp.gnome.org/pub/gnome/sources/pango/1.28/pango-1.28.4.tar.bz2')
    tarball('http://ftp.gnome.org/pub/gnome/sources/gdk-pixbuf/2.23/gdk-pixbuf-2.23.3.tar.bz2')
    tarball('http://ftp.gnome.org/pub/gnome/sources/gtk+/2.24/gtk+-2.24.4.tar.bz2')

    vim_pkg = Package(
        name='vim',
        version='7.3.206',
        deps=['gtk+', 'cscope'],
        script=(
            'git clone git://github.com/b4winckler/vim.git\n'
            'cd vim\n'
            'git checkout 2bdcd40dc142484d235980f28c68def6da43251e\n'
            './configure --prefix=$LOCAL --with-features=huge --with-x --enable-gui=gtk2 --enable-cscope --enable-multibyte --enable-pythoninterp --disable-nls\n'
            '$PMAKE\n'
            #'$MAKE test\n'  -- hangs up during batch installs
            '$MAKE install\n'
        )
    )
    results.append(vim_pkg)

    if is_command_available('gfortran44'):
        tarball('http://cran.r-project.org/src/base/R-2/R-2.13.0.tar.gz', conf=' --with-x --disable-nls', skippable=1)
    else:
        print 'Skipping R because fortran is not available.\n'

    valgrind = Package(
        name='valgrind-freebsd',
        version='20110427',
        deps=['mercurial', 'autoconf'],
        script=(
            'hg clone https://bitbucket.org/stass/valgrind-freebsd\n'
            'cd valgrind-freebsd\n'
            'hg checkout c5f26602ead4\n'
            './autogen.sh\n'
            './configure --prefix=$LOCAL --enable-only64bit\n'
            '$PMAKE\n'
            '$MAKE install\n'
        )
    )
    results.append(valgrind)

    return results


def main():
    parser = optparse.OptionParser()
    parser.add_option('-q', dest='quiet')
    (options, args) = parser.parse_args()

    os.environ.clear()
    fill_build_environment(os.environ)

    bad_packages = []
    for pkg in package_list():
        try:
            install_package(pkg)
        except:
            sys.stderr.write('Failed to build package "%s"\n' % pkg.name)
            if not pkg.skippable:
                raise
            else:
                sys.stderr.write('Skipping %s\n' % pkg.name)
                bad_packages.append(pkg.name)

    if not os.path.exists(os.path.join(HOME, '.fonts')):
        print 'Manual action needed: install some fonts into ~/.fonts'

    print 'Finished.'
    if len(bad_packages) > 0:
        print 'Skipped packages: %s' % bad_packages

if __name__ == '__main__':
    main()
