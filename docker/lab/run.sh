#!/bin/bash
# Usage: ./run.sh [flags] [nb|lab|r|sh]
#   -d <dir>      directory to mount at /mnt, default: current directory
#   -i <image>    image to run, default: guess from command
#   -v <spec>     docker run flag: bind mount a volume

host_main() {
  DFLAGS=()
  IMAGE=
  WORKDIR=.

  while [[ $# > 0 ]]; do
    case "$1" in
      -d) WORKDIR="$2"; shift 2;;
      -i|--image) IMAGE="$2"; shift 2;;
      -v) DFLAGS+=("$1" "$2"); shift 2;;
      *) break;;
    esac
  done

  if [[ -z "$IMAGE" ]]; then
    IMAGE=lab
    if [[ "$1" == r ]]; then
      IMAGE=lab-rstudio
    fi
  fi

  if ! [[ -d "$WORKDIR" ]]; then
    echo "Error: directory $WORKDIR doesn't exist"
    exit 1
  fi
  WORKDIR=$(realpath -m -- "$WORKDIR")
  DFLAGS+=(-v "$WORKDIR:/work")

  if which nvidia-docker >/dev/null 2>&1; then
    DOCKER=nvidia-docker
  else
    echo "Warning: nvidia runtime unavailable"
    DOCKER=docker
  fi

  if [[ -n "$SSH_CONNECTION" ]]; then
    DFLAGS+=(-e "JUMPHOST=$(hostname --fqdn)")
    DFLAGS+=(-e "JUMPUSER=$(whoami)")
    HOSTPORT=8888
    while netstat -46nlt 2>&1 | grep -q ":$HOSTPORT "; do
      HOSTPORT=$((HOSTPORT + 1))
    done
    echo "Picked host port $HOSTPORT"
    DFLAGS+=("-p" "$HOSTPORT:8888")
  fi

  set -e -x
  $DOCKER run --init --rm -i -t "${DFLAGS[@]}" "$IMAGE" "$@"
}

docker_main() {
  COMMAND="${1:-nb}"
  NB_USER="$(cd /home; ls)"
  IPADDR="$(hostname -I | cut -d ' ' -f 1)"

  if [[ $UID == 0 ]]; then
    local PW="$(openssl rand -hex 16)"
    echo
    echo "Login:    $NB_USER"
    echo "Password: $PW"
    echo "$NB_USER:$PW" | chpasswd
    echo "root:$PW" | chpasswd
    unset PW
    mkdir -p /var/run/sshd
    /usr/sbin/sshd
    umask 002; cd /work
    echo "umask 002; cd /work" >~/.bashrc.local

    if [[ "$1" == r ]]; then
      echo "URL:      http://$IPADDR:8888/"
      echo "Qt:       ssh -X -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $NB_USER@$IPADDR bash -i -c rstudio"
      echo "SSH:      ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $NB_USER@$IPADDR"
      echo
      set -x
      rstudio-server start
      bash -i -l
      exit $?
    fi

    sudo --login -u "$NB_USER" bash -- "$(realpath -- "$0")" "$@"
    exit $?
  fi

  umask 002; cd /work
  echo "umask 002; cd /work" >~/.bashrc.local
  source ~/.bashrc

  TOKEN="$(openssl rand -hex 16)"
  mkdir -p ~/.jupyter
  echo "$TOKEN" >~/.jupyter/token

  echo "URL:      http://$IPADDR:8888/?token=${TOKEN}"
  echo "SSH:      ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $(whoami)@$IPADDR"
  if [[ -n "$JUMPHOST" ]]; then
    echo "Jump:     ssh -J $JUMPUSER@$JUMPHOST  -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $(whoami)@$IPADDR"
    # TODO: print ssh port forwarding instructions
    echo "          http://$JUMPHOST:$HOSTPORT/?token=${TOKEN}"
  fi
  echo "Attach:   docker exec -it ${HOSTNAME} bash"
  echo

  case "$COMMAND" in
    lab)
      set -x
      /opt/conda/bin/jupyter-lab --ip=0.0.0.0 --port=8888 --LabApp.token="${TOKEN}";;
    nb|notebook)
      set -x
      /opt/conda/bin/jupyter-notebook --ip=0.0.0.0 --port=8888 --NotebookApp.token="${TOKEN}";;
    bash|sh)
      bash -i -l;;
    *)
      bash -i -l -- "$@";;
  esac
}

if [[ "$0" == "/run.sh" ]]; then
  docker_main "$@"
else
  host_main "$@"
fi
