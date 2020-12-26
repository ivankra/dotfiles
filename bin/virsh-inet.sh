#!/bin/bash

set -e -o pipefail

name="$1"
if [[ -z "$name" ]]; then
  echo "Usage: $0 <network name>"
  exit 1
fi

if virsh net-info "$name" >/dev/null 2>&1; then
  xmlabr=$(virsh net-dumpxml "$name" | sed -Ee 's/<uuid>.*<.uuid>//; s/<(bridge|mac)[^>]*\/>//g' | tr -d '\n ')
  if [[ "$xmlabr" == "<network><name>$name</name><domainname='network'/></network>" ]]; then
    echo "Isolated network $name already defined"
    exit 0
  fi
  echo "Network $name already defined, delete [y/n]?"
  read ans
  if [[ "$ans" != 'y' ]]; then
    exit 1
  fi
  (set -x; virsh net-destroy "$name")
  (set -x; virsh net-undefine "$name")
fi

set -x

virsh net-define <(cat <<EOF
<network>
  <name>$name</name>
  <domain name='network'/>
</network>
EOF
)

virsh net-start "$name"
virsh net-autostart "$name"
