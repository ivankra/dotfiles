#!/bin/bash
# Wrapper for rtmpsuck to set up redirect, rename/chown output and restart on crashes.

if ! grep hypervisor /proc/cpuinfo >/dev/null 2>&1; then
  echo "Refusing to run not in a VM"
  exit 1
fi

if [[ "$UID" != "0" ]]; then
  echo "Script should be run under root, calling sudo"
  sudo bash -c "$0"
  exit $?
fi

if ! [[ -f /tmp/iptables-rtmpsuck ]]; then
  echo "Setting up iptables redirection"
  iptables -t nat -A OUTPUT -p tcp --dport 1935 -m owner \! --uid-owner root -j REDIRECT ||
    (echo iptables failed; exit 1)
  touch /tmp/iptables-rtmpsuck
fi

TARGET_USER=${SUDO_USER}
if [[ -z "$SUDO_USER" ]]; then
  if [[ "$(ls /home | wc -l)" == "1" ]]; then
    TARGET_USER=$(ls /home)
    echo "Assuming main user to be: ${TARGET_USER}"
  fi
fi

if ! [[ -z "${TARGET_USER}" ]]; then
  TARGET_GROUP=$(id -g -n "${TARGET_USER}")
fi

while :; do
  sleep 0.5

  for f in *-??-*; do
    if [[ "$f" != rtmp.* ]]; then
      if [[ $(stat -c '%s' "$f") -le 13 ]]; then
        rm -f "$f"
      else
        if ! [[ -z "$TARGET_USER" ]]; then
          chown "$TARGET_USER" "$f"
          chgrp "$TARGET_GROUP" "$f"
        fi
        mv -f "$f" "rtmp.$f.$(date +%s)"
      fi
    fi
  done

  date
  rtmpsuck
done
