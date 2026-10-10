#!/bin/bash -e
exec podman run \
  -it --rm \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v /dev/dri:/dev/dri \
  --security-opt=label=type:container_runtime_t \
  -e DISPLAY \
  -e HOME \
  --tmpfs="$HOME" \
  --volume="$PWD:$PWD" \
  --volume="dr-vscode-config:$HOME/.config/Code" \
  --volume="dr-vscode-dot:$HOME/.vscode" \
  localhost/vscode --user-data-dir="$HOME/.config/Code" "$@"
