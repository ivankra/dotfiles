#!/bin/bash
# Builds dotfiles package from the contents of current ~/.dotfiles repository.
#
# The package ships dotfiles repository and customized firefox policies file,
# manages installation and update of ~/.dotfiles for all local users.

set -e -u -o pipefail
umask 002

PKGDIR="$(mktemp -d)"

mkdir -p "$PKGDIR/usr/local/share/dotfiles"
export GIT_DIR="$PKGDIR/usr/local/share/dotfiles/dotfiles.git"
git clone --bare ~/.dotfiles "$GIT_DIR"
git remote remove origin
git config --add core.compression 9
git gc --aggressive --prune=now
rm -rf "$GIT_DIR/hooks"

VERSION="$(date +%Y%m%d.%H%M).$(git show-ref --hash=8 master)"

install -D /dev/stdin "$PKGDIR/DEBIAN/control" <<EOF
Package: dotfiles
Version: ${VERSION}
Section: dotfiles
Priority: optional
Maintainer: none
Architecture: all
Depends: bash, git, sudo
Conflicts: firefox-policies-json
Description: Automatically managed ~/.dotfiles for all users
EOF

install -D -m 0755 /dev/stdin "$PKGDIR/DEBIAN/postinst" <<EOF
#!/bin/bash -e
[[ -f /usr/bin/systemctl ]] && systemctl enable dotfiles-update.service
/usr/local/share/dotfiles/update.sh
EOF

install -D -m 0755 /dev/stdin "$PKGDIR/DEBIAN/prerm" <<EOF
#!/bin/bash
[[ -f /usr/bin/systemctl ]] && systemctl disable dotfiles-update.service
EOF

install -D -m 0644 /dev/stdin "$PKGDIR/lib/systemd/system/dotfiles-update.service" <<EOF
[Unit]
Description=Update ~/.dotfiles directories for all users
After=local-fs.target getty.target zfs.target

[Service]
ExecStart=/usr/local/share/dotfiles/update.sh
Type=simple

[Install]
WantedBy=multi-user.target
EOF

install -D -m 0755 update.sh "$PKGDIR/usr/local/share/dotfiles/update.sh"
install -D -m 0755 ../../browser/gen/policies.json "$PKGDIR/usr/share/firefox/distribution/policies.json"
install -D -m 0755 ../../browser/gen/policies.json "$PKGDIR/usr/share/firefox-esr/distribution/policies.json"

fakeroot dpkg-deb --build "$PKGDIR" "dotfiles_${VERSION}_all.deb"

rm -rf "$PKGDIR"
