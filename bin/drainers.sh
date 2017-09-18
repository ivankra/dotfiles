#!/bin/bash
# Lists processes+threads responsible for most consumed user+kernel cpu time.

cd /proc
for pid in [0-9]*; do
  if [[ -f /proc/$pid/stat ]]; then
    pstat=($(cat /proc/$pid/stat))
    pname=${pstat[1]}
    if [[ -d /proc/$pid/task ]]; then
      cd /proc/$pid/task
      for tid in [0-9]*; do
        if [[ -f /proc/$pid/task/$tid/stat ]]; then
          tstat=($(cat /proc/$pid/task/$tid/stat 2>/dev/null))
          tname=${tstat[1]}
          utime=${tstat[13]}
          ctime=${tstat[14]}
          ttime=$(($utime + $ctime))
          echo "$ttime /proc/$pid/task/$tid $pname $tname $utime $ctime"
        fi
      done
    fi
  fi
done
