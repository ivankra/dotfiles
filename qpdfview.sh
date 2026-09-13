# Generates ~/.config/qpdfview/qpdfview.conf
set -e -u -o pipefail

gen() {
  cat <<EOF
[documentView]
continuousMode=true
parallelSearchExecution=false
prefetch=true
prefetchDistance=10
scaleMode=1

[mainWindow]
exitAfterLastTab=true

[pageItem]
cacheSize=1048576K
useDevicePixelRatio=true
useLogicalDpi=true
EOF
}

conf=~/.config/qpdfview/qpdfview.conf

if [[ -f "$conf"  ]] && ! cmp --quiet "$conf" <(gen); then
  if [[ -x /usr/bin/crudini ]]; then
    gen | crudini --output - --merge "$conf"
  else
    echo "Warning: crudini should be installed to merge qpdfview.conf changes" >&2
    cat "$conf"
  fi
else
  gen
fi
