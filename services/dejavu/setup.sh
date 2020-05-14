#!/bin/bash
# setup.sh [--copy] [--keyrings]
#
# Install dejavu service and create an initial ~/.dejavu.git if needed.
#
#   --copy      copy existing browser directories if creating repo
#   --keyrings  also copy keyrings directory into the repo

set -e -o pipefail

COPY=1
KEYRINGS=0

while [[ $# > 0 ]]; do
  case $1 in
    --copy) COPY=1; shift;;
    --no-copy) COPY=0; shift;;
    --keyrings) KEYRINGS=1; shift;;
    --no-keyrings) KEYRINGS=0; shift;;
    *) echo "Unknown flag: $1"; exit 1;
  esac
done

if [[ -d ~/.dejavu.git ]]; then
  echo "~/.dejavu.git already exists, not recreating it"
else
  echo "Creating initial ~/.dejavu.git repository"

  TMPREPO=/tmp/dejavu-init
  rm -rf "$TMPREPO"
  mkdir -p "$TMPREPO"
  cd "$TMPREPO"

  git init .

  echo cache >.gitignore
  if ((COPY)); then
    if [[ -d ~/.mozilla && ! -L ~/.mozilla ]]; then
      cp -a ~/.mozilla "$TMPREPO/mozilla"
    fi
    if [[ -d ~/.config/chromium && ! -L ~/.config/chromium ]]; then
      cp -a ~/.config/chromium "$TMPREPO/chromium"
    fi
    if [[ -d ~/.config/google-chrome && ! -L ~/.config/google-chrome ]]; then
      cp -a ~/.config/google-chrome "$TMPREPO/google-chrome"
    fi
  fi

  mkdir -p "$TMPREPO/mozilla" && touch "$TMPREPO/mozilla/.gitignore"
  mkdir -p "$TMPREPO/chromium" && touch "$TMPREPO/chromium/.gitignore"
  mkdir -p "$TMPREPO/google-chrome" && touch "$TMPREPO/google-chrome/.gitignore"

  if ((KEYRINGS)) && [[ -d ~/.local/share/keyrings ]] ; then
    echo "Copying keyrings"
    rm -f ~/.local/share/keyrings/git
    cp -a ~/.local/share/keyrings "$TMPREPO/keyrings"
  fi

  git add .
  git -c "user.name=$USER" -c "user.email=$USER@$(hostname --short)" commit -m 'Initial commit'
  git gc
  git clone --mirror "$TMPREPO" ~/.dejavu.git
  rm -rf "$TMPREPO"

  echo "Created ~/.dejavu.git"

  rm -rf "$XDG_RUNTIME_DIR/dejavu"
fi

if systemctl --user status dejavu.service >/dev/null 2>&1; then
  systemctl --user disable dejavu.service
  rm -f ~/.config/systemd/user/dejavu.service
fi

mkdir -p ~/.config/systemd/user
envsubst <~/.dotfiles/services/dejavu/dejavu.service >~/.config/systemd/user/dejavu.service
systemctl --user enable dejavu.service
echo "Created dejavu.service"
echo "Run 'systemctl --user start dejavu.service' to activate it"
