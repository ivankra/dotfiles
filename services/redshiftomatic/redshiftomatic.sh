#!/bin/bash
# Automatically reapplies redshift settings on any display connectivity change.
set -eu

cmd() {
  redshift -O 3500K -b 1 -P
}

cmd_rep() {
  for attempt in $(seq $1); do
    cmd
    sleep 1
  done
}

WORKDIR=$(mktemp -d --tmpdir="${XDG_RUNTIME_DIR:-/tmp}" redshiftomaticXXXX)
cd "$WORKDIR"

echo "State file: $WORKDIR/event"
cmd_rep 30
touch event

tail --follow=name --retry /var/log/Xorg.0.log | \
  stdbuf -oL egrep ': (dis)?connected$' | \
  while IFS=$'\n' read line; do
    if [[ "$(date +%s)" != "$(date -r event +%s)" ]]; then
      cmd_rep 10
      touch event
    fi
  done
