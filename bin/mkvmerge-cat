#!/bin/bash
# Concatenates multiple input video files with mkvmerge

set -e -o pipefail

if [[ -z "$2" ]]; then
  echo "Usage: $0 -o output input1 ... inputN [-flags...]"
  exit 1
fi

OUTPUT=""
ARGS=()

while [[ $# > 0 ]]; do
  case "$1" in
    -o)
      OUTPUT="$2";
      shift 2;;
    -*)
      break;;
    *)
      if [[ "${#ARGS[@]}" != 0 ]]; then
        ARGS+=("+" "$1")
      else
        ARGS+=("$1")
      fi
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

(set -x; firejail --net=none mkvmerge -o "$OUTPUT" "$@" "${ARGS[@]}")
