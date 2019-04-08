export QT_AUTO_SCREEN_SCALE_FACTOR=1

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

  for _d in "$CUDA_ROOT/bin" "$CONDA_ROOT/bin" ~/.dotfiles/bin ~/.local/bin ~/.bin ~/bin; do
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

if [ -f "$HOME/.private/profile" ]; then
  . "$HOME/.private/profile"
fi

if [ -z "$HIDPI" ] && [ -f "/run/user/$(id -u)/dconf/user" ]; then
  if [ "$(dconf read /org/gnome/desktop/interface/scaling-factor 2>/dev/null)" = "uint32 2" ]; then
    export HIDPI=1
  else
    export HIDPI=0
  fi
fi

# vim: ft=sh
