#!/bin/bash

if [[ -t 0 || -t 1 ]]; then
  echo "Usage: pdf-rasterize.sh [density] <input.pdf >output.pdf"
  exit 1
fi

set -e -o pipefail
TMP=$(mktemp -d)
cd "$TMP"
cat >input.pdf
(set -x; convert -density "${1:-300}" input.pdf output.pdf)
cat output.pdf
rm -rf "$TMP"
