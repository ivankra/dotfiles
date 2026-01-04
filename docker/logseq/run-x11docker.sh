#!/bin/bash
set -e -x -o pipefail

SCRIPT_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
cd "$SCRIPT_DIR"

podman build -f Dockerfile -t logseq

mkdir -p ~/.config/logseq/empty ~/.config/fcitx5

# Prevent spurious 'window is not responding' errors
dconf write /org/cinnamon/muffin/check-alive-timeout 'uint32 0'
dconf write /org/gnome/muffin/check-alive-timeout 'uint32 0'

exec x11docker \
  -i \
  --backend=podman \
  --network=none \
  --hostdbus \
  --hostdisplay \
  --clipboard \
  --ipc \
  -- \
  --hostname=x11docker \
  --volume="$HOME/.config/fcitx5:$HOME/.config/fcitx5:ro" \
  --volume="$HOME/.config/logseq:$HOME/.logseq" \
  --volume="$HOME/.config/logseq/Logseq:$HOME/.config/Logseq" \
  --volume="$HOME/notes:$HOME/notes" \
  localhost/logseq "$@"

# --shm-size=1g \          conflicts with --ipc needed for keyboard layout switching
# --cap-add=sys_chroot \   or --no-sandbox flag for chromium
#
# If hangs at startup with the rest of podman: --userns=keep-id to blame
# https://docs.nvidia.com/ai-workbench/user-guide/latest/troubleshooting/troubleshooting.html#podman-container-slow-on-first-start
# Put containers on XFS, it works faster.
