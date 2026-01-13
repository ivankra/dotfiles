#!/bin/bash -e
# Usage: run.sh <image> [<args>]

#SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
#IMAGE=$(basename "$SCRIPT_DIR")
IMAGE="$1"

mkdir -p "$HOME/.docker/$IMAGE"

CMD=(
  podman run -it --rm
  --name "$IMAGE-$(openssl rand -hex 4)"
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
