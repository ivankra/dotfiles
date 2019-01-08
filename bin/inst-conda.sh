#!/bin/bash

if [[ -n "$1" ]]; then
  TARGET="$1"
elif [[ -d /opt/conda && ! -f /opt/conda/bin/conda ]]; then
  TARGET=/opt/conda
else
  TARGET=./conda
fi
TARGET=$(realpath -- "$TARGET")

echo "Target directory: $TARGET"
if [[ -f "$TARGET/bin/conda" ]]; then
  echo "Error: $TARGET/bin/conda already exists"
  exit 1
fi

INSTALLER="Miniconda3-4.5.12-Linux-x86_64.sh"
INSTALLER_HASH="e5e5b4cd2a918e0e96b395534222773f7241dc59d776db1b9f7fedfcb489157a"

for url in "http://s/packages/$INSTALLER" \
           "https://repo.anaconda.com/miniconda/$INSTALLER"; do
  echo "Downloading $url"
  rm -f "/tmp/$INSTALLER"
  curl -s -o "/tmp/$INSTALLER" "$url"
  if echo "$INSTALLER_HASH  /tmp/$INSTALLER" | sha256sum -c --quiet - >/dev/null 2>&1; then
    break
  fi
  rm -f "/tmp/$INSTALLER"
done

if ! [[ -f "/tmp/$INSTALLER" ]]; then
  echo "Failed to download $INSTALLER or bad hash"
  exit 1
fi

chmod a+rx "/tmp/$INSTALLER"

# -b  batch mode, accept license terms
# -f  no error if install prefix already exists
# -p  install prefix
# -u  update an existing installation
set -x -e
"/tmp/$INSTALLER" -f -b -u -p "${TARGET}"
