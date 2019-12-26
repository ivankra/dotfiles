#!/bin/bash
set -e -u -o pipefail

PKG=flexi-gnome-gtk-theme
VER=1.1

rm -rf pkg
mkdir -p pkg/DEBIAN pkg/usr/share/themes

(
  cd pkg/usr/share/themes &&
  tar xf ~/Downloads/Flexi-Gnome-1-1.tar.xz
)

cat >pkg/DEBIAN/control <<EOF
Package: $PKG
Version: $VER
Architecture: all
Maintainer: none
Section: dotfiles
Priority: optional
Homepage: https://www.gnome-look.org/p/1333131/
Description: Flexi-Gnome GTK theme
EOF

fakeroot dpkg-deb --build -Zxz -z9 -Sextreme pkg "${PKG}_${VER}_all.deb"

rm -rf pkg
