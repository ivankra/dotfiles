#!/bin/bash
# ~/.config/mpv.conf generator
set -e -u -o pipefail

if egrep 'MemTotal: *[0-9]{8} kB' /proc/meminfo >/dev/null 2>&1; then
  csec=1800
  csize=1024MiB
else
  csec=200
  csize=256MiB
fi

cat <<EOF
demuxer-thread=yes
demuxer-readahead-secs=$csec
volume-max=200
EOF

if [[ -x /usr/bin/mpv ]]; then
  # Run in parallel as each call takes nontrivial time.
  tmp=$(mktemp -d)
  /usr/bin/mpv --version >"$tmp/version" 2>&1 &
  #/usr/bin/mpv --profile=help >"$tmp/profile-help" 2>&1 &
  /usr/bin/mpv --vo=help >"$tmp/vo-help" 2>&1 &
  /usr/bin/mpv --hwdec=help >"$tmp/hwdec-help" 2>&1 &
  wait

  VERSION=$(sed -Ene 's/^mpv ([0-9.]+) .*/\1/p' "$tmp/version")
  if [[ "$VERSION" == "" ]]; then
    rm -rf "$tmp"
    exit
  elif [[ "$VERSION" == 0.[0-2]* ]]; then
    echo "cache=262144"  # KiB
  else
    echo "cache=yes"
    echo "demuxer-max-bytes=$csize"
    echo "cache-secs=$csec"
  fi

  if ls -A /dev/nvidia* >/dev/null 2>&1; then
    if [[ -f /usr/lib/x86_64-linux-gnu/nvidia/current/libvdpau_nvidia.so.1 ]]; then
      if grep -qw '^  vdpau ' "$tmp/hwdec-help"; then
        echo hwdec=vdpau
      fi
    fi

    if grep -qw '^  gpu ' "$tmp/vo-help"; then
      echo vo=gpu
    fi
  fi

  rm -rf "$tmp"
fi
