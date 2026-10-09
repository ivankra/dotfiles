#!/bin/bash
# Fetch the latest antigravity .deb into download-dir/ (https://antigravity.google/download/linux);
# re-downloads when a newer one is out
set -euo pipefail
DOWNLOAD_DIR=download-dir
FILE=$DOWNLOAD_DIR/antigravity.deb
MARK=$DOWNLOAD_DIR/antigravity.path
mkdir -p "$DOWNLOAD_DIR"
repo_url="https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev"
arch=$(dpkg --print-architecture 2>/dev/null || uname -m | sed -e 's/aarch64/arm64/' -e 's/x86_64/amd64/')
packages_url="$repo_url/dists/antigravity-debian/main/binary-$arch/Packages"
deb_path=$(curl -fsSL "$packages_url" |
  awk '/^Package: antigravity$/{p=1} p && /^Filename:/{print $2} p && /^$/{p=0}' |
  sort -V | tail -n 1) || true
if [[ -z "$deb_path" ]]; then
  [[ -f "$FILE" ]] || { echo "No antigravity package found for $arch" >&2; exit 1; }
  echo "Could not check for updates, using existing $FILE" >&2
  exit 0
fi
if [[ -f "$FILE" && "$(cat "$MARK" 2>/dev/null)" == "$deb_path" ]]; then
  echo "Using existing $FILE ($deb_path)"
  exit 0
fi
tmp="$FILE.tmp.$$"
echo "Downloading $repo_url/$deb_path"
curl -fL -o "$tmp" "$repo_url/$deb_path"
mv "$tmp" "$FILE"
echo "$deb_path" >"$MARK"
