#!/bin/bash -e
exec x11docker \
  -i \
  --backend=podman \
  --hostdisplay \
  --clipboard \
  --network=host \
  --ipc \
  -- \
  --hostname=x11docker \
  --tmpfs="$HOME" \
  --volume="$PWD:$PWD" \
  --volume="dr-vscode-config:$HOME/.config/Code" \
  --volume="dr-vscode-dot:$HOME/.vscode" \
  localhost/vscode --user-data-dir="$HOME/.config/Code" "$@"
