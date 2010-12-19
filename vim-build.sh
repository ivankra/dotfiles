#!/usr/bin/env bash
# Compiles cutting-edge vim

set -e -x
if [ "`uname -o`" != "FreeBSD" ]; then
  sudo apt-get build-dep vim-gnome
fi
cd /tmp
rm -rf /tmp/vim-hg
hg clone https://vim.googlecode.com/hg/ vim-hg
cd vim-hg
for x in ~/git/configs/vim*.patch; do
  echo Applying $x
  hg import --no-commit $x
done
make distclean
if [ "`uname -o`" != "FreeBSD" ]; then
  ./configure --prefix=/usr/local --with-features=huge --with-x --enable-gui=gnome2 --enable-cscope --enable-multibyte --enable-pythoninterp --disable-nls
  make
  sudo make install
else
  ./configure --prefix=$HOME/.local --with-features=huge --with-x --enable-gui=gtk2 --enable-cscope --enable-multibyte --disable-pythoninterp --disable-nls
  make
  make install
fi
cd /
rm -rf /tmp/vim-hg
