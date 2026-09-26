#!/bin/bash
set -e -x -o pipefail

# Whole container $HOME persists here: app state (~/.config/OpenKnowledge), git config etc.
mkdir -p ~/.docker/open-knowledge
# Stale symlink from the previous run; x11docker recreates it.
rm -f ~/.docker/open-knowledge/.Xauthority

exec x11docker \
  -i \
  --backend=podman \
  --hostdisplay \
  --clipboard \
  --network=bridge \
  --ipc \
  --home="$HOME/.docker/open-knowledge" \
  --workdir="$PWD" \
  -- \
  --hostname=x11docker \
  --volume="$PWD:$PWD" \
  localhost/open-knowledge "$@"
