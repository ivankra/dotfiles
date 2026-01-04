#!/bin/bash -e
mkdir -p ~/.docker/vscode/.config/Code ~/.docker/vscode/.vscode
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
  --volume="$HOME/.docker/vscode/.config/Code:$HOME/.config/Code" \
  --volume="$HOME/.docker/vscode/.vscode:$HOME/.vscode" \
  localhost/vscode --user-data-dir="$HOME/.config/Code" "$@"
