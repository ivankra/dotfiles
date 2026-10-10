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
  --volume="dr-cursor-config:$HOME/.config/Cursor" \
  --volume="dr-cursor-agent:$HOME/.local/share/cursor-agent" \
  --volume="dr-cursor-data:$HOME/.local/share/cursor" \
  --volume="dr-cursor-dot:$HOME/.cursor" \
  localhost/cursor --user-data-dir="$HOME/.config/Cursor" "$@"
