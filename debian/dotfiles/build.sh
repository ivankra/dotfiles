#!/bin/bash
# Builds dotfiles package from the contents of current ~/.dotfiles repository.
#
# The package ships dotfiles repository and customized firefox policies file,
# manages installation and update of ~/.dotfiles for all local users.

set -e -u -o pipefail
umask 002

PKGDIR="$(mktemp -d)"
trap 'rm -rf "$PKGDIR"' EXIT

DOTFILES_DIR="$PKGDIR/usr/local/share/dotfiles"
mkdir -p "$DOTFILES_DIR"

export GIT_DIR="$DOTFILES_DIR/dotfiles.git"
echo "Packing dotfiles.git"
git clone -q --bare --depth=1 "file://$HOME/.dotfiles" "$GIT_DIR"
git remote remove origin
git tag -f dotfiles HEAD
git config --add core.compression 9
git gc -q --aggressive --prune=now
VERSION="$(date +%Y%m%d.%H%M).$(git show-ref --hash=8 dotfiles)"
rm -rf "$GIT_DIR/hooks"
unset GIT_DIR

# Pack submodules into the package as bare repos.
# Uses sm_path from .gitmodules (e.g. "modules/foo.nvim") to create
# bare repo at $DOTFILES_DIR/modules/foo.nvim.git
mapfile -t submodules < <(cd ~/.dotfiles && git submodule foreach --quiet 'echo "$sm_path"')
for sm_path in "${submodules[@]}"; do
  if [[ ! "$sm_path" =~ ^modules/[^/]+$ ]]; then
    echo "Error: submodule $sm_path must be at modules/<name>"
    exit 1
  fi
  sm_src="$HOME/.dotfiles/$sm_path"
  sm_dst="$DOTFILES_DIR/$sm_path.git"
  if ! [[ -d "$sm_src/.git" || -f "$sm_src/.git" ]]; then
    echo "Error: submodule $sm_path not initialized"
    exit 1
  fi
  mkdir -p "$(dirname "$sm_dst")"
  echo "Packing $sm_path"
  if ! git -c init.defaultBranch=master clone -q --bare --depth=1 "file://$sm_src" "$sm_dst"; then
    echo "Error: failed to clone submodule $sm_path"
    exit 1
  fi
  GIT_DIR="$sm_dst" git remote remove origin 2>/dev/null || true
  GIT_DIR="$sm_dst" git tag -f dotfiles HEAD
  GIT_DIR="$sm_dst" git config --add core.compression 9
  GIT_DIR="$sm_dst" git gc -q --aggressive --prune=now
  rm -rf "$sm_dst/hooks"
done

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
chmod -R a-w /usr/local/share/dotfiles
chmod u+w /usr/local/share/dotfiles
chmod u+w /usr/local/share/dotfiles/modules
EOF

install -D -m 0755 /dev/stdin "$PKGDIR/DEBIAN/prerm" <<EOF
#!/bin/bash
chmod -R u+w /usr/local/share/dotfiles
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
install -D -m 0644 ../../browser/gen/policies.json "$PKGDIR/usr/share/firefox/distribution/policies.json"
install -D -m 0644 ../../browser/gen/policies.json "$PKGDIR/usr/share/firefox-esr/distribution/policies.json"

fakeroot dpkg-deb --build "$PKGDIR" "dotfiles_${VERSION}_all.deb"
