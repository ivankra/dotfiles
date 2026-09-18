#!/bin/bash
set -e -u -o pipefail

# Point ~/.config/theme at this theme
theme_dir=$(cd "$(dirname "$0")" && pwd -P)
if [[ -L ~/.config/theme || ! -e ~/.config/theme ]] && ! [[ ~/.config/theme -ef "$theme_dir" ]]; then
  mkdir -p ~/.config
  ln -sfnr "$theme_dir" ~/.config/theme
  echo "Linked: ~/.config/theme -> $theme_dir"
fi

# gedit: missing

# gnome-terminal
~/.dotfiles/themes/gnome-terminal.sh ~/.config/theme/gnome-terminal.dconf

# Guake
if hash guake dconf >/dev/null 2>&1; then
  for path in /org/guake/ /apps/guake/; do
    dconf load "$path" <~/.config/theme/guake.dconf
  done
fi

# Ptyxis: install a custom palette (built-in 'Sonokai' swaps blue/orange)
if hash ptyxis dconf >/dev/null 2>&1; then
  mkdir -p ~/.local/share/org.gnome.Ptyxis/palettes
  cp -f ~/.config/theme/ptyxis.palette ~/.local/share/org.gnome.Ptyxis/palettes/sonokai-default.palette
  uuid=$(dconf read /org/gnome/Ptyxis/default-profile-uuid | tr -d "'")
  if [[ -n "$uuid" ]]; then
    dconf write "/org/gnome/Ptyxis/Profiles/$uuid/palette" "'sonokai-default'"
  fi
fi
