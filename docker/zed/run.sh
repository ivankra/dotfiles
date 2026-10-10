#!/bin/bash
set -e -x -o pipefail


x11docker \
  -i \
  --backend=podman \
  --hostdisplay \
  --gpu=yes \
  --clipboard \
  --network=host \
  --ipc \
  -- \
  --hostname=x11docker \
  --tmpfs="$HOME" \
  --volume="dr-zed-config:$HOME/.config/zed" \
  --volume="dr-zed-data:$HOME/.local/share/zed" \
  --volume="$PWD:$PWD" \
  localhost/zed "$@"
