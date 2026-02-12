#!/bin/bash
# ~/.config/mpv.conf generator
set -euo pipefail

cat <<EOF
cache-secs=300
cache=yes
demuxer-max-back-bytes=256MiB
demuxer-max-bytes=1024MiB
demuxer-readahead-secs=300
demuxer-thread=yes
volume-max=200
EOF
