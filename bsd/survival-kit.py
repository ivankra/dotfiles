#!/usr/bin/env python
# Downloads and compiles from source some generally useful software, Culminates in compiling a gtk+ enabled vim.
import os, re, sys, urllib2, optparse, hashlib

HOME = os.environ['HOME']
assert HOME.startswith('/home/')
LOCAL = os.path.join(HOME, '.local')
TARBALLS_DIR = LOCAL + '/tarballs'
INSTALLED_TARBALLS_FILE = os.path.join(LOCAL, 'installed-tarballs')
BUILD_DIR = LOCAL + '/build'

KNOWN_MD5_TEXT = """
76ca1c6e1d8904d2d885f81f7332eba6  applewmproto-1.4.1.tar.bz2
48e06ab8971acb9df4203fbda8d46d77  atk-1.29.92.tar.bz2
d30c5dbf19ca6dffcd9788227ecff8c5  bigreqsproto-1.1.0.tar.bz2
63584004613aaef2d3dca19088eb1654  bison-2.4.2.tar.bz2
b60a82f405f9400bbfdcf850b1728d25  cairo-1.8.10.tar.gz
3692f3f8b2ea10dff3d2cede8dc65e79  compositeproto-0.4.1.tar.bz2
56f549854d723d9dcebb77919019df55  coreutils-8.4.tar.gz
da43987622ace8c36bbf14c15a350ec1  cscope-15.7a.tar.bz2
c00f82ecdcc357434731913e5b48630d  ctags-5.8.tar.gz
3dda78c4a808d9a779dc3a2ae81b47d8  curl-7.20.0.tar.bz2
434b931b02bd83ed9fc44951df81cdac  damageproto-1.2.0.tar.bz2
d6bc1bdc874ddb14cfed4d1655a0dbbe  diffutils-2.9.tar.gz
880a41720b2937e2660dcdc0d34a8791  dmxproto-2.3.tar.bz2
5cb7987d29db068153bdc8f23c767c43  dri2proto-2.1.tar.bz2
351cc4adb07d54877fa15f75fb77d39f  findutils-4.4.2.tar.gz
4c1cb4f2ed9f34de59f2f04783ca9483  fixesproto-4.1.1.tar.bz2
10714e50cea54dc7a227e3eddcd44d57  flex-2.5.35.tar.bz2
77e15a92006ddc2adbb06f840d591c0e  fontconfig-2.8.0.tar.gz
f3a857deadca3144fba041af1dbf7603  fontsproto-2.1.0.tar.bz2
e974a82e5939be8e05ee65f07275d7c5  freetype-2.3.12.tar.bz2
674cc5875714315c490b26293d36dfcf  gawk-3.1.7.tar.bz2
21dce610476c054687b52770d2ddc657  gdb-7.1.tar.bz2
58a2bc6d39c0ba57823034d55d65d606  gettext-0.17.tar.gz
c7553b73e2156d187ece6ba936ae30ab  git-1.7.0.tar.bz2
45a8bc697d07f859566c0b64c40382a8  glib-2.24.0.tar.bz2
c9f8cebfba72bfab674bc0170551fb8d  glproto-1.4.10.tar.bz2
6bac6df75c192a13419dfd71d19240a7  gmp-5.0.1.tar.bz2
c1f1db32fb6598d6a93e6e88796a8632  gperf-3.0.4.tar.gz
8d1496da11029112a4d0986cbf09e26f  grep-2.6.1.tar.gz
48fa768dd6fdeb7968041dd5ae8e2b02  groff-1.20.1.tar.gz
5517f78b1eb9b1eb60bd48a0152d09e6  gtk+-2.20.0.tar.bz2
0f7acbc14a082f9ae03744396527d23d  inputproto-2.0.tar.bz2
5146e68be3633c597b0d14d3ed8fa2ea  jpegsrc.v8a.tar.gz
7f439166a9b2bf81471a33951883019f  kbproto-1.0.4.tar.bz2
b5864d76c54ddf4627fd57ab333c88b4  less-418.tar.gz
ecf2d6a27da053500283e803efa2a808  libFS-1.0.2.tar.bz2
2d39bc924af24325dae589e9a849180c  libICE-1.0.6.tar.bz2
6889a455496aaaa65b1fa05fc518d179  libSM-1.1.1.tar.bz2
001d780829f936e34851ef7cd37b4dfd  libX11-1.3.2.tar.bz2
33e54f64b55f22d8bbe822a5b62568cb  libXScrnSaver-1.2.0.tar.bz2
993b3185c629e4b89401fca072dcb663  libXau-1.0.5.tar.bz2
815e74de989ccda684e2baf8d12cf519  libXaw-1.0.7.tar.bz2
0f1367f57fdf5df17a8dd71d0fa68248  libXcomposite-0.4.1.tar.bz2
7dcdad1c10daea872cb3355af414b2ca  libXcursor-1.1.10.tar.bz2
b42780bce703ec202a33e5693991c09d  libXdamage-1.1.2.tar.bz2
d60941d471800f41a3f19b24bea855a7  libXdmcp-1.0.3.tar.bz2
c417c0e8df39a067f90a2a2e7133637d  libXext-1.1.1.tar.bz2
7f2c40852eb337b237ad944ca5c30d49  libXfixes-4.0.4.tar.bz2
4f2bed2a2be82e90a51a24bb3a22cdf0  libXfont-1.4.1.tar.bz2
254e62a233491e0e1251636536163e20  libXft-2.1.14.tar.bz2
8df4ece9bd1efb02c28acb2b6f485e09  libXi-1.3.tar.bz2
a2ac01fc0426cdbb713c5d59cf9955ed  libXinerama-1.1.tar.bz2
fc4d66be7a1a1eb474954728415e46d6  libXmu-1.0.5.tar.bz2
38e58e72d476a74298a59052fde185a3  libXpm-3.5.8.tar.bz2
68eb59c3b7524db6ffd78746ee893d1d  libXrandr-1.3.0.tar.bz2
276dd9e85daf0680616cd9f132b354c9  libXrender-0.9.5.tar.bz2
4daf91f93d924e693f6f6ed276791be2  libXres-1.0.4.tar.bz2
96f3c93434a93186d178b60d4a262496  libXt-1.0.7.tar.bz2
dd6f3e20b87310187121539f9605d977  libXtst-1.1.0.tar.bz2
1d97798b1d8bbf8d9085e1b223a0738f  libXv-1.0.5.tar.bz2
16c3a11add14979beb7510e44623cac6  libXvMC-1.0.5.tar.bz2
368837d3d7a4d3b4f70be48383e3544e  libXxf86dga-1.1.1.tar.bz2
b431ad7084e1055fef99a9115237edd8  libXxf86vm-1.1.0.tar.bz2
a2fcf0382837888d3781b714489a8999  libdmx-1.1.0.tar.bz2
4f0d8191819be9f2bdf9dad49a65e43b  libfontenc-1.0.5.tar.bz2
7ab33ebd26687c744a37264a330bbe9a  libiconv-1.13.1.tar.gz
685cb20e7a6165bc010972f1183addbd  libpciaccess-0.10.9.tar.bz2
e1767bf290ded9fda9ee05bd23ae4cff  libpng-1.4.1.tar.bz2
774eabaf33440d534efe108ef9130a7d  libpthread-stubs-0.1.tar.bz2
b00fd506c717dea01f595e8da31f6914  libxcb-1.4.tar.bz2
b01156e263eca8177e6b7f10441951c4  libxkbfile-1.0.6.tar.bz2
9abc9959823ca9ff904f1fbcf21df066  libxml2-2.7.7.tar.gz
e61d0364a30146aaa3001296f853b2b9  libxslt-1.1.26.tar.gz
e6fb7d08d50d87e796069cff12a52a93  m4-1.4.14.tar.bz2
354853e0b2da90c527e35aabb8d6f1e6  make-3.81.tar.bz2
ca382dd934fc8b9e9a64d13354be48cf  man-db-2.5.5.tar.gz
cce05daf61a64501ef6cd8da1f727ec6  ncurses-5.7.tar.gz
0a29eff1736ddb5effd0b1ec1f6fe0ef  netcat-0.7.1.tar.bz2
076d8efc3ed93646bd01f04e23c07066  openssl-0.9.8n.tar.gz
ffc867ee6c3173bc3941002f33ea4148  pango-1.27.1.tar.bz2
5729b1430ba6c2216e0f3eb18f213c81  patch-2.6.tar.bz2
b0ad87c2cc9346056698eaf6af1933a6  pixman-0.17.14.tar.gz
d922a88782b64441d06547632fd85744  pkg-config-0.23.tar.gz
a5c244c36382b0de39b2828cea4b651d  randrproto-1.3.1.tar.bz2
70f5998c673aa510e2acd6d8fb3799de  recordproto-1.14.tar.bz2
b160a9733fe91b666e74fca284333148  renderproto-0.11.tar.bz2
84795594b3ebd2ee2570cf93340d152c  resourceproto-1.1.0.tar.bz2
49bb52c99e002bf85eb41d8385d903b5  rxvt-unicode-9.07.tar.bz2
9040c991a56ee9b5976936f8c65d5c8a  scrnsaverproto-1.2.0.tar.bz2
7d310fbd76e01a01115075c1fd3f455a  sed-4.2.1.tar.bz2
9c0c5e83ce665f38d4d3aababad275eb  socat-1.7.1.2.tar.bz2
41e2ca4b924ec7860e51b43ad06cdb7e  tar-1.23.tar.bz2
93e56e421679c591de7552db13384cb8  tiff-3.9.2.tar.gz
0865e14c73c08fa8c501ae877298ee9f  twm-1.0.4.tar.bz2
fb762146a18207a1e8bc9f299dfc7ac0  videoproto-2.3.0.tar.bz2
f0901284b338e448bfd79ccca0041254  vim-7.2.tar.bz2
308a5476fc096a8a525d07279a6f6aa3  wget-1.12.tar.bz2
e74b2ff3172a6117f2a62b655ef99064  windowswmproto-1.0.4.tar.bz2
fa00078c414c4a57cab7a6d89a0c8734  xauth-1.0.4.tar.bz2
f9ddd4e70a5375508b3acaf17be0d0ab  xbitmaps-1.1.0.tar.bz2
7d0481790104a10ff9174895ae954533  xcb-proto-1.5.tar.bz2
dd8968b8ee613cb027a8ef1fcbdc8fc9  xcb-util-0.3.6.tar.bz2
bb9fd5e00d39c348a0078b97fdf8258f  xclock-1.0.4.tar.bz2
7b83e4a7e9f4edc9c6cfb0500f4a7196  xcmiscproto-1.2.0.tar.bz2
d1d516610316138105cd07064b257c5c  xdpyinfo-1.1.0.tar.bz2
fb6ccaae76db7a35e49b12aea60ca6ff  xextproto-7.1.1.tar.bz2
933f6d2b132d14f707f1f3c87b39ebe2  xeyes-1.1.0.tar.bz2
120e226ede5a4687b25dd357cc9b8efe  xf86bigfontproto-1.2.0.tar.bz2
a036dc2fcbf052ec10621fd48b68dbb1  xf86dgaproto-2.1.tar.bz2
309d552732666c3333d7dc63e80d042f  xf86driproto-2.1.0.tar.bz2
4434894fc7d4eeb4a22e6b876d56fdaa  xf86vidmodeproto-2.3.tar.bz2
a8aadcb281b9c11a91303e24cdea45f5  xineramaproto-1.2.tar.bz2
28958248590ff60ecd70e8f590d977b7  xlsfonts-1.0.2.tar.bz2
75c9edff1f3823e5ab6bb9e66821a901  xproto-7.0.16.tar.bz2
75983f143ce83dc259796c6eaf85c8f5  xsel-1.2.0.tar.gz
2d1e57e82acc5f21797e92341415af2f  xtrans-1.2.5.tar.bz2
cc4044fcc073b8bcf3164d1d0df82161  xz-4.999.9beta.tar.bz2
"""
KNOWN_MD5 = dict((b, a) for (a, b) in [s.split() for s in KNOWN_MD5_TEXT.strip().split('\n')])

