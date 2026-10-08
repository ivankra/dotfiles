#!/bin/bash
# URL handler for vimline://PATH:LINE (see delta's hyperlinks-file-link-format
# in gitconfig.delta); opens PATH at LINE in nvim-qt, else gvim.
set -e -u -o pipefail
url=${1#vimline://}
printf -v url '%b' "${url//%/\\x}"  # percent-decode
path=${url%:*}
line=${url##*:}
if ! [[ "$line" =~ ^[0-9]+$ ]]; then
  path=$url
  line=1
fi
bin_dir=$(dirname "$(readlink -f "$0")")
if command -v nvim-qt >/dev/null 2>&1; then
  exec "$bin_dir/qvim" -- "+$line" "$path"
else
  exec "$bin_dir/gvim" "+$line" -- "$path"
fi
