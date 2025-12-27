#!/bin/bash -e
SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
IMAGE=$(basename "$SCRIPT_DIR")

mkdir -p "$HOME/.docker/$IMAGE"

CMD=(
  podman run -it --rm
  -e HOME
  -v "$HOME/.docker/$IMAGE:$HOME"
)

if [[ "$PWD" == "$HOME/.dotfiles" ]]; then
  CMD+=(-v "$HOME/.dotfiles:$HOME/.dotfiles")
else
  CMD+=(-v "$HOME/.dotfiles:$HOME/.dotfiles:ro")
  CMD+=(-v "$PWD:$PWD")
fi

# Add .git bind-mount if it exists
if [[ -d "$PWD/.git" ]]; then
  CMD+=(-v "$PWD/.git:$PWD/.git:ro")
fi

CMD+=(-w "$PWD")

exec "${CMD[@]}" "localhost/$IMAGE" nvim "$@"
