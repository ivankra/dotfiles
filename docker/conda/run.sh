#!/bin/bash
# Usage: ./run.sh [-d <working directory or volume>] [command]
# Command: lab, nb/notebook or a shell command e.g. bash.

IMAGE=conda

host_main() {
  WORKDIR=.
  while [[ $# > 0 ]]; do
    case "$1" in
      -d) WORKDIR="$2"; shift 2;;
      *) break;;
    esac
  done

  if ! [[ -d "$WORKDIR" ]]; then
    echo "Error: directory $WORKDIR doesn't exist"
    exit 1
  fi

  WORKDIR=$(realpath -m -- "$WORKDIR")

  if which nvidia-docker >/dev/null 2>&1; then
    DOCKER=nvidia-docker
  else
    echo "Warning: nvidia runtime unavailable"
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

  ENVF=()
  if [[ -n "$HOSTPORT" ]]; then ENVF+=("-e" "HOSTPORT=$HOSTPORT"); fi
  if [[ -n "$JUMPHOST" ]]; then ENVF+=("-e" "JUMPHOST=$JUMPHOST"); fi
  if [[ -n "$JUMPUSER" ]]; then ENVF+=("-e" "JUMPUSER=$JUMPUSER"); fi

  set -e -x
  $DOCKER run \
    --init --rm -i -t \
    -v "$WORKDIR:/mnt" \
    ${HOSTPORT:+-p "$HOSTPORT:8888"} \
    "${ENVF[@]}" "$IMAGE" "$@"
}

docker_main() {
  if [[ $UID == 0 ]]; then
    local USR="$(cd /home; ls)"
    local PW="$(openssl rand -hex 16)"
    echo
    echo "root password:   $PW"
    echo "$USR:$PW" | chpasswd
    echo "root:$PW" | chpasswd
    usermod -a -G sudo "$USR"
    mkdir -p /var/run/sshd
    /usr/sbin/sshd
    echo "umask 002; cd /mnt" >~/.bashrc.local
    sudo --preserve-env --login -u "$USR" bash -- "$(realpath -- "$0")" "$@"
    exit $?
  fi

  umask 002; cd /mnt
  echo "umask 002; cd /mnt" >~/.bashrc.local
  source ~/.bashrc

  TOKEN="$(openssl rand -hex 16)"
  mkdir -p ~/.jupyter
  echo "$TOKEN" >~/.jupyter/token

  IPADDR="$(hostname -I | cut -d ' ' -f 1)"

  echo "URL:             http://$IPADDR:8888/?token=${TOKEN}"
  if [[ -n "$JUMPHOST" ]]; then
    # TODO: print ssh port forwarding instruction
    echo "                 http://$JUMPHOST:$HOSTPORT/?token=${TOKEN}"
  fi
  echo "SSH:             ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $(whoami)@$IPADDR"
  if [[ -n "$JUMPHOST" ]]; then
    echo "                 ssh -J $JUMPUSER@$JUMPHOST -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $(whoami)@$IPADDR"
  fi
  echo "Attach:               docker exec -it ${HOSTNAME} bash"
  echo

  case "${1:-nb}" in
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
