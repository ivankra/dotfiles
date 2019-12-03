#!/bin/bash
set -e -u -o pipefail -x

(rm -rf src && mkdir src && cd src && tar xf ~/Downloads/Complete-Yaru-Colors-v2.3.tar.xz)
VER=2.3

for name in Yaru-{Aqua,Blue,Brown,Deepblue,Green,Grey,MATE,Pink,Purple,Red,Yellow}; do
  PKG=${name,,}-theme-gtk
  rm -rf pkg
  mkdir -p pkg/DEBIAN pkg/usr/share/themes pkg/usr/share/doc/$PKG
  cp -a src/Themes/${name}* pkg/usr/share/themes/
  cp -a src/{LICENSE.md,README.md} pkg/usr/share/doc/$PKG/
  cat >pkg/DEBIAN/control <<EOF
Package: $PKG
Version: $VER
Architecture: all
Maintainer: none
Depends: gnome-themes-extra, gtk2-engines-pixbuf, gtk2-engines-murrine
Section: misc
Priority: optional
Homepage: https://www.gnome-look.org/p/1299514/
Description: $name GTK theme
EOF
  fakeroot dpkg-deb --build -Zxz -z9 -Sextreme pkg "${PKG}_${VER}_all.deb"

  PKG=${name,,}-theme-icon
  rm -rf pkg
  mkdir -p pkg/DEBIAN pkg/usr/share/icons pkg/usr/share/doc/$PKG
  cp -a src/Icons/${name}* pkg/usr/share/icons/
  cp -a src/{LICENSE.md,README.md} pkg/usr/share/doc/$PKG/
  cat >pkg/DEBIAN/control <<EOF
Package: $PKG
Version: $VER
Architecture: all
Maintainer: none
Section: misc
Priority: optional
Homepage: https://www.gnome-look.org/p/1299514/
Description: $name icon theme
EOF
  fakeroot dpkg-deb --build -Zxz -z9 -Sextreme pkg "${PKG}_${VER}_all.deb"
done