def is_command_available(name):
    return os.system("which '%s' >/dev/null 2>/dev/null" % name) == 0

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

    for gcc, gxx in (('gcc44', 'g++44'), ('gcc', 'g++')):
        if is_command_available(gcc) and is_command_available(gxx):
            env['CC'] = gcc
            env['CXX'] = gxx
            break

def sh(cmd):
    print cmd
    n = os.system(cmd)
    if n != 0:
        raise Exception('Command "%s" terminated with exit code %d' % (cmd, n))

def check_symlink(src, dst):
    try:
        return os.readlink(src) == dst
    except:
        return False

def download(url, path):
    assert "'" not in (url + path)
    if is_command_available('wget'):
        sh("wget -O '%s' '%s'" % (path + '.temp', url))
    elif is_command_available('curl'):
        sh("curl '%s' > '%s'" % (url, path + '.temp'))
    else:
        file(path + '.temp', 'w').write(urllib2.urlopen(url).read())
    sh("mv -f '%s' '%s'" % (path + '.temp', path))

def is_installed(package_id):
    if os.path.exists(INSTALLED_TARBALLS_FILE):
        for line in file(INSTALLED_TARBALLS_FILE):
            if line.strip() == package_id:
                return True
    return False

def mark_installed(package_id):
    file(INSTALLED_TARBALLS_FILE, 'a').write(package_id + '\n')

