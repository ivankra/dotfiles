#!/bin/bash
# Usage: ./run.sh [flags] [notebook|lab|bash]
#   -c <dir>    mount specified conda installation directory at /opt/conda
#               default: ./conda if exists, else installation from docker build
#   -n <env>    activate specified environment
#   -v <spec>   docker run flag: bind mount a volume

IMAGE=lab

host_main() {
  CMD=(nvidia-docker run --rm -it --init --shm-size=4g --ulimit memlock=-1 --ulimit stack=67108864)

  CONDA_DIR=""
  if [[ -d conda ]]; then
    CONDA_DIR=conda
  fi

  while [[ $# > 0 ]]; do
    case "$1" in
      -c|--conda) CONDA_DIR="$2"; shift 2;;
      -n) CMD+=(-e "LAB_ENV=$2"); shift 2;;
      -v) CMD+=(-v "$2"); shift 2;;
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
    sudo --preserve-env -u "$NB_USER" bash -- "$(realpath -- "$0")" "$@"
    exit $?
  fi

  unset SUDO_UID SUDO_GID SUDO_USER SUDO_COMMAND
  export HOME="/home/$USERNAME"

  umask 002; cd /work
  echo "umask 002; cd /work" >~/.bashrc.local  # for ssh
  export CONDA_ROOT=/opt/conda
  source ~/.bashrc
  if [[ -f $CONDA_ROOT/etc/profile.d/conda.sh ]]; then
    source $CONDA_ROOT/etc/profile.d/conda.sh
  fi

  if [[ -d ~/.history && ! -L ~/.history ]]; then
    rm -rf ~/.history
  fi
  for dir in .history .torch .keras; do
    if ! [[ -f "$HOME/$dir" ]]; then
      mkdir -p "$CONDA_ROOT/home/$dir" && ln -s "$CONDA_ROOT/home/$dir" "$HOME/$dir"
    fi
  done

  TOKEN="$(openssl rand -hex 8)"
  mkdir -p ~/.jupyter
  # for jupyter_notebook_config.py
  echo "$TOKEN" >~/.jupyter/token

  echo "SSH:      ssh-insecure $(whoami)@$IPADDR / ssh-insecure root@$IPADDR / docker exec -it $HOSTNAME bash"
  echo "URL:      http://$IPADDR:8888/?token=${TOKEN}"
  echo

  if [[ -n "$LAB_ENV" ]]; then
    echo "+ conda activate $LAB_ENV"
    conda activate "$LAB_ENV"
    unset LAB_ENV
  fi

  if [[ "$1" == notebook || "$1" == nb ]] ||
     ([[ "$1" == "" ]] && which jupyter-notebook >/dev/null 2>&1); then
    (set -e -x; jupyter-notebook --ip=0.0.0.0 --port=8888 --NotebookApp.token="$TOKEN")
  elif [[ "$1" == lab ]]; then
    (set -e -x; jupyter-lab --ip=0.0.0.0 --port=8888 --LabApp.token="$TOKEN")
  elif [[ "$1" == "" || "$1" == "sh" || "$1" == bash ]]; then
    bash -i -l
  else
    "$@"
  fi
}

if [[ "$0" != "/run.sh" ]]; then
  host_main "$@"
else
  docker_main "$@"
fi
