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
  --volume="dr-cursor-config:$HOME/.config/Cursor" \
  --volume="dr-cursor-agent:$HOME/.local/share/cursor-agent" \
  --volume="dr-cursor-data:$HOME/.local/share/cursor" \
  --volume="dr-cursor-dot:$HOME/.cursor" \
  localhost/cursor --user-data-dir="$HOME/.config/Cursor" "$@"
