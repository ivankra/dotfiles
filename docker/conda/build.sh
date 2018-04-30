#!/bin/bash

IMAGE=conda

ANACONDA_URL=https://repo.continuum.io/miniconda/Miniconda3-4.4.10-Linux-x86_64.sh
ANACONDA_SHA256=0c2e9b992b2edd87eddf954a96e5feae86dd66d69b1f6706a99bd7fa75e7a891

#ANACONDA_URL=https://repo.continuum.io/miniconda/Miniconda2-4.4.10-Linux-x86_64.sh
#ANACONDA_SHA256=4e4ff02c9256ba22d59a1c1a52c723ca4c4ec28fed3bc3b6da68b9d910fe417c

build() {
  set -e -o pipefail
  cd "$SCRIPT_DIR"
  rm -rf pkg
  mkdir -p pkg
  cp -a ~/.dotfiles pkg/dotfiles
  if [[ -f ~/.ssh/id_ed25519.pub ]]; then
    cp -a ~/.ssh/id_ed25519.pub pkg/authorized_keys
  elif [[ -f ~/.ssh/id_rsa.pub ]]; then
    cp -a ~/.ssh/id_rsa.pub pkg/authorized_keys
  fi
  if [[ -f ~/.ssh/authorized_keys ]]; then
    cat ~/.ssh/authorized_keys >>pkg/authorized_keys
  fi
  time docker build -t "$IMAGE" --build-arg "ANACONDA_URL=$ANACONDA_URL" --build-arg "ANACONDA_SHA256=$ANACONDA_SHA256" .
  rm -rf pkg
}

build
