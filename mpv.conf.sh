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

echo scale=ewa_lanczossharp
echo cscale=ewa_lanczossharp
echo cache=131072
