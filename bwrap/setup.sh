#!/bin/bash
# Installs app launcher overrides for the current user.

set -e -o pipefail

APPS=(
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
  qpdfview
  vlc
)

UTILS=(
  7z
  7za
  7zr
  p7zip
  rar
)

mkdir -p -m 0700 ~/.local/share/applications ~/.local/bin

for app in "${UTILS[@]}"; do
  if [[ -x /usr/bin/"$app" ]]; then
    src="$(realpath .)/$app"
    dst=~/.local/bin/"$app"
    if ! [[ "$src" -ef "$dst" ]]; then
      rm -f "$dst"
      ln -s -f "$src" "$dst"
      echo "Linked ~/.local/bin/$app -> $src"
    fi
  fi
done

for app in "${APPS[@]}"; do
  if [[ "$app" == *:* ]]; then
    launcher="${app#*:}"
    app="${app%:*}"
  else
    launcher="$app.desktop"
  fi

  if ! [[ -f /usr/share/applications/$launcher ]]; then
    echo "Skipping $app ($launcher)"
    continue
  fi

  cat /usr/share/applications/$launcher \
    | egrep -v '^(TryExec|[A-Za-z]*\[.*\])=' \
    | sed -Ee 's/^((Name|GenericName|Comment)=.*)/\1 (bwrap)/' \
    | sed -Ee "s|Exec=([^ ]+)|Exec=$(realpath .)/$app|" \
    >~/.local/share/applications/$launcher

  echo "Generated ~/.local/share/applications/$launcher"

  src="$(realpath .)/$app"
  dst=~/.local/bin/"$app"
  if ! [[ "$src" -ef "$dst" ]]; then
    rm -f "$dst"
    ln -s -f "$src" "$dst"
    echo "Linked ~/.local/bin/$app -> $src"
  fi
done
