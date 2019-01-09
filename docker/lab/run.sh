#!/bin/bash
# Usage: ./run.sh [flags] [notebook|lab|bash]
#   -v <spec>   docker run flag: bind mount a volume
#   -c <dir>    mount specified conda installation directory at /opt/conda
#               default: ./conda if exists, else installation from docker build

IMAGE=lab

host_main() {
  CMD=(nvidia-docker run --rm -it --init --shm-size=4g --ulimit memlock=-1 --ulimit stack=67108864)

  CONDA_DIR=""
  if [[ -d conda ]]; then
    CONDA_DIR=conda
  fi

  while [[ $# > 0 ]]; do
    case "$1" in
      -v) CMD+=(-v "$2"); shift 2;;
      -c|--conda) CONDA_DIR="$2"; shift 2;;
      *) break;;
    esac
  done

  CMD+=(-v "$(pwd):/work")
  if [[ -n "$CONDA_DIR" ]]; then
    CMD+=(-v "$(realpath -- "$CONDA_DIR"):/opt/conda")
  fi

  if ! which nvidia-docker >/dev/null 2>&1; then
    echo "Warning: nvidia-docker unavailable"
    CMD[0]=docker
  fi

  (set -e -x; "${CMD[@]}" "$IMAGE" "$@")
}

docker_main() {
  NB_USER="$(cd /home; ls)"
  IPADDR="$(hostname -I | cut -d ' ' -f 1)"

  if [[ $UID == 0 ]]; then
    ldconfig
    local PW="$(openssl rand -hex 8)"
    echo
    echo "Password: $NB_USER:$PW"
    echo "$NB_USER:$PW" | chpasswd
    echo "root:$PW" | chpasswd
    unset PW
    mkdir -p /var/run/sshd
    /usr/sbin/sshd
    umask 002; cd /work
    echo "umask 002; cd /work" >~/.bashrc.local
    sudo --login -u "$NB_USER" bash -- "$(realpath -- "$0")" "$@"
    exit $?
  fi

  unset SUDO_UID SUDO_GID SUDO_USER SUDO_COMMAND

  umask 002; cd /work
  echo "umask 002; cd /work" >~/.bashrc.local  # for ssh
  export CONDA_ROOT=/opt/conda
  source ~/.bashrc
  if [[ -f $CONDA_ROOT/etc/profile.d/conda.sh ]]; then
    source $CONDA_ROOT/etc/profile.d/conda.sh
  fi

  if ! [[ -f ~/.torch ]]; then
    mkdir -p "$CONDA_ROOT/torch" && ln -s "$CONDA_ROOT/torch" ~/.torch
  fi

  TOKEN="$(openssl rand -hex 8)"
  mkdir -p ~/.jupyter
  echo "$TOKEN" >~/.jupyter/token

  echo "URL:      http://$IPADDR:8888/?token=${TOKEN}"
  echo "SSH:      ssh-insecure $(whoami)@$IPADDR"
  echo "          ssh-insecure root@$IPADDR"
  echo "Attach:   docker exec -it $HOSTNAME bash"
  echo

  if [[ "$1" == notebook || "$1" == nb || "$1" == "" ]] && [[ -x /opt/conda/bin/jupyter-notebook ]]; then
    (set -e -x; /opt/conda/bin/jupyter-notebook --ip=0.0.0.0 --port=8888 --NotebookApp.token="$TOKEN")
  elif [[ "$1" == lab && -x /opt/conda/bin/jupyter-lab ]]; then
    (set -e -x; /opt/conda/bin/jupyter-lab --ip=0.0.0.0 --port=8888 --LabApp.token="$TOKEN")
  else
    bash -i -l
  fi
}

if [[ "$0" != "/run.sh" ]]; then
  host_main "$@"
else
  docker_main "$@"
fi
