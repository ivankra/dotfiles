#!/bin/bash
# Installs cinnamon applets and their configs from here into the system.
set -e -o pipefail

cd "$(dirname "$(readlink -f "$0")")"

# Tells a running cinnamon to reload an applet, which caches its settings in
# memory. Fails harmlessly when cinnamon isn't running or is too old to have
# ReloadXlet.
reload_applet() {
  if command -v dbus-send >/dev/null 2>&1; then
    dbus-send --session --dest=org.Cinnamon --type=method_call \
      /org/Cinnamon org.Cinnamon.ReloadXlet "string:$1" string:APPLET \
      >/dev/null 2>&1 || true
  fi
}

# Applets
# Adding a new applet:
# * vendor into ../third_party/cinnamon-spices-applets/
# * symlink applets/<name> to ../../third_party/cinnamon-spices-applets/<name>/files/<name>
# * adjust org/cinnamon/enabled-applets and org/cinnamon/next-applet-id in ../dconf.json

APPLETS_DIR="$HOME/.local/share/cinnamon/applets"

for dir in applets/*; do
  name="${dir#applets/}"
  target_dir="$APPLETS_DIR/$name"
  if [[ -d "$dir" && ! "$dir" -ef "$target_dir" ]]; then
    rm -rf "$target_dir"
    mkdir -p "$APPLETS_DIR"
    ln -sfT "$(realpath -s --relative-to="$APPLETS_DIR" "$PWD/$dir")" "$target_dir"
    echo "$target_dir -> $PWD/$dir"
  fi
done

# Applet configs
# spices/<uuid>/<n>.json, where <n> must match the trailing numbers in
# org/cinnamon/enabled-applets (see ../dconf.json)
# Copy only what changed, as each applet whose config we touch gets reloaded.
# panel-launchers is generated from the detected apps by ../gui-setup.sh, so an
# existing config is left alone.

SPICES_DIR="$HOME/.config/cinnamon/spices"

for src in spices/*/*.json; do
  [[ -f "$src" ]] || continue
  rel="${src#spices/}"
  uuid="${rel%/*}"
  dst="$SPICES_DIR/$rel"
  if [[ "$uuid" == panel-launchers@cinnamon.org && -f "$dst" ]]; then
    continue
  fi
  if ! cmp -s "$src" "$dst"; then
    mkdir -p "$(dirname "$dst")"
    cp -f "$src" "$dst"
    echo "$src -> $dst"
    reload_applet "$uuid"
  fi
done
