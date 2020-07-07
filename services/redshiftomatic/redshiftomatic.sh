#!/bin/bash
# Automatically reapplies redshift settings on any display connectivity change.
# Optionally, with --break flag, flashes screen red every 20min to remind to do 20/20/20 breaks.

set -e

reset_cmd() {
  redshift -O 3500K -b 1 -P
}

BREAK_INTERVAL_SEC=$((20 * 60 - 23))

break_cmd() {
  (
    set +e
    redshift -O 1000K -b 1 -P; sleep 2
    reset_cmd; sleep 20
    redshift -O 1000K -b 1 -P; sleep 1
    reset_cmd
  ) >/dev/null 2>&1
}

reset_rep() {
  if [[ "$(date +%s)" == "$(date -r reset-timestamp +%s)" ]]; then
    return 0
  fi

  for attempt in $(seq 20); do
    if [[ -f break-in-progress ]]; then
      sleep 1
      continue
    fi
    if reset_cmd; then
      touch reset-timestamp
    else
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
    sleep 1
  done
  touch reset-timestamp
}

reset_main() {
  reset_rep
  tail --follow=name --retry /var/log/Xorg.0.log | \
    stdbuf -oL egrep ': ((dis)?connected$|Setting mode)' | \
    while IFS=$'\n' read line; do
      reset_rep
    done
}

break_main() {
  while :; do
    if [[ "$(cinnamon-screensaver-command -q)" == *" active"* ]]; then
      touch break-timestamp
      sleep 30
      continue
    fi

    if ! [[ -f break-timestamp ]]; then
      touch break-timestamp
    fi

    diff=$(($(date +%s) - $(date -r break-timestamp +%s)))
    if (( diff >= 0 && diff < BREAK_INTERVAL_SEC )); then
      sleep 30
      continue
    fi

    touch break-in-progress
    echo "Break"
    break_cmd
    rm -f break-in-progress
    touch break-timestamp
  done
}


if [[ -z "$DISPLAY" ]]; then
  export DISPLAY=:0
fi

WORKDIR="${XDG_RUNTIME_DIR:-/tmp}"/redshiftomatic
mkdir -p "$WORKDIR"
cd "$WORKDIR"
echo "$$" >pid

if [[ "$1" == "--break" ]]; then
  break_main &
fi

reset_main
