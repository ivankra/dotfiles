#!/bin/bash

export QT_STYLE_OVERRIDE=adwaita

if ! (echo "$PATH" | grep -q ".dotfiles/bin"); then
  if [ -z "$CUDA_ROOT" ] && [ -z "$CUDA_PATH" ] && [ -d /usr/local/cuda ]; then
    export CUDA_ROOT=/usr/local/cuda
    export CUDA_PATH=/usr/local/cuda
  fi

  if [ -z "$CONDA_ROOT" ]; then
    if [ -x ~/.conda/bin/conda ]; then
      export CONDA_ROOT=~/.conda
    elif [ -x /opt/conda/bin/conda ]; then
      export CONDA_ROOT=/opt/conda
    fi
  fi

  for _d in "$CUDA_ROOT/bin" "$CONDA_ROOT/bin" ~/.dotfiles/bin ~/.dotfiles/bwrap ~/.local/bin ~/.bin ~/bin; do
    if [ -d "$_d" ] && ! (echo ":$PATH:" | fgrep -q ":$_d:"); then
      PATH="$_d:$PATH"
    fi
  done
  unset _d
fi
export PATH

if [ -n "$BASH_VERSION" ] && [ -f "$HOME/.bashrc" ]; then
  . "$HOME/.bashrc"
fi
