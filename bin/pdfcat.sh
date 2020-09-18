#!/bin/bash
# Concatenates input pdf files, writing to stdout.

if [[ -t 1 || -z "$1" ]]; then
  echo "Usage: pdfcat.sh input1.pdf input2.pdf ... >output.pdf"
  exit 1
fi

set -e -x
pdftk "$@" cat output /dev/stdout
