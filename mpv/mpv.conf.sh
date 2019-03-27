#!/bin/bash

if [[ -x /usr/bin/mpv ]] && (/usr/bin/mpv --profile=help | grep -qw gpu-hq); then
  echo profile=gpu-hq
fi

echo scale=ewa_lanczossharp
echo cscale=ewa_lanczossharp
