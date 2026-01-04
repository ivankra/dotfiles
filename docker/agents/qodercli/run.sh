#!/bin/bash -e
mkdir -p ~/.docker/qodercli

CMD=(
  podman run -it --rm
  -v "$PWD:$PWD"
  -v "$HOME/.docker/qodercli:/root"
  -w "$PWD"
)

# Add .git bind-mount if it exists
if [ -d "$PWD/.git" ]; then
  CMD+=(-v "$PWD/.git:$PWD/.git")
fi

exec "${CMD[@]}" localhost/qodercli "$@"
