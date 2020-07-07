#!/bin/bash
# Inserts an empty page after every page in the input .pdf
# Usage: pdftk-insert-empty.sh <input.pdf >output.pdf

set -e -x -o pipefail

TMP=$(mktemp -d)
cd "$TMP"

cat >input.pdf

pdftk input.pdf burst

convert xc:none -page A4 blank.pdf
for x in pg_????.pdf; do
  cp blank.pdf "${x/.pdf}z.pdf"
done

pdftk pg_*.pdf cat output output.pdf

cat output.pdf
