#!/bin/bash
# Fetch the latest stable Cursor AppImage into download-dir/ (re-downloads when a newer one is out)
set -euo pipefail
DOWNLOAD_DIR=download-dir
FILE=$DOWNLOAD_DIR/cursor.AppImage
MARK=$DOWNLOAD_DIR/cursor.url
mkdir -p "$DOWNLOAD_DIR"
arch=$(dpkg --print-architecture 2>/dev/null || uname -m)
case $arch in
  amd64|x86_64) arch=x64;;
  arm64|aarch64) arch=arm64;;
esac
url=$(curl -fsSL "https://api2.cursor.sh/updates/api/download/stable/linux-$arch/cursor" |
  sed -n 's/.*"downloadUrl":"\([^"]*\)".*/\1/p') || true
if [[ -z "$url" ]]; then
  [[ -f "$FILE" ]] || { echo "Could not find latest Cursor for $arch" >&2; exit 1; }
  echo "Could not check for updates, using existing $FILE" >&2
  exit 0
fi
if [[ -f "$FILE" && "$(cat "$MARK" 2>/dev/null)" == "$url" ]]; then
  echo "Using existing $FILE ($url)"
  exit 0
fi
tmp="$FILE.tmp.$$"
echo "Downloading $url"
curl -fL -o "$tmp" "$url"
mv "$tmp" "$FILE"
echo "$url" >"$MARK"
