#!/bin/bash
set -e -u -o pipefail

for x in ~/.dotfiles/bin-cond/*.cond; do
  if [[ -x "$x" && -x "${x/.cond}" ]]; then
    name=$(basename "${x/.cond}")
    dst=~/.local/bin/"$name"
    src=~/.dotfiles/bin-cond/"$name"

    if "$x" >/dev/null; then
      if ! [[ -L "$dst" && "$dst" -ef "$src" ]]; then
        mkdir -p -m 0700 ~/.local/bin
        rm -f "$dst"
        (set -x; ln -s -r "$src" "$dst")
      fi
    elif [[ -L "$dst" && ! -f "$dst" ]] || [[ "$dst" -ef "$src" ]]; then
      (set -x; rm -f ~/.local/bin/"$name")
    fi
  fi
done