def install_tarball(entry):
    url = entry['url']

    package_id = entry.get('package_id', os.path.basename(url))
    if is_installed(package_id):
        print '%s is already installed' % package_id
        return

    print 'Installing %s (%s)' % (package_id, url)

    if not os.path.exists(LOCAL):
        os.makedirs(LOCAL)

    if 'url_basename' in entry:
        url_basename = entry['url_basename']
        url_filename = entry['url_filename']
    else:
        m = re.match(r'.*/(([^/]*)\.tar\.(gz|bz2))$', url)
        if not m:
            raise Exception("Couldn't parse the URL: %s" % url)
        url_filename, url_basename, gz_bz2 = m.groups()

    if not os.path.exists(TARBALLS_DIR):
        os.makedirs(TARBALLS_DIR)
    archive_path = os.path.join(TARBALLS_DIR, url_filename)
    if not os.path.exists(archive_path):
        download(url, archive_path)

    if url_filename in KNOWN_MD5:
        m = hashlib.md5()
        m.update(file(archive_path).read())
        m = m.hexdigest()
        if KNOWN_MD5[url_filename] != m:
            raise Exception('File "%s" has md5 sum %s, expected md5 %s' % (archive_path, m, KNOWN_MD5_TEXT[url_filename]))

    if os.path.exists(BUILD_DIR):
        sh("rm -rf '%s'" % BUILD_DIR)
    os.makedirs(BUILD_DIR)
    os.chdir(BUILD_DIR)
    sh("tar xf '%s'" % archive_path)

    file_list = os.listdir('.')
    if len(file_list) != 1:
        raise Exception("Tarball %s contained multiple files/directories at the top level: %s" % (url, file_list))
    os.chdir(file_list[0])

    cmd = entry.get('config_make_install',
            "%(pre_configure)s && ./configure '--prefix=%(LOCAL)s' %(configure_flags)s && nice -20 make -j 10 && make install && %(post_install)s")
    sh(cmd % dict(
        LOCAL=LOCAL,
        pre_configure=entry.get('pre_configure', 'true'),
        configure_flags=entry.get('configure_flags', ''),
        post_install=entry.get('post_install', 'true')))

    os.chdir(LOCAL)
    sh("rm -rf '%s'" % BUILD_DIR)

    print 'Installed %s' % package_id
    mark_installed(package_id)

