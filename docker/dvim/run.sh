#!/bin/bash -e
SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
IMAGE=$(basename "$SCRIPT_DIR")
NAME=$(basename "$0")

if [[ "$NAME" != dvim* ]]; then
  echo "Expected basename \$0 ($0) != dvim*" >&2
  exit 1
fi

# The host dotfiles at <home>/.dotfiles as an overlay (:O): live, writes dropped on exit
dotfiles() { echo "$(realpath ~/.dotfiles):$1/.dotfiles:O"; }

# The claude image, via dr as the claude launcher: its /root volume (Claude's
# login, settings, history) and .git read-only. Not setup.sh, which would
# change that volume for claude too: only nvim's config linked, and bashrc for
# PATH, EDITOR, ... TERM/COLORTERM for nvim's colors, as the image sets none.
if [[ "$NAME" == dvim-claudecode ]]; then
  exec "$SCRIPT_DIR/../dr" \
    --hostname "$NAME" \
    -v dr-claude:/root \
    -v "$(dotfiles /root)" \
    -e TERM=xterm-256color -e COLORTERM=truecolor \
    localhost/claude \
    /bin/bash -c 'mkdir -p ~/.config && ln -sfn ~/.dotfiles/nvim ~/.config/nvim; . ~/.dotfiles/bashrc; exec nvim "$@"' nvim "$@"
fi

VOL="dr-$NAME"

CMD=(
  podman run -it --rm
  --hostname "$NAME"
  -e HOME
  -v "$VOL:$HOME"
)

# First run: setup.sh links the dotfiles into the volume's $HOME, as on the host
if ! podman volume exists "$VOL"; then
  echo "Setting up volume $VOL"
  podman volume create "$VOL" >/dev/null
  "${CMD[@]}" -v "$(dotfiles "$HOME")" "localhost/$IMAGE" "$HOME/.dotfiles/setup.sh" ||
    { podman volume rm "$VOL" >/dev/null; exit 1; }
fi

# Run in ~/.dotfiles itself: the $PWD mount below is it, writable
if [[ "$PWD" != "$HOME/.dotfiles" ]]; then
  CMD+=(-v "$(dotfiles "$HOME")")
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
