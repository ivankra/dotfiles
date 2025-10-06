#!/bin/bash
# Suppress "Address family not supported by protocol" on ipv6-disabled hosts

for ping in {,/usr}/{bin,sbin}/ping; do
  if [[ -x "$ping" ]]; then
    break
  fi
done

if ! [[ -x "$ping" ]]; then
  echo "$0: can't find ping binary" >&2
  exit 1
fi

if [[ -f /sys/module/ipv6/parameters/disable &&
      "$(cat /sys/module/ipv6/parameters/disable)" == "1" ]]; then
  for ping4 in {,/usr}/{bin,sbin}/ping4; do
    if [[ -x "$ping4" ]]; then
      ping="$ping4"
      break
    fi
  done
fi

exec "$ping" "$@"
