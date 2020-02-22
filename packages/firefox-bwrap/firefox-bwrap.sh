#!/bin/bash
set -e -o pipefail

SCRIPT=$(realpath -P -- "${BASH_SOURCE[0]}")
BINARY="$(dirname -- "$SCRIPT")/firefox"
if ! [[ -x "$BINARY" ]]; then
  BINARY=/usr/lib/firefox/firefox
fi
if ! [[ -x "$BINARY" ]]; then
  BINARY=/usr/lib/firefox-esr/firefox-esr
fi

FLAGS=(
  --unshare-all
  --share-net
  --cap-drop ALL
  --new-session
  --die-with-parent
  --hostname bwrap
  --dev /dev
  --proc /proc
  --bind /tmp /tmp
  --ro-bind /usr/lib /usr/lib
  --ro-bind /usr/local /usr/local
  --ro-bind /usr/share /usr/share
  --ro-bind /lib /lib
  --ro-bind /lib64 /lib64
  --bind /run/user/$UID/pulse /run/user/$UID/pulse
  --bind ~/.cache/mozilla ~/.cache/mozilla
  --bind ~/.mozilla ~/.mozilla
  --ro-bind /etc /etc
  --ro-bind ~/.config ~/.config
  --unsetenv DBUS_SESSION_BUS_ADDRESS
  --unsetenv SESSION_MANAGER
  --setenv DISPLAY "$DISPLAY"
)

mkdir -m 0700 -p ~/.cache/mozilla ~/.mozilla

if [[ -f ~/.Xauthority ]]; then
  FLAGS+=(--ro-bind ~/.Xauthority ~/.Xauthority)
fi
if [[ -c /dev/nvidiactl ]]; then
  for f in /dev/dri /dev/nvidia-modeset /dev/nvidia[0-9] /dev/nvidiactl; do
    if [[ -e "$f" ]]; then
      FLAGS+=(--dev-bind "$f" "$f")
    fi
  done
fi

add_argdirs() {
  local flag="--bind"
  if [[ "$1" == "--ro-bind" ]]; then
    flag="--ro-bind"
    shift 1
  fi

  need_chdir=0

  for arg in "$@"; do
    if [[ "$arg" == --* ]]; then
      continue
    fi
    if ! realpath -s -- "$arg" >/dev/null 2>&1; then
      continue
    fi
    local dir="$(realpath -s -- "$arg")"
    if [[ -f "$dir" ]]; then
      dir="$(dirname -- "$dir")"
    fi
    if ! [[ "$arg" == /* ]]; then
      need_chdir=1
    fi
    if [[ -d "$dir" ]]; then
      FLAGS+=("$flag" "$dir" "$dir")
    fi
  done

  if ((need_chdir)); then
    FLAGS+=(--chdir "$(realpath -s -- ".")")
  fi
}
add_argdirs "$(realpath ~/Downloads)" ~/Downloads /share
add_argdirs --ro-bind "$@"

export GTK_CSD=1  # fix titlebar hiding in cinnamon

exec /usr/bin/bwrap "${FLAGS[@]}" "$BINARY" "$@"
