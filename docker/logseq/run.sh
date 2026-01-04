#!/bin/bash -e
mkdir -p ~/.config/logseq/empty ~/.config/fcitx5
set -x
podman run \
  -it --rm \
  -v /tmp/.X11-unix:/tmp/.X11-unix \
  -v /dev/dri:/dev/dri \
  --security-opt=label=type:container_runtime_t \
  -e DISPLAY \
  -e HOME \
  --volume="$HOME/.config/fcitx5:$HOME/.config/fcitx5:ro" \
  --volume="$HOME/.config/logseq:$HOME/.logseq" \
  --volume="$HOME/.config/logseq/Logseq:$HOME/.config/Logseq" \
  --volume="$HOME/notes:$HOME/notes" \
  localhost/logseq "$@"
