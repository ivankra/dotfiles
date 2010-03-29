#!/usr/bin/env python
# Downloads and compiles from source some generally useful software,
# Now includes X11 libs!
import os, re, sys, urllib2

HOME = os.environ['HOME']
assert HOME.startswith('/home/')
LOCAL = os.path.join(HOME, '.local')
BUILD_DIR = os.path.join(LOCAL, 'build')  # for tarball archives and builds
INSTALLED_TARBALLS_FILE = os.path.join(LOCAL, 'installed-tarballs')

os.environ['PATH'] = LOCAL + '/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
os.environ['PKG_CONFIG_PATH'] = '%s/lib/pkgconfig:%s/share/pkgconfig' % (LOCAL, LOCAL)
os.environ['CPATH'] = LOCAL + '/include'
os.environ['LIBRARY_PATH'] = LOCAL + '/lib'
os.environ['LD_LIBRARY_PATH'] = LOCAL + '/lib'


def sh(cmd):
    print cmd
    n = os.system(cmd)
    if n != 0:
        raise Exception('Command "%s" terminated with exit code %d' % (cmd, n))

def download(url, path):
    if os.system('which wget >/dev/null') == 0:
        sh("wget -O '%s' '%s'" % (path + '.temp', url))
    elif os.system('which curl >/dev/null') == 0:
        sh("curl '%s' > '%s'" % (url, path + '.temp'))
    else:
        file(path + '.temp', 'w').write(urlopen2.urlopen(url).read())
    sh("mv -f '%s' '%s'" % (path + '.temp', path))

def is_installed(package_id):
    if os.path.exists(INSTALLED_TARBALLS_FILE):
        for line in file(INSTALLED_TARBALLS_FILE):
            if line.strip() == package_id:
                return True
    return False

def mark_installed(package_id):
    file(INSTALLED_TARBALLS_FILE, 'a').write(package_id + '\n')

def install_tarball(url):
    print 'Installing %s' % url

    if not os.path.exists(LOCAL):
        os.makedirs(LOCAL)

    if not os.path.exists(BUILD_DIR):
        os.makedirs(BUILD_DIR)

    m = re.match(r'.*/(([^/]*)\.tar\.(gz|bz2))$', url)
    if not m:
        raise Exception("Couldn't parse the URL: %s" % url)

    archive, basename, gz_bz2 = m.groups()
    archive_path = os.path.join(BUILD_DIR, archive)
    if not os.path.exists(archive_path):
        download(url, archive_path)

    os.chdir(BUILD_DIR)
    sh("rm -rf '%s'" % basename)
    sh("tar xf '%s'" % archive)
    if not os.path.exists(basename):
        raise Exception('Tarball %s wasn\'t extracted into "%s"' % (url, basename))

    sh("cd '%s' && ./configure '--prefix=%s' && make && make install" % (basename, LOCAL))
    os.chdir(BUILD_DIR)
    sh("rm -rf '%s'" % basename)

    print 'Installed %s' % url

###############################################################################

_page_cache = {}
def xorg(package):
    global _page_cache
    url = 'http://www.x.org/releases/X11R7.5/src/' + package
    if '.tar' in url:
        return url
    dir = os.path.dirname(url)
    if dir not in _page_cache:
        _page_cache[dir] = urllib2.urlopen(dir).read()
    page = _page_cache[dir]
    matches = re.findall('<a href="(%s-[^"]*.tar.bz2)">' % os.path.basename(package), page)
    if len(matches) != 1:
        raise Exception('Failed to find package %s (found %d matches on page %s)' % (
            os.path.basename(package), len(matches), dir))
    res = dir + '/' + matches[0]
    return dict(url=res)

def gnu(package):
    #return 'http://ftp.gnu.org/gnu/' + package
    return dict(url='http://mirrors.kernel.org/gnu/' + package)

PACKAGES = [
    # let's install some gnu tools to replace the junk shipped with bsd.
    gnu('make/make-3.81.tar.bz2')
    gnu('tar/tar-latest.tar.bz2'),
    gnu('coreutils/coreutils-8.4.tar.gz')
    gnu('diffutils/diffutils-2.9.tar.gz'),
    gnu('findutils/findutils-4.4.2.tar.gz'),
    gnu('patch/patch-2.6.1.tar.bz2'),
    gnu('grep/grep-2.6.1.tar.gz'),
    gnu('groff/groff-1.20.1.tar.gz'),
    gnu('m4/m4-1.4.14.tar.bz2'),
    gnu('sed/sed-4.2.1.tar.bz2'),
    gnu('gawk/gawk-3.1.7.tar.bz2'),
    gnu('bison/bison-2.4.2.tar.bz2'),
    dict(url='http://prdownloads.sourceforge.net/flex/flex-2.5.35.tar.bz2?download'),
    gnu('libiconv/libiconv-1.13.1.tar.gz'),
    gnu('gettext/gettext-0.17.tar.gz'),
    gnu('ncurses/ncurses-5.7.tar.gz'),
    gnu('gmp/gmp-5.0.1.tar.bz2'),
    gnu('git/gnuit-4.9.5.tar.gz'),
    gnu('gdb/gdb-7.1.tar.bz2'),

    #xorg('proto/applewmproto'),
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
    #xorg('proto/windowswmproto'),
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
    #build xcb pthread-stubs
    #build xcb libxcb
    #build xcb util
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

    xorg('app/xauth'),
    xorg('app/xdpyinfo'),
]

del gnu
del xorg

def main():
    for d in PACKAGES:
        url = d['url']
        package_id = d.get('package_id', os.path.basename(url))
        if not is_installed(package_id):
            install_tarball(url)
            mark_installed(package_id)

main()
