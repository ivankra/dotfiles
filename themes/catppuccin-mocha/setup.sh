#!/bin/bash
set -e -u -o pipefail

# Point ~/.config/theme at this theme
theme_dir=$(cd "$(dirname "$0")" && pwd -P)
if [[ -L ~/.config/theme || ! -e ~/.config/theme ]] && ! [[ ~/.config/theme -ef "$theme_dir" ]]; then
  mkdir -p ~/.config
  ln -sfnr "$theme_dir" ~/.config/theme
  echo "Linked: ~/.config/theme -> $theme_dir"
fi

# gedit
if [[ -x /usr/bin/gedit ]]; then
  styles_dir=~/.local/share/gedit/styles
  if (($(gedit --version | grep -oP 'Version \K[0-9]+') >= 46)); then
    styles_dir=~/.local/share/libgedit-gtksourceview-300/styles
  fi
  mkdir -p $styles_dir
  cp -f ~/.config/theme/gedit.xml $styles_dir/catppuccin-mocha.xml
  dconf write /org/gnome/gedit/preferences/editor/scheme "'catppuccin-mocha'"
  dconf write /org/gnome/gedit/preferences/editor/style-scheme-for-dark-theme-variant "'catppuccin-mocha'"
  dconf write /org/gnome/gedit/preferences/ui/theme-variant "'dark'"
fi

# gnome-terminal
~/.dotfiles/themes/gnome-terminal.sh ~/.config/theme/gnome-terminal.dconf

# Guake
if hash guake dconf >/dev/null 2>&1; then
  for path in /org/guake/ /apps/guake/; do
    dconf load "$path" <~/.config/theme/guake.dconf
  done
fi

# Ptyxis built-in theme
if hash ptyxis dconf >/dev/null 2>&1; then
  uuid=$(dconf read /org/gnome/Ptyxis/default-profile-uuid | tr -d "'")
  if [[ -n "$uuid" ]]; then
    dconf write "/org/gnome/Ptyxis/Profiles/$uuid/palette" "'Catppuccin Mocha'"
  fi
fi
