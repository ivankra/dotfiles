#!/bin/bash
# Usage: ./build.sh [version]

set -e -u -o pipefail
umask 002

get_latest_ver() {
  local ver=$(
    wget -q -O - "https://product-details.mozilla.org/1.0/firefox_versions.json" |
    sed -ne "s/.*\"$1\": \"\(.*\)\".*/\1/p"
  )
  (echo "$1 = $ver"; echo) >&2
  echo "$ver"
}

# Find latest release version
VERSION=""
case "${1:-release}" in
  release)
    VERSION=$(get_latest_ver LATEST_FIREFOX_VERSION);;
  beta|dev|devel)
    VERSION=$(get_latest_ver LATEST_FIREFOX_RELEASED_DEVEL_VERSION);;
  nightly)
    VERSION=$(get_latest_ver FIREFOX_NIGHTLY);;
  esr)
    VERSION=$(get_latest_ver FIREFOX_ESR);;
  *)
    VERSION="$1"
esac

# Maybe download signing key
rm -f firefox.asc
wget -O firefox.asc "https://archive.mozilla.org/pub/firefox/releases/$VERSION/KEY"

do_build() {
  ARCH="$1"

  TMPDIR="$(mktemp -d)"
  trap 'set +eu; rm -rf "$TMPDIR"; exit 1;' ERR

  gpg -q --no-default-keyring --keyring "$TMPDIR/firefox.gpg" --import firefox.asc

  # Download release tarball
  if [[ "$ARCH" == "amd64" ]]; then
    URL="https://download.cdn.mozilla.net/pub/firefox/releases/$VERSION/linux-x86_64/en-US/firefox-$VERSION.tar.xz"
  else
    URL="https://download.cdn.mozilla.net/pub/firefox/releases/$VERSION/linux-aarch64/en-US/firefox-$VERSION.tar.xz"
  fi
  TARBALL=$(basename "$URL")
  wget -O "$TMPDIR/$TARBALL" "$URL"
  wget -O "$TMPDIR/$TARBALL.asc" "$URL.asc"
  gpg --no-default-keyring --keyring "$TMPDIR/firefox.gpg" --verify "$TMPDIR/$TARBALL.asc" "$TMPDIR/$TARBALL"

  # Prepare package
  PKGDIR="$TMPDIR/pkg"
  mkdir -p "$PKGDIR/usr/local/lib"
  (set -x; cd "$PKGDIR/usr/local/lib" && tar xf "$TMPDIR/$TARBALL")

  if [[ "$(ls -A "$PKGDIR/usr/local/lib")" != "firefox" ]]; then
    echo "Unexpected content in $TMPDIR/$TARBALL"
    exit 1
  fi

  mv "$PKGDIR/usr/local/lib/firefox" "$PKGDIR/usr/local/lib/firefox-bwrap"
  install -D -m 0644 ../../browser/gen/policies.json "$PKGDIR/usr/local/lib/firefox-bwrap/distribution/policies.json"
  install -D -m 0755 firefox-bwrap.sh "$PKGDIR/usr/local/lib/firefox-bwrap/firefox-bwrap.sh"
  mkdir -p "$PKGDIR/usr/local/bin"
  ln -sf "../lib/firefox-bwrap/firefox-bwrap.sh" "$PKGDIR/usr/local/bin/firefox-bwrap"
  ln -sf "../lib/firefox-bwrap/firefox-bwrap.sh" "$PKGDIR/usr/local/bin/firefox"

  # Copy icons from an existing firefox installation
  ICON="firefox-esr"
  for path in /usr/share/icons/hicolor/128x128/apps/firefox.png \
              /usr/share/icons/hicolor/16x16/apps/firefox.png \
              /usr/share/icons/hicolor/32x32/apps/firefox.png \
              /usr/share/icons/hicolor/48x48/apps/firefox.png \
              /usr/share/icons/hicolor/64x64/apps/firefox.png \
              /usr/share/icons/hicolor/symbolic/apps/firefox-symbolic.svg; do
    for product in firefox firefox-esr firefox-bwrap; do
      spath=$(echo "$path" | sed -e "s/firefox/$product/")
      dpath=$(echo "$path" | sed -e "s/firefox/firefox-bwrap/")
      echo $spath $dpath
      if [[ -f "$spath" ]]; then
        install -D -m 0644 <(cat "$spath") "$PKGDIR$dpath"
        ICON=firefox-bwrap
        break
      fi
    done
  done

  install -D -m 0644 /dev/stdin "$PKGDIR/usr/share/applications/firefox-bwrap.desktop" <<EOF
[Desktop Entry]
Name=Firefox (bwrap)
Comment=Browse the World Wide Web
GenericName=Web Browser
X-GNOME-FullName=Firefox (bwrap)
Exec=/usr/local/bin/firefox-bwrap %u
Terminal=false
X-MultipleArgs=false
Type=Application
Icon=$ICON
Categories=Network;WebBrowser;
MimeType=text/html;text/xml;application/xhtml+xml;application/xml;application/vnd.mozilla.xul+xml;application/rss+xml;application/rdf+xml;image/gif;image/jpeg;image/png;x-scheme-handler/http;x-scheme-handler/https;
StartupWMClass=Firefox
StartupNotify=true
EOF

  install -D /dev/stdin "$PKGDIR/DEBIAN/control" <<EOF
Package: firefox-bwrap
Version: ${VERSION}
Section: dotfiles
Priority: optional
Maintainer: none
Architecture: ${ARCH}
Depends: bash, bubblewrap
Description: Firefox bubblewrapped
EOF

  fakeroot dpkg-deb --build "$PKGDIR" "firefox-bwrap_${VERSION}_${ARCH}.deb"

  rm -rf "$TMPDIR"
}

do_build amd64
do_build arm64
