#!/bin/bash
# Loads dconf-based settings.

set -e -o pipefail
cd "${BASH_SOURCE[0]%/*}"

dconf reset -f /org/gnome/terminal/ && ./gnome-terminal/gen.sh | dconf load /
