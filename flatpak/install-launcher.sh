#!/bin/bash
# Install a Flatpak desktop launcher and matching binary symlink.
# Ensures the first Name= entry includes a " (Flatpak)" suffix for clarity.
set -euo pipefail

if [[ "$#" -lt 1 ]]; then
  echo "Usage: $0 [uninstall] [--launcher=FILE] [--name=NAME] [--binary=NAME] <app-id>" >&2
  exit 1
fi

LAUNCHER_FILENAME=""
NAME_OVERRIDE=""
APP_BINARY_OVERRIDE=""
UNINSTALL=0
ARGS=()

for arg in "$@"; do
  case "$arg" in
    uninstall)
      UNINSTALL=1
      ;;
    --binary=*)
      APP_BINARY_OVERRIDE="${arg#--binary=}"
      ;;
    --launcher=*)
      LAUNCHER_FILENAME="${arg#--launcher=}"
      ;;
    --name=*)
      NAME_OVERRIDE="${arg#--name=}"
      ;;
    *)
      ARGS+=("$arg")
      ;;
  esac
done

if [[ "${#ARGS[@]}" -ne 1 ]]; then
  echo "Usage: $0 [uninstall] [--launcher=FILE] [--name=NAME] [--binary=NAME] <app-id>" >&2
  exit 1
fi

APP_ID="${ARGS[0]}"
if [[ -z "$LAUNCHER_FILENAME" ]]; then
  LAUNCHER_FILENAME="${APP_ID}.desktop"
fi
if [[ -n "$APP_BINARY_OVERRIDE" ]]; then
  APP_BINARY="$APP_BINARY_OVERRIDE"
else
  APP_BINARY="${APP_ID##*.}"
  APP_BINARY="${APP_BINARY,,}"
fi
SRC="${HOME}/.local/share/flatpak/exports/share/applications/${APP_ID}.desktop"
DEST_DIR="${HOME}/.local/share/applications"
DEST="${DEST_DIR}/${LAUNCHER_FILENAME}"
BIN_DIR="${HOME}/.local/bin"
BIN_SRC="${HOME}/.local/share/flatpak/exports/bin/${APP_ID}"
BIN_DEST="${BIN_DIR}/${APP_BINARY}"

if [[ "$UNINSTALL" -eq 1 ]]; then
  rm -f "$DEST" "$BIN_DEST"
  exit 0
fi

if [[ ! -f "$SRC" ]]; then
  echo "Desktop file not found: ${SRC}" >&2
  exit 1
fi

mkdir -p "$DEST_DIR"

TMP="${DEST}.tmp"

# Only touch the first Name= entry to avoid action sections.
awk '
  BEGIN { edited = 0 }
  !edited && /^Name=/ {
    if (name_override != "") {
      print "Name=" name_override
    } else {
      name = substr($0, 6)
      if (name ~ / \(Flatpak\)$/) {
        print $0
      } else {
        print "Name=" name " (Flatpak)"
      }
    }
    edited = 1
    next
  }
  { print }
' name_override="$NAME_OVERRIDE" "$SRC" > "$TMP"

chmod 0644 "$TMP"
mv -f "$TMP" "$DEST"
update-desktop-database "$DEST_DIR" || true
mkdir -p "$BIN_DIR"
ln -sf "$BIN_SRC" "$BIN_DEST"
