#!/bin/bash -e
SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
IMAGE=$(basename "$SCRIPT_DIR")

mkdir -p "$HOME/.docker/$IMAGE"

CMD=(
  podman run -it --rm
  -w "$PWD"
  -v "$PWD:$PWD"
  -v "$HOME/.docker/$IMAGE:/root"
)

# Add read-only .git bind-mount if it exists
if [[ -d .git ]]; then
  CMD+=(-v "$PWD/.git:$PWD/.git:ro")
fi

set -x
exec "${CMD[@]}" "localhost/$IMAGE" "$@"

# Initial auth is broken, requires connection to localhost:1455, -p 1455:1455 broken too
# Workaround: podman exec -it to container, curl -v <url>, then curl -v <redirect url>
