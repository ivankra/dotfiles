#!/bin/bash
set -e -x -o pipefail

mkdir -p ~/.docker/zed/.config/zed ~/.docker/zed/.local/share/zed

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
  --volume="$HOME/.docker/zed/.config/zed:$HOME/.config/zed" \
  --volume="$HOME/.docker/zed/.local/share/zed:$HOME/.local/share/zed" \
  --volume="$PWD:$PWD" \
  localhost/zed "$@"
