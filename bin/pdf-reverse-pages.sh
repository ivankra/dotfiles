#!/bin/bash

if [[ -t 0 || -t 1 ]]; then
  echo "Usage: pdf-reverse-pages.sh <input.pdf >output.pdf"
  exit 1
fi

set -e -x -o pipefail

TMP=$(mktemp -d)
cd "$TMP"

cat >input.pdf
pdftk input.pdf burst
pdftk $(ls pg_????.pdf | tac) cat output output.pdf
cat output.pdf

rm -rf "$TMP"
