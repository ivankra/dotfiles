#!/usr/bin/env bash
# Compiles cutting-edge vim in which "set clipboard=unnamed" yanks to plus register on X11
set -e -x
#sudo apt-get build-dep vim-gnome
cd /tmp
rm -rf /tmp/vim-hg
hg clone https://vim.googlecode.com/hg/ vim-hg
cd vim-hg
hg import --no-commit ~/git/configs/ubuntu/vim.patch
make distclean
./configure --prefix=/usr/local --with-features=huge --with-x --enable-gui=gnome2 --enable-cscope --enable-multibyte --enable-pythoninterp --disable-nls
make
sudo make install
cd /
rm -rf /tmp/vim-hg
