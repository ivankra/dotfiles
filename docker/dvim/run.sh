#!/bin/bash -e
SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
IMAGE=$(basename "$SCRIPT_DIR")
NAME=$(basename "$0")

if [[ "$NAME" != dvim* ]]; then
  echo "Expected basename \$0 ($0) != dvim*" >&2
  exit 1
fi

mkdir -p "$HOME/.docker/$NAME"

CMD=(
  podman run -it --rm
  --hostname "$NAME"
  -e HOME
  -v "$HOME/.docker/$NAME:$HOME"
)

if ! [[ -d "$HOME/.docker/$NAME/.config/nvim" ]]; then
  echo "Setting up $HOME/.docker/$NAME"
  cp -a ~/.dotfiles "$HOME/.docker/$NAME/.dotfiles"
  "${CMD[@]}" "localhost/$IMAGE" /bin/bash -c "$HOME/.dotfiles/setup.sh"
fi

if [[ "$NAME" == dvim-obsidian ]]; then
  CMD+=(-v "$PWD:/notes")
fi

CMD+=(-v "$PWD:$PWD")

# Add .git bind-mount if it exists
if [[ -d "$PWD/.git" ]]; then
  CMD+=(-v "$PWD/.git:$PWD/.git:ro")
fi

CMD+=(-w "$PWD")

exec "${CMD[@]}" "localhost/$IMAGE" nvim "$@"
