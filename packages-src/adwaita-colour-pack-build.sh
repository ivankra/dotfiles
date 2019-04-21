#!/bin/bash
# .deb packaging for Adwaita Colour Pack https://www.opendesktop.org/p/1284913/

set -e -o pipefail

sha256sum -c <<EOF
532ff7b7e2b4528df16cf6e519d8e35ea1769de62ace63bc0db31579f1f0d81f  Adwaita-Green-Dark.zip
4bfad7c3c6de93bc304ae725fec34cb0c406d8a15902daccbb359395ef506cfb  Adwaita-Green.zip
7a4b51540f4374828f20b36ef07dae8eca2112557841f1038fa322a3aa401523  Adwaita-Orange-Dark.zip
edce9155339eb2f598ad5aedc9411f767047502e6f2d5331efab111f3543ab8f  Adwaita-Orange.zip
6facbc0f1c925d3f7507feace65058cfcb9a5f73739178fdb74ee2e0305f5fd2  Adwaita-Pink-Dark.zip
c774162c491d93efca9371c8336c6a5a613bdb7399cb60e05e1411de01733fcf  Adwaita-Pink.zip
59cc856abd0169302ad303b40fd27f3dbc84dc618cbf8aecb663459b8f9a5ece  Adwaita-Purple-Dark.zip
6cca7275f104fe841155d400c181db10656f9881036fb9b2d7baefe824cf4c2d  Adwaita-Purple.zip
4c02c558d43a18c39a5430cdf5b615eefc280e49a3874056ae9b60d99d715d10  Adwaita-Red-Dark.zip
0f128dfd6a9338bfda09420e3c4593a305cc06805b7768d5614decf1c73726ce  Adwaita-Red.zip
EOF

rm -rf pkg
mkdir -p pkg/DEBIAN

for f in Adwaita-*.zip; do
  dir="pkg/usr/share/themes/${f%.zip}"
  (mkdir -p "$dir" && cd "$dir" && unzip ../../../../../$f)
done

PKG=adwaita-colour-pack
VER=20190112

mkdir -p pkg/usr/share/doc/$PKG/
cp "${BASH_SOURCE[0]}" pkg/usr/share/doc/$PKG/

cat >pkg/DEBIAN/control <<EOF
Package: $PKG
Architecture: all
Maintainer: none
Depends: gtk2-engines-pixbuf
Priority: optional
Version: $VER
Section: x11
Description: Original Adwaita theme re-colourized into five fabulous variants
Homepage: https://www.opendesktop.org/p/1284913/
EOF

fakeroot dpkg-deb --build -Zxz -z9 -Sextreme pkg "${PKG}_${VER}_all.deb"
