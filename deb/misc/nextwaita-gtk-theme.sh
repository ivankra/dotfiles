#!/bin/bash
set -e -u -o pipefail

PKG=nextwaita-gtk-theme
VER=2.0

rm -rf pkg
mkdir -p pkg/DEBIAN pkg/usr/share/themes

(
  cd pkg/usr/share/themes &&
  tar xf ~/Downloads/Nextwaita-2.0.tar.xz
  tar xf ~/Downloads/Nextwaita-dark-2.0.tar.xz
)

cat >pkg/DEBIAN/control <<EOF
Package: $PKG
Version: $VER
Architecture: all
Maintainer: none
Section: dotfiles
Priority: optional
Homepage: https://www.gnome-look.org/p/1289376/
Description: Nextwaita GTK theme
EOF

fakeroot dpkg-deb --build -Zxz -z9 -Sextreme pkg "${PKG}_${VER}_all.deb"

rm -rf pkg
