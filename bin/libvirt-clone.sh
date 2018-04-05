#!/bin/bash
# Clones zvol-based libvirt VMs, as virt-manager doesn't seem to be yet
# capable of this simple task.
#
# Usage:
#   sudo ./libvirt-clone.sh [basedir/]zvol[@snapshot] newzvol

set -e -o pipefail

if [[ $# != 2 || $UID != 0 ]]; then
  echo "Usage: sudo $0 [basedir/]zvol[@snapshot] newzvol"
  exit 1
fi

BASEDIR=spool/libvirt
OLD_ZVOL="$1"
NEW_ZVOL="$2"

if ! [[ "$OLD_ZVOL" == */* ]]; then
  OLD_ZVOL="${BASEDIR}/${OLD_ZVOL}"
else
  BASEDIR=$(echo "$OLD_ZVOL" | sed -e "s|/[^/]*$||")
  echo "Imputed base directory: $BASEDIR"
fi

if ! [[ "$NEW_ZVOL" == */* ]]; then
  NEW_ZVOL="${BASEDIR}/${NEW_ZVOL}"
fi

if [[ "$OLD_ZVOL" == *@* ]]; then
  OLD_SNAP="${OLD_ZVOL/*@/}"
  OLD_ZVOL="${OLD_ZVOL/@*/}"
fi

OLD_NAME=$(basename "$OLD_ZVOL")
NEW_NAME=$(basename "$NEW_ZVOL")
OLD_CONF="/etc/libvirt/qemu/$OLD_NAME.xml"
if ! [[ -f "$OLD_CONF" ]]; then
  echo "Config doesn't exist: $OLD_ZVOL"
  exit 1
fi
if ! grep -q "/dev/zvol/$OLD_ZVOL" <"$OLD_CONF"; then
  echo "Error: $OLD_CONF does not reference /dev/zvol/$OLD_ZVOL"
  exit 1
fi
if ! grep -q "<name>$OLD_NAME</name>" <"$OLD_CONF"; then
  echo "Error: $OLD_CONF is not named $OLD_NAME"
  exit 1
fi

NEW_CONF="/etc/libvirt/qemu/$NEW_NAME.xml"
if [[ -f "$NEW_CONF" ]]; then
  echo "Error: $NEW_CONF already exists"
  exit 1
fi

NEW_CONF="$(mktemp -d)/$NEW_NAME.xml"
cat "$OLD_CONF" | \
  sed -e "s|<name>$OLD_NAME</name>|<name>$NEW_NAME</name>|" | \
  sed -e "s|/dev/zvol/$OLD_ZVOL|/dev/zvol/$NEW_ZVOL|" | \
  sed -e "/<uuid>.*</uuid>/d" >"$NEW_CONF"

if ! [[ "$OLD_ZVOL" == *@* ]]; then
  echo "Found snapshots:"
  zfs list -H -t snapshot -o name -r "$OLD_ZVOL" | fgrep -e "$OLD_ZVOL@"
  OLD_SNAP="$(zfs list -H -t snapshot -o name -r "$OLD_ZVOL" | fgrep -e "$OLD_ZVOL@" | sed -e "s/^.*@//" | head -1)"
  if [[ "$OLD_SNAP" == "" ]]; then
    echo "No existing snapshots of $OLD_ZVOL found"
    exit 1
  fi
  echo
  echo -n "Clone snapshot $OLD_ZVOL@$OLD_SNAP [y/n]? "
  read ans
  if [[ "$ans" != "y" && "$ans" != "Y" ]]; then
    exit 1
  fi
fi

echo "Cloning $OLD_ZVOL@$OLD_SNAP as $NEW_ZVOL"
zfs clone "$OLD_ZVOL@$OLD_SNAP" "$NEW_ZVOL"

echo "Importing modified config $NEW_CONF"
virsh define "$NEW_CONF"

echo Success
