#!/bin/bash

set -e -o pipefail

add_nvidia() {
  if glxinfo | grep '^OpenGL renderer string: Mesa'; then
    return 0
  fi

  if [[ -c /dev/nvidiactl ]]; then
    for f in /dev/dri /dev/nvidia-modeset /dev/nvidia[0-9] /dev/nvidiactl; do
      if [[ -e "$f" ]]; then
        FLAGS+=(--dev-bind "$f" "$f")
      fi
    done
  fi
}

add_gpu() {
  if glxinfo | grep '^OpenGL renderer string: Mesa'; then
    FLAGS+=(
      --bind-try /dev/dri /dev/dri
      --ro-bind-try /sys /sys
    )
  elif [[ -c /dev/nvidiactl ]]; then
    add_nvidia
  fi
}

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

add_argdirs_ro() {
  add_argdirs --ro-bind "$@"
}


MIN_FLAGS=(
  #--unshare-all
  --unshare-user-try
  #--unshare-ipc
  --unshare-pid
  --unshare-net
  --unshare-uts
  --unshare-cgroup-try
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
  --ro-bind /etc /etc
)
if [[ -d /lib64 ]]; then
  MIN_FLAGS+=(--ro-bind /lib64 /lib64)
fi

X11_FLAGS=(
  ${MIN_FLAGS[@]}
  --setenv DISPLAY "$DISPLAY"
)
if [[ "$DISPLAY" == ":0" ]]; then
  X11_FLAGS+=(--ro-bind /tmp/.X11-unix/X0 /tmp/.X11-unix/X0)
elif [[ "$DISPLAY" =~ ^localhost:[0-9.]+$ ]]; then
  X11_FLAGS+=(--share-net --hostname "$(hostname)")
fi
if [[ -f ~/.Xauthority ]]; then
  X11_FLAGS+=(--ro-bind ~/.Xauthority ~/.Xauthority)
fi
