#!/bin/bash
# ~/.config/mpv.conf generator
set -e -u -o pipefail

cat <<EOF
scale=ewa_lanczossharp
cscale=ewa_lanczossharp
demuxer-thread=yes
demuxer-readahead-secs=200
volume-max=200
EOF

if [[ -x /usr/bin/mpv ]]; then
  # Run in parallel as each call takes nontrivial time.
  tmp=$(mktemp -d)
  /usr/bin/mpv --version >"$tmp/version" 2>&1 &
  /usr/bin/mpv --profile=help >"$tmp/profile-help" 2>&1 &
  /usr/bin/mpv --vo=help >"$tmp/vo-help" 2>&1 &
  wait

  VERSION=$(sed -Ene 's/^mpv ([0-9.]+) .*/\1/p' "$tmp/version")
  if [[ "$VERSION" == "" ]]; then
    rm -rf "$tmp"
    exit
  elif [[ "$VERSION" == 0.[0-2]* ]]; then
    echo "cache=262144"  # KiB
  else
    echo "cache=yes"
    echo "demuxer-max-bytes=256MiB"
    echo "cache-secs=200"
  fi

  if [[ -f /usr/lib/x86_64-linux-gnu/nvidia/current/libvdpau_nvidia.so.1 ]]; then
    if grep -qw gpu-hq "$tmp/profile-help"; then
      echo profile=gpu-hq
    fi

    # For smooth 4K
    if grep -qw vdpau "$tmp/vo-help"; then
      echo vo=vdpau
    fi
  fi

  rm -rf "$tmp"
fi
