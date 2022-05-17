#!/bin/bash

find "$@" -type f -name '*.png' -print0 | \
  while IFS= read -r -d '' png; do
    echo "$png"
    jpg=${png%.png}.jpg
    convert -quality 70 "$png" "$jpg"
    if [[ $? == 0 && -f "$jpg" ]]; then
      rm -f "$png"
    fi
  done
