#!/usr/bin/env python
import os, sys

packages = '''
adblock-plus
amule
aptitude
autoconf
automake
avidemux
bison
bochs
build-essential
bum
byobu
calibre
cgdb
checkinstall
cmake
cmake-curses-gui
cmake-gui
cone
cpufrequtils
crack-attack
cscope
curl
cvs
ddd
dosbox
doxygen
ecryptfs-utils
elinks
exif
expat
exuberant-ctags
fbreader
ffmpeg
flex
fortune-mod
g++
gawk
gcc-doc
gdb-doc
geany
gimp
git-core
gitk
git-svn
gitweb
global
glpk
gltron
gmp-doc
g++-multilib
gnome-mplayer
gnuplot
gparted
gperf
graphviz
gtkpod
htop
human-theme
iamerican
id-utils
imagemagick
indent
inkscape
iotop
ipython
irussian
ispell
kcachegrind
language-support-ru
latex-beamer
libatk1.0-dev
libbonoboui2-dev
libcairo2-dev
libgmp3-dev
libgmp3-doc
libgnome2-dev
libgnomeui-dev
libgsl0-dev
libgtk2.0-dev
libncurses5-dev
libnotify-bin
libpcap-dev
libssl-dev
libsvm-tools
libusb-1.0-0
libusb-1.0-0-dev
libx11-dev
libxpm-dev
libxt-dev
lm-sensors
mailutils
manpages-dev
manpages-posix
manpages-posix-dev
mc
mercurial
mplayer
mutt
nautilus-open-terminal
network-manager-openvpn-gnome
nmap
ntp
octave3.2
octave3.2-info
openjdk-6-jdk
openoffice.org-thesaurus-ru
openssh-server
openvpn
p7zip-full
pidgin
powertop
pwgen
pychecker
python2.6
python3-all
python-all
python-dev
python-doc
python-gmpy
python-matplotlib
python-pyparsing
python-rpy2
python-scipy
python-setuptools
qbittorrent
qemu
rar
r-base
r-cran-randomforest
rdesktop
rrdtool
ruby
scalable-cyrfonts-tex
scons
scummvm
sdparm
socat
sox
sqlite
sqlite3
sshfs
strace
subversion
swig
sysfsutils
tcpdump
texlive
texlive-generic-extra
texlive-lang-cyrillic
texlive-latex-extra
texlive-science
texmaker
thunderbird
tkdiff
tofrodos
traceroute
ubuntu-restricted-extras
unetbootin
unrar
valgrind
vim
vim-gnome
vinagre
vlc
wamerican-huge
weka
wine
wireshark
xsel
fakeroot build-essential crash kexec-tools makedumpfile kernel-wedge
git-core libncurses5 libncurses5-dev libelf-dev asciidoc binutils-dev
mesa-utils

-f-spot
-gwibber
-gwibber-service
-tomboy
-ubuntuone-client
'''

packages = packages.split()

if len(sys.argv) == 2:
    release = int(float(sys.argv[1]) * 100 + 1e-5)
else:
    release = int(float(os.popen('lsb_release -r -s', 'r').read()) * 100 + 1e-5)

if release >= 1010:
    packages += 'g++-4.5 python2.7'.split()

print '#!/bin/sh'
print 'sudo apt-get install ' + ' '.join([s for s in packages if not s.startswith('-')])
print 'sudo apt-get build-dep linux'
print 'sudo apt-get remove ' + ' '.join([s[1:] for s in packages if s.startswith('-')])
print 'sudo easy_install gitserve'
