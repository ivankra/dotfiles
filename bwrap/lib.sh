#!/bin/bash

set -e -o pipefail

BWRAP_ETC="/run/user/$UID/bwrap-etc"

create_bwrap_etc() {
  if ! [[ -f "$BWRAP_ETC/passwd" ]]; then
    echo "Creating $BWRAP_ETC"
    rm -rf "$BWRAP_ETC"
    mkdir -p "$BWRAP_ETC"
    cp -a -f \
      /etc/resolv.conf \
      /etc/hosts \
      /etc/ld.so.* \
      /etc/fonts \
      /etc/nvidia \
      /etc/alternatives \
      /etc/timezone \
      /etc/alsa \
      /etc/pulse \
      /etc/mpv \
      "$BWRAP_ETC/"
    egrep "^[^:]+:x:$UID:.*" /etc/passwd >"$BWRAP_ETC/passwd"
    egrep "^[^:]+:x:$(id -g):.*" /etc/group >"$BWRAP_ETC/group"
  fi
}

add_etc() {
  create_bwrap_etc
  FLAGS+=(--ro-bind "$BWRAP_ETC" /etc)
}

add_nvidia() {
  for f in /dev/dri /dev/nvidia-modeset /dev/nvidia0 /dev/nvidiactl; do
    if [[ -e "$f" ]]; then
      FLAGS+=(--dev-bind "$f" "$f")
    fi
  done
}

add_argdirs() {
  local flag="--bind"
  if [[ "$1" == "--ro-bind" ]]; then
    flag="--ro-bind"
    shift 1
  fi

  for arg in "$@"; do
    local dir="$(realpath -s -- "$arg")"
    if [[ -f "$dir" ]]; then
      dir="$(dirname -- "$dir")"
    fi
    if [[ -d "$dir" ]]; then
      FLAGS+=("$flag" "$dir" "$dir")
    fi
  done
}

add_argdirs_ro() {
  add_argdirs --ro-bind "$@"
}


MIN_FLAGS=(
  --unshare-all
  --cap-drop ALL
  --new-session
  --die-with-parent
  --hostname bwrap
  --dev /dev
  --proc /proc
  --tmpfs /tmp
  --ro-bind /usr/lib /usr/lib
  --ro-bind /usr/share /usr/share
  --ro-bind /lib /lib
  --ro-bind /lib64 /lib64
)

MIN_X11_FLAGS=(
  ${MIN_FLAGS[@]}
  --ro-bind /tmp/.X11-unix/X0 /tmp/.X11-unix/X0
  --ro-bind ~/.Xauthority ~/.Xauthority
  --setenv DISPLAY :0
)
