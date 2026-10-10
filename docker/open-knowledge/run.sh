#!/bin/bash
set -e -x -o pipefail

# Whole container $HOME persists here: app state (~/.config/OpenKnowledge), git config etc.
STATE="${XDG_DATA_HOME:-$HOME/.local/share}/dr/open-knowledge"
mkdir -p "$STATE"
# Stale symlink from the previous run; x11docker recreates it.
rm -f "$STATE"/.Xauthority

exec x11docker \
  -i \
  --backend=podman \
  --hostdisplay \
  --clipboard \
  --network=bridge \
  --ipc \
  --home="$STATE" \
  --workdir="$PWD" \
  -- \
  --hostname=x11docker \
  --volume="$PWD:$PWD" \
  localhost/open-knowledge "$@"
