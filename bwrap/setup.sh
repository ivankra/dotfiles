#!/bin/bash
# Installs app launcher overrides for current user.
# Usage: bash ./install.sh [--uninstall]

set -e -o pipefail

APPS=(
  eog
  evince
  firefox
  geeqie
  mpv
  qpdfview
  vlc
)

install() {
  for app in "${APPS[@]}"; do
    launcher="$app.desktop"
    if [[ "$app" == "evince" ]]; then
      launcher="org.gnome.Evince.desktop"
    fi

    if ! [[ -f /usr/share/applications/$launcher ]]; then
      echo "Skipping $launcher"
      continue
    fi

    cat /usr/share/applications/$launcher \
      | egrep -v '^TryExec=' \
      | sed -Ee 's/((Name|Comment)=.*)/\1 (bwrap)/' \
      | sed -Ee "s|Exec=([^ ]+)|Exec=$(realpath .)/$app|" \
      >~/.local/share/applications/$launcher

    echo "Installed ~/.local/share/applications/$launcher"
  done
}

uninstall() {
  for app in "${APPS[@]}" org.gnome.Evince; do
    if grep -q 'Exec=.*bwrap' ~/.local/share/applications/$app; then
      rm -f ~/.local/share/applications/$app
    fi
  done
}

if [[ "$1" == "--uninstall" ]]; then
  uninstall
else
  install
fi
