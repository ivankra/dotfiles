#!/bin/bash
# Usage: gnome-terminal.sh [--only] <profile.dconf>
# Loads a theme's gnome-terminal profile (one [:<uuid>] section) on top of
# shared non-color settings, adds it to the profile list and makes it default.
#   --only: delete all other profiles (other themes' and any others),
#           leaving just this one
# Run by themes' setup.sh.
set -e -u -o pipefail

only=0
if [[ "${1:-}" == "--only" ]]; then
  only=1
  shift
fi
if [[ $# -ne 1 ]]; then
  echo "Usage: ${0##*/} [--only] <profile.dconf>" >&2
  exit 1
fi

if ! [[ -x /usr/bin/gnome-terminal ]] || ! hash dconf >/dev/null 2>&1; then
  exit 0
fi

profiles=/org/gnome/terminal/legacy/profiles:
uuid=$(sed -n 's/^\[:\(.*\)\]$/\1/p' "$1")

dconf reset -f "$profiles/:$uuid/"
# Non-color settings shared by all themes
dconf load "$profiles/:$uuid/" <<'EOF'
[/]
audible-bell=false
default-size-columns=100
default-size-rows=40
scrollback-unlimited=true
scrollbar-policy='never'
use-system-font=true
use-theme-transparency=false
EOF
dconf load "$profiles/" <"$1"

if ((only)); then
  # Profiles in the list, and any left in dconf without being listed
  others=$( (dconf read "$profiles/list" | grep -o "'[^']*'" | tr -d "'"
             dconf list "$profiles/" | sed -n 's|^:\(.*\)/$|\1|p') | sort -u)
  for other in $others; do
    if [[ "$other" != "$uuid" ]]; then
      dconf reset -f "$profiles/:$other/"
      echo "Deleted gnome-terminal profile $other"
    fi
  done
  dconf write "$profiles/list" "['$uuid']"
fi

# Without --only, profiles are only ever added to the list: profiles of other
# themes stay available in the menu after switching
list=$(dconf read "$profiles/list")
if [[ "$list" != *"'$uuid'"* ]]; then
  if [[ "$list" == "" || "$list" == "@as []" ]]; then
    list="['$uuid']"
  else
    list="${list%]}, '$uuid']"
  fi
  dconf write "$profiles/list" "$list"
fi
dconf write "$profiles/default" "'$uuid'"
