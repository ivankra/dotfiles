#!/bin/bash
# Installs bubblewrapped launchers for the current user into ~/.local/share/applications/
# as well as symlinks into ~/.local/bin/ for the terminal.
#
# Usage: ./setup.sh [app ...]

set -e -o pipefail

# app[:launcher]
APPS=(
  7z:none
  7za:none
  7zr:none
  eog
  evince:org.gnome.Evince.desktop
  firefox
  geeqie
  libreoffice:libreoffice-calc.desktop
  libreoffice:libreoffice-draw.desktop
  libreoffice:libreoffice-impress.desktop
  libreoffice:libreoffice-math.desktop
  libreoffice:libreoffice-startcenter.desktop
  libreoffice:libreoffice-writer.desktop
  libreoffice:libreoffice-writer.desktop
  libreoffice:libreoffice-xsltfilter.desktop
  mpv
  okular:org.kde.okular.desktop
  p7zip:none
  qpdfview
  rar:none
  unzip:none
  vlc
)

install() {
  mkdir -p -m 0700 ~/.local/share/applications ~/.local/bin

  only_app="$1"

  for spec in "${APPS[@]}"; do
    if [[ "$spec" == *:* ]]; then
      launcher="${spec#*:}"
      app="${spec%:*}"
    else
      app="$spec"
      launcher="$spec.desktop"
    fi

    if [[ -n "$only_app" && "$app" != "$only_app" ]]; then
      continue
    fi

    if [[ "$launcher" == "none" ]]; then
      if ! [[ -x /usr/bin/"$app" ]]; then
        echo "$app: skipping (/usr/bin/$app missing)"
        continue
      fi
    else
      if ! [[ -f /usr/share/applications/$launcher ]]; then
        echo "$app: skipping (/usr/share/applications/$launcher missing)"
        continue
      fi

      cat /usr/share/applications/$launcher \
        | egrep -v '^(TryExec|[A-Za-z]*\[.*\])=' \
        | sed -Ee 's/^((Name|GenericName|Comment)=.*)/\1 (bwrap)/' \
        | sed -Ee "s|Exec=([^ ]+)|Exec=$(realpath .)/$app|" \
        >~/.local/share/applications/$launcher

      echo "$app: installed ~/.local/share/applications/$launcher"
    fi

    src="$(realpath .)/$app"
    dst=~/.local/bin/"$app"
    if ! [[ "$src" -ef "$dst" ]]; then
      rm -f "$dst"
      ln -s -f "$src" "$dst"
      echo "$app: linked ~/.local/bin/$app -> $src"
    fi
  done
}


if [[ $# == 0 ]]; then
  install
else
  for app in "$@"; do
    install "$app"
  done
fi
