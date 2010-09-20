#!/bin/sh

set -x
rm -rf .local/tarbals/*
rm -rf .local/share/gtk-doc
rm -rf .local/share/doc
rm -rf .local/share/info
rm -rf .local/share/man
rm -rf .local/info
rm -rf .local/man

(cd .local/share/locale && rm -rf $(ls | grep -v '^en'))

if [ -d .local/libexec/git-core ]; then
  cd .local/libexec/git-core
  for x in $(md5sum * | grep "^$(md5sum <git | awk '{print $1}')" | grep -v ' git$' | awk '{print $2}'); do
    rm -f $x
    ln -s git $x
  done
fi

(cd .local/bin; strip *)
