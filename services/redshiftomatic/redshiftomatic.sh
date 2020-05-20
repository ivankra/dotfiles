#!/bin/bash
# Automatically reapplies redshift settings on any display connectivity change.
set -e

cmd() {
  if ! redshift -O 3500K -b 1 -P; then
    echo "redshift failed!"
    sleep 3

    local user=$(whoami)
    local n=0
    while ! (loginctl show-user "$user" 2>&1 | grep -q State=active); do
      ((++n))
      if [[ $n == 1 ]]; then
        echo "User logged out"
      fi
      sleep 3
    done
  fi
}

cmd_wrap() {
  for attempt in $(seq 20); do
    cmd
    sleep 1
  done
  touch event
}

main() {
  if [[ -z "$DISPLAY" ]]; then
    export DISPLAY=:0
  fi

  WORKDIR="${XDG_RUNTIME_DIR:-/tmp}"/redshiftomatic
  mkdir -p "$WORKDIR"
  cd "$WORKDIR"
  echo "$$" >pid
  cmd_wrap

  tail --follow=name --retry /var/log/Xorg.0.log | \
    stdbuf -oL egrep ': ((dis)?connected$|Setting mode)' | \
    while IFS=$'\n' read line; do
      if [[ "$(date +%s)" != "$(date -r event +%s)" ]]; then
        cmd_wrap
      fi
    done
}

main
