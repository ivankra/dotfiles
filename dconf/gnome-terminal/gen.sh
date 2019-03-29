#!/bin/bash
# Generates /org/gnome/terminal/ dconf configuration from Xresources-style
# colorscheme files in this directory (all files beginning with cap)
# or from files passed on the command line.
#
# Generated one profile per color scheme.
#
# Usage:
#   $ dconf reset -f /org/gnome/terminal/ && ./gen-dconf.sh | dconf load /
#
set -e -o pipefail

if [[ $# == 0 ]]; then
  SCRIPT_DIR="$(dirname $(readlink -f "$0"))"
  THEMES="$(ls "$SCRIPT_DIR"/[A-Z]*)"
else
  THEMES="$(ls $@)"
fi

DEFAULT_THEME="${DEFAULT_THEME:-Dracula}"

get_color() {
  cat "$FILENAME" | cpp | sed -e 's/!.*//' | egrep ".*[*.]$1:" | egrep -o ':[^!]*' | \
    egrep -o '#[a-zA-Z0-9]{6}' | head -1
}

parse_theme() {
  COLOR_FG="$(get_color foreground)"
  COLOR_BG="$(get_color background)"
  PALETTE=""
  for n in {0..15}; do
    PALETTE+="${PALETTE:+, }'$(get_color color$n)'"
  done
}

gen_dconf() {
  NUM=0
  UUID_LIST=""

  for FILENAME in $THEMES; do
    parse_theme

    NAME="$(basename "$FILENAME")"

    NUM=$((NUM+1))
    UUID="00000000-0000-0000-0000-$(printf "%.12X" $NUM)"
    UUID_LIST+="${UUID_LIST:+, }'$UUID'"
    [[ "$FILENAME" == "$DEFAULT_THEME" || -z "$UUID_DEFAULT" ]] &&
      UUID_DEFAULT="$UUID"

    SCROLLBAR_POLICY="never"
    for k in /org/{gnome,cinnamon}/desktop/interface/gtk-theme; do
      if dconf read $k | grep -q Ambiance; then
        SCROLLBAR_POLICY="always"
      fi
    done

    cat <<EOF
[org/gnome/terminal/legacy/profiles:/:${UUID}]
visible-name='$NAME'
background-color='$COLOR_BG'
foreground-color='$COLOR_FG'
use-theme-colors=false
palette=[$PALETTE]
use-system-font=true
use-theme-transparency=false
default-size-columns=100
default-size-rows=40
scrollback-unlimited=true
scrollbar-policy='$SCROLLBAR_POLICY'
audible-bell=false

EOF
  done

  cat <<EOF
[org/gnome/terminal/legacy/profiles:]
list=[$UUID_LIST]
default='$UUID_DEFAULT'

[org/gnome/terminal/legacy/keybindings]
help='disabled'

[org/gnome/terminal/legacy]
menu-accelerator-enabled=false
schema-version=uint32 3
default-show-menubar=false
theme-variant='system'
EOF
}

gen_dconf
