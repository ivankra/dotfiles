#!/bin/bash
# Rescans the system for new SATA/SCSI disks.
for x in /sys/class/scsi_host/host*/scan; do
  echo "- - -" >$x
done
