#!/bin/bash
# Unmounts ws-hpool and offlines its disk drives. Assumptions:
#   * pool consists of all rotational disks in the system AND
#   * all the disks are registered in /etc/crypttab with noauto

POOL="ws-hpool"

set -e -o pipefail

sync

cryptdisks=$(cat /etc/crypttab | grep '\bnoauto\b' | egrep -o '^([^# ]+)')
if [[ -z "$cryptdisks" ]]; then
  echo "Error: did not find any 'noauto' devices in /etc/crypttab"
  exit 1
fi
if zpool status "$POOL" >/dev/null 2>&1; then
  zpool export "$POOL"
fi

sync

for id in $cryptdisks; do
  if [[ -L "/dev/mapper/$id" ]]; then
    (set -x; cryptdisks_stop "$id")
  fi
done

sync

for dev in /dev/sd*; do
  short=$(basename "$dev")
  if [[ "$(cat /sys/block/$short/queue/rotational 2>/dev/null || true)" != "1" ]]; then
    continue
  fi
  echo "Offlining $dev"
  echo 1 >/sys/block/$short/device/delete
done
