#!/bin/bash -e
SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
IMAGE=$(basename "$SCRIPT_DIR")
NAME=$(basename "$0")

if [[ "$NAME" != dvim* ]]; then
  echo "Expected basename \$0 ($0) != dvim*" >&2
  exit 1
fi

VOL="dr-$NAME"

CMD=(
  podman run -it --rm
  --hostname "$NAME"
  -e HOME
  -v "$VOL:$HOME"
)

if ! podman volume exists "$VOL"; then
  echo "Setting up volume $VOL"
  podman volume create "$VOL" >/dev/null
  "${CMD[@]}" -v "$HOME/.dotfiles:/dotfiles-src:ro" "localhost/$IMAGE" /bin/bash -c \
    "cp -a /dotfiles-src $HOME/.dotfiles && $HOME/.dotfiles/setup.sh" ||
    { podman volume rm "$VOL" >/dev/null; exit 1; }
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
