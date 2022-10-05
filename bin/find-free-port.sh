#!/bin/bash
# find-free-port.sh [lower bound]
# Find a free available tcp port

port=${1:-10000}

while netstat -ant | grep -q ":$port .*LISTEN" >/dev/null 2>&1; do
  ((++port));
done

echo "$port"