###############################################################################

def get_package_list():
    page_cache = dict()

    def xorg(package, **extra):
        url = 'http://www.x.org/releases/X11R7.5/src/' + package
        if '.tar' in url:
            return url
        dir = os.path.dirname(url)
        if dir not in page_cache:
            page_cache[dir] = urllib2.urlopen(dir).read()
        page = page_cache[dir]
        matches = re.findall('<a href="(%s-[^"]*.tar.bz2)">' % os.path.basename(package), page)
        if len(matches) != 1:
            raise Exception('Failed to find package %s (found %d matches on page %s)' % (
                os.path.basename(package), len(matches), dir))
        res = dir + '/' + matches[0]
        return dict(url=res, **extra)

    def gnu(package, **extra):
        #return 'http://ftp.gnu.org/gnu/' + package
        return dict(url='http://mirrors.kernel.org/gnu/' + package, **extra)

    return [
        # let's install some gnu tools to replace the junk shipped with bsd.
        gnu('make/make-3.82.tar.bz2', config_make_install="./configure '--prefix=%(LOCAL)s' && make && make install"),
        gnu('wget/wget-1.12.tar.bz2'),
        gnu('libiconv/libiconv-1.13.1.tar.gz'),
        gnu('gettext/gettext-0.18.1.1.tar.gz'),
        gnu('ncurses/ncurses-5.9.tar.gz'),
        gnu('gmp/gmp-5.0.1.tar.bz2'),
        gnu('tar/tar-1.26.tar.bz2'),
        gnu('coreutils/coreutils-8.9.tar.gz', post_install='mv -f %s/bin/wc %s/bin/gnu.wc' % (LOCAL, LOCAL)),  # native wc is so much faster
        'http://tukaani.org/xz/xz-4.999.9beta.tar.bz2',
        gnu('diffutils/diffutils-3.0.tar.gz'),
        gnu('findutils/findutils-4.4.2.tar.gz'),
        gnu('patch/patch-2.6.tar.bz2'),
        gnu('grep/grep-2.7.tar.gz'),
        gnu('groff/groff-1.20.1.tar.gz', configure_flags='--x-includes=%s/include --x-libraries=%s/lib' % (LOCAL, LOCAL)),  # note: 1.21 is broken
        gnu('m4/m4-1.4.16.tar.bz2'),
        gnu('sed/sed-4.2.1.tar.bz2'),
        gnu('gawk/gawk-3.1.8.tar.bz2'),
        gnu('bison/bison-2.4.3.tar.bz2'),
        gnu('less/less-418.tar.gz'),
        dict(url='http://ftp.twaren.net/Unix/NonGNU/man-db/man-db-2.5.5.tar.gz', post_install='chmod u-s %s/bin/man %s/bin/mandb' % (LOCAL, LOCAL)),
        'http://downloads.sourceforge.net/flex/flex-2.5.35.tar.bz2',
        dict(url='http://www.openssl.org/source/openssl-0.9.8n.tar.gz',
            package_id='openssl-0.9.8n.tar.gz (static)',
            config_make_install='./config --openssldir=%s/etc/ssl --prefix=%s && (make -j 20 || make) && make install' % (LOCAL, LOCAL)),
        dict(url='http://www.openssl.org/source/openssl-0.9.8n.tar.gz',
            package_id='openssl-0.9.8n.tar.gz (shared)',
            config_make_install='./config --openssldir=%s/etc/ssl --prefix=%s shared && (make -j 20 || make) && make install' % (LOCAL, LOCAL)),
        'http://curl.haxx.se/download/curl-7.21.4.tar.bz2',
        #gnu('gdb/gdb-7.1.tar.bz2',
        #    pre_configure="export CC=gcc CXX=g++"),  # gcc44 produced a binary that crashes with "Bad system call: 12"
        gnu('gperf/gperf-3.0.4.tar.gz'),

        dict(url='http://downloads.sourceforge.net/project/netcat/netcat/0.7.1/netcat-0.7.1.tar.bz2',
            pre_configure='export CFLAGS="-O2 -static"; export LDFLAGS="$CFLAGS"'),
        'http://www.dest-unreach.org/socat/download/socat-1.7.1.2.tar.bz2',
        'http://downloads.sourceforge.net/ctags/ctags-5.8.tar.gz',
        'http://downloads.sourceforge.net/project/cscope/cscope/15.7a/cscope-15.7a.tar.bz2',

        'http://xmlsoft.org/sources/libxml2-2.7.7.tar.gz',
        'http://xmlsoft.org/sources/libxslt-1.1.26.tar.gz',
        'http://pkgconfig.freedesktop.org/releases/pkg-config-0.23.tar.gz',
        'http://ftp.gnome.org/pub/gnome/sources/glib/2.24/glib-2.24.0.tar.bz2',
        dict(
            url='http://www.fontconfig.org/release/fontconfig-2.8.0.tar.gz',
            pre_configure='export CC=gcc CXX=g++',
        ),
        'http://downloads.sourceforge.net/freetype/freetype-2.3.12.tar.bz2',
        'http://www.ijg.org/files/jpegsrc.v8a.tar.gz',
        'http://downloads.sourceforge.net/libpng/01-libpng-master/1.4.1/libpng-1.4.1.tar.bz2',
        'http://download.osgeo.org/libtiff/tiff-3.9.2.tar.gz',  #'ftp://ftp.remotesensing.org/pub/libtiff/tiff-3.9.2.tar.gz',

        dict(
            url='http://www.cpan.org/src/5.0/perl-5.8.9.tar.bz2',
            config_make_install=(
                'set -x; cd hints; chmod a+rw *; '
                r'''echo -e '223c223\n< 		 exit 1\n---\n> 		 ldflags="-pthread $ldflags"  # FUCK BSD!\n' | patch freebsd.sh; cd ..; ''' +
                'sed -i -e "s/<command line>/<command-line>/" makedepend.SH; '
                './Configure -sde -Dprefix=%(LOCAL)s -Dvendorprefix=%(LOCAL)s ' + 
                '-Dman1dir=%(LOCAL)s/share/man/man1 -Dman3dir=%(LOCAL)s/share/man/man3 ' +
                '-Dsiteman1dir=%(LOCAL)s/share/man/man1 -Dsiteman3dir=%(LOCAL)s/share/man/man3 ' +
                '"-Dpager=%(LOCAL)s/bin/less -isR"'
                '-Darchlib=%(LOCAL)s/lib/perl5/5.8.9/mach ' + 
                '-Dprivlib=%(LOCAL)s/lib/perl5/5.8.9 ' + 
                '-Dsitearchlib=%(LOCAL)s/lib/perl5/site_perl/5.8.9/mach ' + 
                '-Dsitelib=%(LOCAL)s/lib/perl5/site_perl/5.8.9 ' + 
                '-Ui_malloc -Ui_iconv -Dcc=cc -Duseshrplib ' +  # gcc 4.2.1 ?
                '"-Doptimize=-O2 -fno-strict-aliasing -pipe -mtune=native" -Ud_dosuid -Ui_gdbm -Dusethreads=y -Dusemymalloc=n -Duse64bitint &&'
                # -Dinc_version_list=none -Uinstallusrbinperl -Dscriptdir=/usr/local/bin
                #'-Dccflags=-DAPPLLIB_EXP="/usr/local/lib/perl5/5.8.9/BSDPAN" ' +
                ' make -j 10 && make install' %
                { 'LOCAL': LOCAL }
            )
        ),

        'http://www.sqlite.org/sqlite-amalgamation-3.6.13.tar.gz',
        'http://sourceforge.net/projects/pcre/files/pcre/8.12/pcre-8.12.tar.bz2',
        dict(
            url='http://prdownloads.sourceforge.net/swig/swig-2.0.3.tar.gz',
            config_make_install=(
                'export LDFLAGS=-lpcre; ./configure --with-pcre-prefix=%s --prefix=%s && make -j 10 && make install' % (LOCAL, LOCAL)
            )
        ),
        dict(
            url='http://subversion.tigris.org/downloads/subversion-1.6.16.tar.bz2',
            config_make_install=(
                './configure --prefix=%s && make -j 10 && make install && make swig-pl && make check-swig-pl && make install-swig-pl' % LOCAL
            )
        ),
        dict(url='http://www.kernel.org/pub/software/scm/git/git-1.7.4.4.tar.bz2',
            config_make_install=(
                'export PYTHON_PATH=$(which python); ./configure --prefix=%s && make -j 10 && make install && ' % LOCAL +
                '(cd %s/man && curl http://www.kernel.org/pub/software/scm/git/git-manpages-1.7.4.4.tar.bz2 | tar -jx) && ' % LOCAL +
                r"sed -i -e 's/^#![/]usr[/]bin[/]perl/^#\/usr\/bin\/env perl/' %s/libexec/git-core/git-*" % LOCAL
            )
        ),

        # X11 libs
        xorg('proto/applewmproto'),
        xorg('proto/bigreqsproto'),
        xorg('proto/compositeproto'),
        xorg('proto/damageproto'),
        xorg('proto/dmxproto'),
        xorg('proto/dri2proto'),
        xorg('proto/fixesproto'),
        xorg('proto/fontsproto'),
        xorg('proto/glproto'),
        xorg('proto/inputproto'),
        xorg('proto/kbproto'),
        xorg('proto/randrproto'),
        xorg('proto/recordproto'),
        xorg('proto/renderproto'),
        xorg('proto/resourceproto'),
        xorg('proto/scrnsaverproto'),
        xorg('proto/videoproto'),
        xorg('proto/windowswmproto'),
        xorg('proto/xcmiscproto'),
        xorg('proto/xextproto'),
        xorg('proto/xf86bigfontproto'),
        xorg('proto/xf86dgaproto'),
        xorg('proto/xf86driproto'),
        xorg('proto/xf86vidmodeproto'),
        xorg('proto/xineramaproto'),
        xorg('proto/xproto'),
        xorg('lib/xtrans'),
        xorg('lib/libXau'),
        xorg('lib/libXdmcp'),
        'http://xcb.freedesktop.org/dist/xcb-proto-1.5.tar.bz2',
        'http://xcb.freedesktop.org/dist/libpthread-stubs-0.1.tar.bz2',
        'http://xcb.freedesktop.org/dist/libxcb-1.4.tar.bz2',
        'http://xcb.freedesktop.org/dist/xcb-util-0.3.6.tar.bz2',
        xorg('lib/libX11'),
        xorg('lib/libXext'),
        xorg('lib/libdmx'),
        xorg('lib/libfontenc'),
        xorg('lib/libFS'),
        xorg('lib/libICE'),
        xorg('lib/libSM'),
        xorg('lib/libXt'),
        xorg('lib/libXmu'),
        xorg('lib/libXpm'),
        xorg('lib/libXaw'),
        xorg('lib/libXfixes'),
        xorg('lib/libXcomposite'),
        xorg('lib/libXrender'),
        xorg('lib/libXdamage'),
        xorg('lib/libXcursor'),
        xorg('lib/libXfont'),
        xorg('lib/libXft'),
        xorg('lib/libXi'),
        xorg('lib/libXinerama'),
        xorg('lib/libxkbfile'),
        xorg('lib/libXrandr'),
        xorg('lib/libXres'),
        xorg('lib/libXScrnSaver'),
        xorg('lib/libXtst'),
        xorg('lib/libXv'),
        xorg('lib/libXvMC'),
        xorg('lib/libXxf86dga'),
        xorg('lib/libXxf86vm'),
        xorg('lib/libpciaccess'),
        #build pixman ""
        'http://xorg.freedesktop.org/releases/individual/data/xbitmaps-1.1.0.tar.bz2',
        #'http://xorg.freedesktop.org/releases/individual/data/xcursor-themes-1.0.2.tar.bz2',

        # X11 apps
        xorg('app/xauth', pre_configure="export CFLAGS=-static LDFLAGS=-static LIBS='-lxcb -lXdmcp -lXau'"),  # link statically
        xorg('app/xdpyinfo'),
        'http://www.x.org/releases/individual/app/xclock-1.0.4.tar.bz2',
        'http://www.x.org/releases/individual/app/xeyes-1.1.0.tar.bz2',
        'http://www.x.org/releases/individual/app/twm-1.0.4.tar.bz2',
        'http://www.x.org/releases/individual/app/xlsfonts-1.0.2.tar.bz2',
        dict(url='http://dist.schmorp.de/rxvt-unicode/Attic/rxvt-unicode-9.07.tar.bz2', configure_flags='--enable-everything'),
        dict(url='http://www.vergenet.net/~conrad/software/xsel/download/xsel-1.2.0.tar.gz',
            pre_configure="sed -i -e 's/-Werror/-Wno-error/' ./configure"),

        # GTK
        'http://cairographics.org/releases/pixman-0.20.2.tar.gz',
        dict(url='http://cairographics.org/releases/cairo-1.10.2.tar.gz', pre_configure='export CC=gcc CXX=g++'),
        'http://ftp.gnome.org/pub/gnome/sources/atk/1.29/atk-1.29.92.tar.bz2',
        'http://ftp.gnome.org/pub/gnome/sources/pango/1.27/pango-1.27.1.tar.bz2',
        'http://ftp.gnome.org/pub/gnome/sources/gtk+/2.20/gtk+-2.20.0.tar.bz2',

        # TODO: git clone git://github.com/b4winckler/vim.git && ...
        #dict(url='ftp://ftp.vim.org/pub/vim/unix/vim-7.2.tar.bz2',
        #    config_make_install=(
        #        'set -x; ' +
        #        'wget ftp://ftp.vim.org/pub/vim/extra/vim-7.2-extra.tar.gz && tar xf vim-7.2-extra.tar.gz && ' + 
        #        'wget ftp://ftp.vim.org/pub/vim/extra/vim-7.2-extra.tar.gz && (cd ..; tar xf vim72/vim-7.2-extra.tar.gz) && ' + 
        #        'wget ftp://ftp.vim.org/pub/vim/extra/vim-7.2-lang.tar.gz && (cd ..; tar xf vim72/vim-7.2-lang.tar.gz) && ' + 
        #        'curl http://ftp.vim.org/pub/vim/patches/7.2/7.2.001-100.gz | gzip -d | patch -p0 && ' +
        #        'curl http://ftp.vim.org/pub/vim/patches/7.2/7.2.101-200.gz | gzip -d | patch -p0 && ' +
        #        'curl http://ftp.vim.org/pub/vim/patches/7.2/7.2.201-300.gz | gzip -d | patch -p0 && ' +
        #        'curl http://ftp.vim.org/pub/vim/patches/7.2/7.2.301-400.gz | gzip -d | patch -p0 && ' +
        #        ' && '.join(['curl http://ftp.vim.org/pub/vim/patches/7.2/7.2.%.3d | patch -p0' % n for n in range(401, 445)]) + ' && ' +
        #        './configure --prefix=%s --with-features=huge --with-x --with-gui=gtk2 --enable-cscope --enable-multibyte --enable-pythoninterp --disable-nls && ' % LOCAL +
        #        'make -j 10 && '
        #        'make install'
        #    ),            
        #),
    ]

def main():
    args = sys.argv[1:]
    if len(args) == 0 or any([s.startswith('-') for s in args]):
        print 'Usage:'
        print '  survival-kit.py go               installs a hard-coded list of packages'
        print '  survival-kit.py url1 [url2] ...  installs tarballs from specified URLs'
        print 'Software will be installed in %s' % LOCAL
        sys.exit(1)

    fill_build_environment(os.environ)

    if args == ['go']:
        for entry in get_package_list():
            if type(entry) is str:
                entry = dict(url=entry)
            assert type(entry) is dict
            url = entry['url']
            install_tarball(entry)

        if not os.path.exists(os.path.join(os.environ['HOME'], '.fonts')):
            print 'Action needed: install some fonts into ~/.fonts'
    else:
        for s in args:
            install_tarball(dict(url=s))

main()
