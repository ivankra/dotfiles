#!/bin/sh

set -e -x
rm -rf ~/.local/tarballs/*
rm -rf ~/.local/share/gtk-doc
rm -rf ~/.local/share/doc
rm -rf ~/.local/share/info
rm -rf ~/.local/info
#rm -rf .local/share/man
#rm -rf .local/man

(cd ~/.local/share/locale && rm -rf $(ls | grep -v '^en'))
(cd ~/.local/bin && strip *; true)
