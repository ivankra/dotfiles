#!/bin/bash -e
mkdir -p ~/.docker/astronvim

CMD=(
  podman run -it --rm
  -e HOME
  -e XDG_CONFIG_HOME=/root/.config
  -e XDG_DATA_HOME=/root/.local/share
  -e XDG_CACHE_HOME=/root/.cache
  -e XDG_STATE_HOME=/root/.local/state
  -v "$PWD:$PWD"
  -v "$HOME/.docker/astronvim:/root"
  -w "$PWD"
)

# Add .git bind-mount if it exists
if [ -d "$PWD/.git" ]; then
  CMD+=(-v "$PWD/.git:$PWD/.git:ro")
fi

exec "${CMD[@]}" localhost/astronvim "$@"
