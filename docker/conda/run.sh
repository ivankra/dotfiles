#!/bin/bash
# Usage:
#   ./run.sh build
#   ./run.sh [mount directory]

IMAGE=conda3

ANACONDA_URL=https://repo.continuum.io/miniconda/Miniconda3-4.4.10-Linux-x86_64.sh
ANACONDA_SHA256=0c2e9b992b2edd87eddf954a96e5feae86dd66d69b1f6706a99bd7fa75e7a891

#ANACONDA_URL=https://repo.continuum.io/miniconda/Miniconda2-4.4.10-Linux-x86_64.sh
#ANACONDA_SHA256=4e4ff02c9256ba22d59a1c1a52c723ca4c4ec28fed3bc3b6da68b9d910fe417c

VOLUME=/srv/lab

SCRIPT_DIR="$(dirname -- "$(readlink -f -- "$0")")"


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
  docker build -t "$IMAGE" --build-arg "ANACONDA_URL=$ANACONDA_URL" --build-arg "ANACONDA_SHA256=$ANACONDA_SHA256" .
}

run() {
  if ! [[ -z "$1" ]]; then
    VOLUME="$1"
  fi

  if [[ -z "$VOLUME" ]]; then
    VOLUME=lab
    echo "Using volume 'lab' as /mnt"
  elif [[ -d "$VOLUME" ]]; then
    echo "Using directory $VOLUME as /mnt"
  else
    echo "Error: $VOLUME is not a directory"
    exit 1
  fi

  if which nvidia-docker >/dev/null 2>&1; then
    echo "Using nvidia runtime"
    DOCKER=nvidia-docker
  else
    DOCKER=docker
  fi

  if [[ -n "$SSH_CONNECTION" ]]; then
    JUMPHOST=$(hostname --fqdn)
    JUMPUSER=$(whoami)
    HOSTPORT=8888
    while netstat -46nlt 2>&1 | grep -q ":$HOSTPORT "; do
      HOSTPORT=$((HOSTPORT + 1))
    done
    echo "Picked host port $HOSTPORT"
  fi

  set -e -x
  $DOCKER run \
    --init --rm -i -t \
    -v "$VOLUME:/mnt" \
    -p "$HOSTPORT:8888" \
    -e "HOSTPORT=$HOSTPORT" \
    -e "JUMPHOST=$JUMPHOST" \
    -e "JUMPUSER=$JUMPUSER" \
    "$IMAGE"
}

startup() {
  if [[ $? == 0 ]]; then
    mkdir -p /var/run/sshd
    /usr/sbin/sshd
  fi

  cd /mnt
  echo "umask 002; cd /mnt" >~/.bashrc.local
  source ~/.bashrc

  TOKEN="$(openssl rand -hex 16)"
  IPADDR="$(hostname -I | cut -d ' ' -f 1)"

  echo
  echo "URL:             http://$IPADDR:8888/?token=${TOKEN}"
  if [[ -n "$JUMPHOST" ]]; then
    echo "                 http://$JUMPHOST:$HOSTPORT/?token=${TOKEN}"
  fi
  echo "SSH:             ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $(whoami)@$IPADDR"
  if [[ -n "$JUMPHOST" ]]; then
    echo "                 ssh -J $JUMPUSER@$JUMPHOST -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $(whoami)@$IPADDR"
  fi
  echo "Attach as root:  docker exec -it -u root ${HOSTNAME} bash"
  echo "Attach as $(whoami):  docker exec -it ${HOSTNAME} bash"
  echo

  /opt/conda/bin/jupyter-lab \
    --allow-root \
    --ip=0.0.0.0 \
    --no-browser \
    --port=8888 \
    --LabApp.token="${TOKEN}" \
    --NotebookApp.iopub_data_rate_limit=100000000
}

if [[ "$1" == "build" ]]; then
  build
elif [[ "$0" == "/run.sh" || "$1" == "startup" ]]; then
  startup
else
  run "$@"
fi
