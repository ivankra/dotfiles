#!/bin/bash

systemctl --user disable dejavu.service

rm -f ~/.config/systemd/user/dejavu.service

for lnk in ~/.cache ~/.mozilla ~/.config/chromium ~/.config/google-chrome; do
  if [[ -L "$lnk" && "$(readlink "$lnk")" =~ /run/.*/dejavu/.* ]]; then
    echo "Removing $lnk"
    rm -f "$lnk"
  fi
done

mkdir -p ~/.cache
chmod 0700 ~/.cache
