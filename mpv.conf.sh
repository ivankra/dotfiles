#!/bin/bash

if [[ -x /usr/bin/mpv && -f /usr/lib/x86_64-linux-gnu/nvidia/current/libvdpau_nvidia.so.1 ]]; then
  if /usr/bin/mpv --profile=help | grep -qw gpu-hq; then
    echo profile=gpu-hq
  fi

  # For smooth 4K
  if /usr/bin/mpv --vo=help | grep -qw vdpau; then
    echo vo=vdpau
  fi
fi

cat <<EOF
scale=ewa_lanczossharp
cscale=ewa_lanczossharp
cache=262144
demuxer-thread=yes
demuxer-readahead-secs=200
volume-max=200
EOF
