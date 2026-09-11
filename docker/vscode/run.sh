#!/bin/bash -e
mkdir -p ~/.docker/vscode/.config/Code ~/.docker/vscode/.vscode
exec podman run \
  -it --rm \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v /dev/dri:/dev/dri \
  --security-opt=label=type:container_runtime_t \
  -e DISPLAY \
  -e HOME \
  --tmpfs="$HOME" \
  --volume="$PWD:$PWD" \
  --volume="$HOME/.docker/vscode/.config/Code:$HOME/.config/Code" \
  --volume="$HOME/.docker/vscode/.vscode:$HOME/.vscode" \
  localhost/vscode --user-data-dir="$HOME/.config/Code" "$@"
