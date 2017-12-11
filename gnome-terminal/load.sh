#!/bin/bash
# Runs gen-dconf.sh, loads generated config, backs up previous config.
# Usage: ./load.sh [filenames]

set -e -o pipefail

SCRIPT_DIR="$(dirname $(readlink -f "$0"))"

BACKUP="/tmp/dconf-org-gnome-terminal-backup-$(date +%s)"
dconf dump /org/gnome/terminal/ >$BACKUP
echo "Config backed up. To revert: dconf load / <$BACKUP"

TMP="/tmp/dconf-org-gnome-terminal-new-$(date +%s)"
"$SCRIPT_DIR/gen-dconf.sh" "$@" >$TMP || (echo "gen-dconf.sh failed"; exit 1)
dconf reset -f /org/gnome/terminal/
cat "$TMP" | dconf load /
rm -f "$TMP"

echo "New gnome-terminal configuration loaded"
