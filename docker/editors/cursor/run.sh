#!/bin/bash -e
mkdir -p ~/.docker/cursor/.config/Cursor ~/.docker/cursor/.local/share/cursor ~/.docker/cursor/.local/share/cursor-agent ~/.docker/cursor/.cursor
exec podman run \
  -it --rm \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v /dev/dri:/dev/dri \
  --security-opt=label=type:container_runtime_t \
  -e DISPLAY \
  -e HOME \
  --tmpfs="$HOME" \
  --volume="$PWD:$PWD" \
  --volume="$HOME/.docker/cursor/.config/Cursor:$HOME/.config/Cursor" \
  --volume="$HOME/.docker/cursor/.local/share/cursor-agent:$HOME/.local/share/cursor-agent" \
  --volume="$HOME/.docker/cursor/.local/share/cursor:$HOME/.local/share/cursor" \
  --volume="$HOME/.docker/cursor/.cursor:$HOME/.cursor" \
  localhost/cursor --user-data-dir="$HOME/.config/Cursor" "$@"
