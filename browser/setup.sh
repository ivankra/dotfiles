#!/bin/bash

set -e -o pipefail

cd "$(dirname -- "${BASH_SOURCE[0]}")"

if ! python3 -c 'import lz4' >/dev/null 2>&1; then
  (set -x; sudo apt-get install python3-lz4);
fi
if ! [[ -x /usr/bin/cpp ]]; then
  (set -x; sudo apt-get install cpp)
fi

if ! [[ -f /usr/share/chromium/extensions/no-skip-ink/no-skip-ink.css ]]; then
  if ! (set -x; sudo apt-get install chromium-no-skip-ink); then
    echo -e "\e[33mWWARNING:\e[0m skipped installation of chromium-no-skip-ink"
  fi
fi

set -x
./chromium.py
./firefox.py
