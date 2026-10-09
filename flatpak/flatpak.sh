#!/bin/bash
# Install vetted flatpak apps from Flathub or locally built.
# Adds "<name> (Flatpak)" menu launcher and a ~/.local/bin symlink.
# Run without args for usage.
# Permissions: overrides/global applies to every app; overrides/<app-id> is optional.
# overrides/ is linked to ~/.local/share/flatpak/overrides here (and by ../setup.sh).
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")"
HERE=$PWD
RUNTIME_VERSION=25.08
FLATHUB=https://flathub.org/repo/flathub.flatpakrepo

# Apps {{{
# Flathub apps: apps.tsv (alias, app-id, optional menu name).
# Built apps: every ./<alias>/<app-id>.yaml.
# Either way the alias is also the ~/.local/bin command.
# Build dirs may also have download.sh (fetch sources); runtimes come from the manifest.
APPS_FILE=$HERE/apps.tsv
[[ -f "$APPS_FILE" ]] || { echo "Error: missing $APPS_FILE" >&2; exit 1; }
# Rows need tab-separated alias and app-id (spaces instead of tabs are an easy mistake)
bad_rows=$(awk -F'\t' '!/^[[:space:]]*(#|$)/ &&
  (NF < 2 || $1 == "" || $2 == "" || $1 ~ /[[:space:]]/ || $2 ~ /[[:space:]]/) {
    print "  " FILENAME ":" FNR ": " $0
  }' "$APPS_FILE")
[[ -z "$bad_rows" ]] || {
  printf 'Error: bad rows (need <alias>TAB<app-id>[TAB<menu name>]):\n%s\n' "$bad_rows" >&2
  exit 1
}

# apps: print all apps as tab-separated rows: alias app-id source name
apps() {
  local m a
  grep -v -e '^[[:space:]]*#' -e '^[[:space:]]*$' "$APPS_FILE" |
    awk -F'\t' -v OFS='\t' '{print $1, $2, "flathub", $3}'
  for m in "$HERE"/*/*.*.yaml; do
    [[ -f "$m" ]] || continue
    a=$(basename "$(dirname "$m")")
    printf '%s\t%s\tbuild\n' "$a" "$(basename "$m" .yaml)"
  done
}

# Extra steps after install
post_install() {
  case $1 in
    io.mpv.Mpv)
      local d=~/.var/app/$1/config/mpv
      rm -rf "$d"
      mkdir -p "$(dirname "$d")"
      cp -a ~/.dotfiles/mpv "$d"
      "$d/mpv.conf.sh" >"$d/mpv.conf"
      ;;
  esac
}

# Extra runtimes for `sdk`: https://github.com/orgs/flathub/repositories?q=sdk.extension
SDK_REFS="
  org.freedesktop.Platform
  org.freedesktop.Sdk
  org.freedesktop.Sdk.Extension.dotnet10
  org.freedesktop.Sdk.Extension.golang
  org.freedesktop.Sdk.Extension.llvm21
  org.freedesktop.Sdk.Extension.openjdk25
  org.freedesktop.Sdk.Extension.rust-stable
  org.freedesktop.Sdk.Extension.texlive
  org.freedesktop.Sdk.Extension.typescript
  org.electronjs.Electron2.BaseApp
"
# }}}

usage() {
  cat <<USAGE
Usage: ${0##*/} <app>...             install apps (alias or app-id)
       ${0##*/} uninstall <app>...
       ${0##*/} bundle <app>...      export .flatpak bundle (built apps only)
       ${0##*/} clean <app>...       remove build leftovers (built apps only)
       ${0##*/} update               update everything, refresh launchers
       ${0##*/} sdk                  install common SDK runtimes/extensions
       ${0##*/} list                 print app aliases

Apps:
$(apps | awk -F'\t' '{printf "  %-14s %-34s %s\n",$1,$2,$3}')
USAGE
}

die() { echo "Error: $*" >&2; exit 1; }

# run <command...>: print the command (like `set -x`, but readable) and run it
run() {
  { printf '+'; printf ' %q' "$@"; echo; } >&2
  "$@"
}

# need_pkgs <command>:<apt package>...: make sure the commands exist, installing
# the missing packages with apt (via sudo) on Debian-like systems. Fails early,
# before any big downloads.
need_pkgs() {
  local pair missing=()
  for pair in "$@"; do
    command -v "${pair%%:*}" >/dev/null 2>&1 || missing+=("${pair##*:}")
  done
  [[ ${#missing[@]} -eq 0 ]] && return 0
  command -v apt-get >/dev/null 2>&1 ||
    die "missing: ${missing[*]} (install with your package manager)"
  local sudo=
  if [[ $EUID -ne 0 ]]; then
    command -v sudo >/dev/null 2>&1 || die "missing: ${missing[*]} (and no sudo to install them)"
    sudo=sudo
  fi
  run $sudo apt-get install -y "${missing[@]}"
  for pair in "$@"; do
    command -v "${pair%%:*}" >/dev/null 2>&1 || die "${pair%%:*} still not found after install"
  done
}
need_flatpak() { need_pkgs flatpak:flatpak; }
need_flatpak_builder() { need_pkgs flatpak:flatpak flatpak-builder:flatpak-builder curl:curl; }

# app_info <alias|app-id>: sets ALIAS, APP_ID, SOURCE, MENU_NAME
app_info() {
  local a i s n
  while IFS=$'\t' read -r a i s n; do
    if [[ "$1" == "$a" || "$1" == "$i" ]]; then
      ALIAS=$a APP_ID=$i SOURCE=$s
      MENU_NAME=$n
      return 0
    fi
  done < <(apps)
  die "unknown app '$1' (try: ${0##*/} list)"
}

# Make flatpak read our overrides/ (via a symlink); a real directory is backed up
ensure_overrides() {
  local dir=~/.local/share/flatpak/overrides
  [[ "$dir" -ef "$HERE/overrides" ]] && return 0
  mkdir -p "$(dirname "$dir")"
  if [[ -d "$dir" && ! -L "$dir" ]]; then
    rm -rf "$dir.bak"
    mv "$dir" "$dir.bak"
    echo "Backed up $dir to $dir.bak" >&2
  fi
  run ln -sfn "$HERE/overrides" "$dir"
}

# Validate all requested apps up front, before installing any of them, and
# refuse to install without overrides/global (per-app files are optional).
check_apps() {
  local a
  [[ -f "$HERE/overrides/global" ]] || die "missing $HERE/overrides/global"
  for a in "$@"; do app_info "$a"; done
  ensure_overrides
}

add_remote() {
  run flatpak remote-add --if-not-exists --user flathub "$FLATHUB"
}

# Launcher {{{
LAUNCHER_DIR=~/.local/share/applications
BIN_DIR=~/.local/bin
EXPORTS=~/.local/share/flatpak/exports

# Copy the exported .desktop file with " (Flatpak)" appended to the first Name=
# (action sections are left alone) and symlink the binary into ~/.local/bin.
# Uses ALIAS, APP_ID, MENU_NAME (from app_info).
launcher_install() {
  local id=$APP_ID src=$EXPORTS/share/applications/$APP_ID.desktop
  local dest=$LAUNCHER_DIR/$APP_ID.desktop name=$MENU_NAME
  [[ -f "$src" ]] || die "desktop file not found: $src"
  mkdir -p "$LAUNCHER_DIR" "$BIN_DIR"
  awk -v name="$name" '
    !done && /^Name=/ {
      if (name != "") print "Name=" name
      else if ($0 ~ / \(Flatpak\)$/) print
      else print $0 " (Flatpak)"
      done = 1; next
    }
    { print }
  ' "$src" >"$dest.tmp"
  chmod 0644 "$dest.tmp"
  mv -f "$dest.tmp" "$dest"
  update-desktop-database "$LAUNCHER_DIR" 2>/dev/null || true
  ln -sf "$EXPORTS/bin/$id" "$BIN_DIR/$ALIAS"
}

launcher_remove() {
  rm -f "$LAUNCHER_DIR/$APP_ID.desktop" "$BIN_DIR/$ALIAS"
}
# }}}
# Building {{{

# Build state lives outside the dotfiles, per app in $WORK/<alias>/:
#   state/      flatpak-builder --state-dir (downloads, ccache, stage cache; kept)
#   build-dir/  the app before export (deleted after a successful build)
#   download/   download.sh output, linked as ./<alias>/download-dir for the manifest
# $WORK/repo: built apps are exported to (and installed from) it. It must stay:
# installed apps keep it as their origin remote, so `flatpak update` needs it.
WORK=${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles-flatpak
REPO=$WORK/repo

# Sets MANIFEST (path) and runs download.sh if present
build_prepare() {
  local dir=$HERE/$ALIAS work=$WORK/$ALIAS
  MANIFEST=$dir/$APP_ID.yaml
  [[ -f "$MANIFEST" ]] || die "manifest not found: $MANIFEST"
  [[ -x "$dir/download.sh" ]] || return 0
  mkdir -p "$work/download"
  # Move an old in-tree download-dir/ out, then link it
  if [[ -d "$dir/download-dir" && ! -L "$dir/download-dir" ]]; then
    mv -n "$dir/download-dir"/* "$work/download/" 2>/dev/null || true
    rm -rf "$dir/download-dir"
  fi
  ln -sfn "$work/download" "$dir/download-dir"
  (cd "$dir" && run ./download.sh)
}

# build_run [extra flatpak-builder args]
# Runtime, SDK, base app and SDK extensions come from the manifest (--install-deps-from).
build_run() {
  add_remote
  (cd "$(dirname "$MANIFEST")" && \
    run flatpak-builder --user --force-clean --install-deps-from=flathub \
      --state-dir="$WORK/$ALIAS/state" --repo="$REPO" \
      "$@" "$WORK/$ALIAS/build-dir" "$(basename "$MANIFEST")")
}

# After a successful build: drop old commits from the repo and the exported build-dir
build_cleanup() {
  run flatpak build-update-repo --prune --prune-depth=0 "$REPO" >/dev/null
  rm -rf "$WORK/$ALIAS/build-dir"
}

is_build() { [[ "$SOURCE" == build ]]; }
# }}}

install_app() {
  app_info "$1"
  if is_build; then
    need_flatpak_builder
    build_prepare
    build_run --install
    build_cleanup
  else
    need_flatpak
    add_remote
    run flatpak install -y --user flathub "$APP_ID"
  fi
  launcher_install
  post_install "$APP_ID"
}

uninstall_app() {
  app_info "$1"
  need_flatpak
  run flatpak uninstall -y --user "$APP_ID" || true
  launcher_remove
}

bundle_app() {
  app_info "$1"
  is_build || die "$ALIAS is a Flathub app, nothing to bundle"
  need_flatpak_builder
  build_prepare
  build_run
  run flatpak build-bundle "$REPO" "$HERE/$APP_ID.flatpak" "$APP_ID"
  build_cleanup
  echo "Bundle created: $HERE/$APP_ID.flatpak"
}

clean_app() {
  app_info "$1"
  is_build || die "$ALIAS is a Flathub app, nothing to clean"
  rm -rf "${WORK:?}/$ALIAS" "$HERE/$ALIAS"/{.flatpak-builder,build-dir,download-dir}
}

update_all() {
  need_flatpak
  ensure_overrides
  run flatpak update -y --user
  local i
  for i in $(apps | cut -f2); do
    if [[ -f "$EXPORTS/share/applications/$i.desktop" ]]; then
      app_info "$i"
      launcher_install
    fi
  done
}

install_sdk() {
  need_flatpak
  local rv=$RUNTIME_VERSION refs=() r
  for r in $SDK_REFS; do refs+=("$r//$rv"); done
  add_remote
  run flatpak install -y --user flathub "${refs[@]}"
}

foreach_app() {
  local fn=$1 a; shift
  [[ $# -gt 0 ]] || die "missing app name"
  for a in "$@"; do "$fn" "$a"; done
}

case "${1:-}" in
  ''|-h|--help|help) usage;;
  list)      apps | cut -f1;;
  uninstall) shift; foreach_app uninstall_app "$@";;
  bundle)    shift; foreach_app bundle_app "$@";;
  clean)     shift; foreach_app clean_app "$@";;
  update)    update_all;;
  sdk)       install_sdk;;
  -*)        usage >&2; exit 1;;
  *)         check_apps "$@"; foreach_app install_app "$@";;
esac
