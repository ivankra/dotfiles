#!/bin/bash
# Concatenates multiple input video files with ffmpeg

set -e -o pipefail

if [[ -z "$2" ]]; then
  echo "Usage: $0 -o output input1 ... inputN [-flags...]";
  exit 1
fi

OUTPUT=""
TMP=$(mktemp)

while [[ $# > 0 ]]; do
  case "$1" in
    -o)
      OUTPUT="$2";
      shift 2;;
    -*)
      break;;
    *)
      echo "file '$(realpath -- "$1")'" >>"$TMP"
      shift 1
  esac
done

if [[ -z "$OUTPUT" ]]; then
  echo "-o flag is required"
  exit 1
fi

if [[ -f "$OUTPUT" ]]; then
  echo "Error: output file '$OUTPUT' already exists"
  exit 1
fi

# https://trac.ffmpeg.org/wiki/Concatenate
(set -x; firejail --net=none ffmpeg -f concat -safe 0 -i "$TMP" -c copy "$@" "$OUTPUT")

rm -f "$TMP"
