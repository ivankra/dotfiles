#!/bin/bash
set -e

# Back up /root to /root-template if it doesn't exist
if [[ ! -d /root-template ]]; then
  cp -a /root /root-template
  exit 0
fi

# Otherwise, we're being used as entrypoint
# Restore /root if it's missing .config
if [[ ! -d /root/.config ]]; then
  cp -a /root-template/. /root/
fi

exec "$@"
