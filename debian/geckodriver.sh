#!/bin/bash
# Builds geckodriver package from github release.
set -e -u -o pipefail -x

VER="0.26.0"
URL="https://github.com/mozilla/geckodriver/releases/download/v$VER/geckodriver-v$VER-linux64.tar.gz"
SHA256="d59ca434d8e41ec1e30dd7707b0c95171dd6d16056fb6db9c978449ad8b93cc0"

TMP="$(mktemp -d)"
wget -O "$TMP/geckodriver.tgz" "$URL"
echo "$SHA256  $TMP/geckodriver.tgz" | sha256sum -c

(cd "$TMP" && tar xf geckodriver.tgz)

install -D -m 0755 "$TMP/geckodriver" "$TMP/pkg/usr/local/bin/geckodriver"
install -D -m 0755 /dev/stdin "$TMP/pkg/DEBIAN/control" <<EOF
Package: geckodriver
Version: $VER
Provides: firefox-geckodriver
Section: World Wide Web
Priority: optional
Maintainer: none
Architecture: amd64
Homepage: https://github.com/mozilla/geckodriver/releases
Description: geckodriver
EOF

fakeroot dpkg-deb --build "$TMP/pkg" "geckodriver_${VER}_amd64.deb"
rm -rf "$TMP"
