#!/bin/bash
# Brings ws-hpool back online after it has been offlined by ws-hpool-offline.sh

POOL="ws-hpool"

set -e -o pipefail

echo "Rescanning disks..."
for x in /sys/class/scsi_host/host*/scan; do
  echo "- - -" >$x
done

cryptdisks=$(cat /etc/crypttab | grep '\bnoauto\b' | egrep -o '^([^# ]+)')
if [[ -z "$cryptdisks" ]]; then
  echo "Error: did not find any 'noauto' devices in /etc/crypttab"
  exit 1
fi

for id in $cryptdisks; do
  (set -x; cryptdisks_start "$id")
done

(set -x; zpool import "$POOL")

# TODO: replace by udev rule in svc-hdd-spindown
if [[ -x /usr/local/sbin/svc-hdd-spindown.sh ]]; then
  /usr/local/sbin/svc-hdd-spindown.sh
fi
