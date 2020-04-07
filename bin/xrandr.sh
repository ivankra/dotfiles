#!/bin/bash
# Sets a custom xrandr display resolution.
# Mainly for use inside VMs with qxl/virtio graphics.

set -e -o pipefail

width="$1"
if [[ "$width" =~ ^([0-9]+)x([0-9]+)$ ]]; then
  # xrand.sh <width>x<height> [<refresh>]
  width="${BASH_REMATCH[1]}"
  height="${BASH_REMATCH[2]}"
  refresh_rate="$2"
elif [[ "$width" =~ 0?\.[0-9]+ ]]; then
  # xrandr.sh <ratio> [<refresh>]
  ratio="$1"
  refresh_rate="$2"

  curr=$(xrandr | sed -ne 's/^Screen .* current \([0-9]\+\) x \([0-9]\+\).*/\1 \2/p' | head -1)
  curw=$(echo "$curr" | cut -d " " -f 1)
  curh=$(echo "$curr" | cut -d " " -f 1)
  width=$(python -c "print(int($curw * $ratio))")
  height=$(python -c "print(int($curh * $ratio))")
else
  # xrandr.sh <width> <height> [<refresh>]
  height="$2"
  refresh_rate="$3"
fi

if [[ -z "$width" || -z "$height" ]]; then
  echo "Usage: $0 width height [refresh_rate]"
  exit 1
fi

if [[ -z "$refresh_rate" ]]; then
  refresh_rate=60
fi

display=$(xrandr | grep -oP '.+(?=\sconnected)' | head -1)
modename="${width}x${height}"

if ! (xrandr | grep -q "^ *$modename "); then
  params=$(gtf "$width" "$height" "$refresh_rate" | grep -oP '(?<=" ).+')
  (set -x; xrandr --newmode "$modename" $params)
  (set -x; xrandr --addmode "$display" "$modename")
fi

(set -x; xrandr --output "$display" --mode "$modename")
