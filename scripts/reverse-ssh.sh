#!/usr/bin/env bash
# Problem: you can ssh from A to B, but firewalls don't let you ssh from B to A.
# This script solves this problem. It lets you ssh from B to A, bypassing firewalls.
#
# Usage:
#   * On machine A:
#       ./reverse-ssh.sh [user@]B 12345
#   * On machine B:
#       ssh -p 12345 [user@]localhost

REMOTE_USER_HOST=$1
TUNNEL_PORT=$2

if [ -z "$1" -o -z "$2" ]; then
  echo "Usage: reverse-ssh.sh [user@]host port"
  exit 1
fi

set -x
while true; do
  ssh \
    -o TCPKeepAlive=no \
    -o ServerAliveInterval=60 \
    -o ServerAliveCountMax=3 \
    -o BatchMode=yes \
    -o PreferredAuthentications=publickey  \
    -o ExitOnForwardFailure=yes \
    -o ConnectTimeout=30 \
    -o StrictHostKeyChecking=no \
    -xnNT -v \
    -R 127.0.0.1:${TUNNEL_PORT}:127.0.0.1:22 \
    ${REMOTE_USER_HOST}
  sleep 10
done
