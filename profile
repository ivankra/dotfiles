#!/bin/bash

export QT_STYLE_OVERRIDE=adwaita

if ! (echo "$PATH" | grep -q ".dotfiles/bin"); then
  for _d in ~/.dotfiles/bin ~/.local/bin ~/.bin ~/bin; do
    if [ -d "$_d" ] && ! (echo ":$PATH:" | fgrep -q ":$_d:"); then
      PATH="$_d:$PATH"
    fi
  done
  unset _d
fi
export PATH

if [ -n "$BASH_VERSION" ]; then
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi
