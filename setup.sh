#!/bin/bash
# Installs/reinstall dotfiles. Can be rerun multiple times.
set -e -u -o pipefail
source "${BASH_SOURCE[0]%/*}/setup.lib.sh"

if ! [[ -f "$HOME/.dotfiles/setup.sh" && "$HOME/.dotfiles/setup.sh" -ef "$0" ]]; then
  echo "Error: dotfiles must be installed in ~/.dotfiles"
  exit 1
fi
cd ~/.dotfiles

remove_dotfiles_symlinks \
  ~/.config/autostart/gnome-keyring-ssh.desktop \
  ~/.config/mpv \
  ~/.config/mpv/input.conf \
  ~/.config/qpdfview \
  ~/.config/qpdfview/shortcuts.conf \
  ~/.fonts \
  ~/.gdb

setup_gen -c <(./gitconfig.sh) ~/.gitconfig
setup_gen -c <(./hgrc.sh) ~/.hgrc
setup_gen <(./jupyter/jupyter_notebook_config.json.sh) jupyter/jupyter_notebook_config.json
setup_ln Rprofile
setup_ln bash_logout
setup_ln bashrc
setup_ln gdbinit
setup_ln htoprc ~/.config/htop/htoprc
setup_ln hushlogin
setup_ln inputrc
setup_ln ipython_config.py ~/.ipython/profile_default/ipython_config.py
setup_ln jupyter
setup_ln profile
setup_ln sqliterc
setup_ln tmux.conf
setup_ln vim
setup_ln vimrc

if [[ $UID != 0 ]]; then
  setup_cp gnome-system-monitor.desktop ~/.local/share/applications/gnome-system-monitor.desktop
  setup_cp mpv-input.conf ~/.config/mpv/input.conf
  setup_cp okularpartrc ~/.config/okularpartrc
  setup_cp qpdfview-shortcuts.conf ~/.config/qpdfview/shortcuts.conf
  setup_cp vlcrc ~/.config/vlc/vlcrc
  setup_gen <(./mpv.conf.sh) ~/.config/mpv/mpv.conf
  setup_gen <(./qpdfview.sh) ~/.config/qpdfview/qpdfview.conf
  setup_gen <(./qt5ct.sh) ~/.config/qt5ct/qt5ct.conf
  setup_ln tkdiffrc
  setup_ln xinitrc
  setup_ln xonshrc
  setup_ln xsessionrc

  if [[ -x /usr/bin/virt-manager ]]; then
    setup_cp virt-manager.desktop ~/.local/share/applications/virt-manager.desktop
  fi
fi

if [[ $UID == 0 ]]; then
  mkdir -m 0700 -p ~/.synaptic
  setup_cp synaptic.conf ~/.synaptic/synaptic.conf
  if [[ -f /var/lib/synaptic/preferences ]]; then
    if ! [[ -s /var/lib/synaptic/preferences ]]; then
      rm -f /var/lib/synaptic/preferences || true
    else
      chmod 0644 /var/lib/synaptic/preferences || true
    fi
  fi
fi

mkdir -p -m 0700 ~/.ssh
setup_gen -c <(./ssh-config.sh) ~/.ssh/config
chmod 0700 ~/.ssh
chmod 0600 ~/.ssh/config
if [[ -f ~/.ssh/authorized_keys ]]; then
  chmod 0600 ~/.ssh/authorized_keys
fi

if [[ -x /usr/bin/byobu && ! -f ~/.byobu/.welcome-displayed ]]; then
  mkdir -p ~/.byobu
  (set -x; touch ~/.byobu/.welcome-displayed)
fi

if ! [[ -d ~/.local/bin ]]; then
  (set -x; mkdir -p ~/.local/bin)
fi

if ! [[ -d ~/.bin ]]; then
  (set -x; ln -s .local/bin ~/.bin)
fi

if [[ -d ~/.gnupg/ ]]; then
  chmod og-rwx ~/.gnupg/
fi

if ! [[ -e ~/.history ]]; then
  mkdir -p -m 0700 ~/.history
fi
if [[ -d ~/.history ]]; then
  chmod 0700 ~/.history
fi

rm -rf python/dotfiles/__pycache__

if [[ -x ~/.private/setup.sh ]]; then
  (set -x; ~/.private/setup.sh)
fi
