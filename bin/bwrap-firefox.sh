#!/bin/bash
# Minimal bubblewrap config to run firefox with GPU acceleration

FLAGS=(
  --unshare-all
  --share-net
  --dev /dev
  --proc /proc
  --tmpfs /tmp
  --ro-bind /usr /usr
  --ro-bind /bin /bin
  --ro-bind /sbin /sbin
  --ro-bind /lib /lib
  --ro-bind /lib64 /lib64
  --ro-bind /etc /etc
  --tmpfs ~/
  --tmpfs /run/user/$UID
  --ro-bind ~/.config/pulse ~/.config/pulse
  --bind /run/user/$UID/pulse /run/user/$UID/pulse
  --bind /tmp/.X11-unix/X0 /tmp/.X11-unix/X0
  --setenv DISPLAY :0
)

for f in /dev/dri /dev/nvidia-modeset /dev/nvidia0 /dev/nvidiactl; do
  if [[ -e "$f" ]]; then
    FLAGS+=(--dev-bind "$f" "$f")
  fi
done

for d in ~/.mozilla ~/.cache/mozilla ~/Downloads /share; do
  if [[ -d "$d" ]]; then
    FLAGS+=(--bind "$d" "$d")
  fi
done

bwrap "${FLAGS[@]}" /usr/bin/firefox "$@"
