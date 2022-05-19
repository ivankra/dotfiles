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
  ~/.gdb \
  ~/.sqliterc

if [[ -L ~/.bin && "$(readlink ~/.bin)" == ".local/bin" ]]; then
  (set -x; rm -f ~/.bin)
fi

if [[ -f ~/.dotfiles/gitconfig.local ]]; then
  setup_ln gitconfig.local ~/.gitconfig
else
  setup_gen -c <(./gitconfig.sh) ~/.gitconfig
fi

setup_gen -c <(./hgrc.sh) ~/.hgrc
setup_gen <(./jupyter/jupyter_notebook_config.json.sh) ~/.dotfiles/jupyter/jupyter_notebook_config.json
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
setup_ln tmux.conf
setup_ln vim
setup_ln vimrc

if [[ $UID != 0 ]]; then
  setup_ln fcitx5 ~/.config/fcitx5
  setup_cp gnome-system-monitor.desktop ~/.local/share/applications/gnome-system-monitor.desktop
  setup_cp mpv-input.conf ~/.config/mpv/input.conf
  setup_cp okularpartrc ~/.config/okularpartrc
  setup_cp qpdfview-shortcuts.conf ~/.config/qpdfview/shortcuts.conf
  setup_cp vlcrc ~/.config/vlc/vlcrc
  setup_gen <(./mpv.conf.sh) ~/.config/mpv/mpv.conf
  setup_gen --backup <(./qpdfview.sh) ~/.config/qpdfview/qpdfview.conf
  setup_gen <(./qt5ct.sh) ~/.config/qt5ct/qt5ct.conf
  setup_ln keepassxc.ini ~/.config/keepassxc/keepassxc.ini
  setup_ln tkdiffrc
  setup_ln xinitrc
  setup_ln xonshrc
  setup_ln xsessionrc

  if [[ -x /usr/bin/virt-manager ]]; then
    setup_cp virt-manager.desktop ~/.local/share/applications/virt-manager.desktop
  fi
  if [[ -x /usr/bin/keepassxc ]]; then
    setup_cp keepassxc.desktop ~/.local/share/applications/org.keepassxc.KeePassXC.desktop
  fi
else
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

~/.dotfiles/bin-cond/setup.sh

mkdir -p -m 0700 ~/.ssh
setup_gen -c <(./ssh-config.sh) ~/.ssh/config
chmod 0700 ~/.ssh
chmod 0600 ~/.ssh/config
if [[ -f ~/.ssh/authorized_keys ]]; then
  chmod 0600 ~/.ssh/authorized_keys
fi

# don't show welcome message and mess up with prompt on first run
for f in ~/.byobu/{prompt,.welcome-displayed}; do
  if ! [[ -f "$f" ]]; then
    mkdir -m 0700 -p ~/.byobu
    (set -x; touch "$f")
  fi
done

if ! [[ -d ~/.local/bin ]]; then
  (set -x; mkdir -p ~/.local/bin)
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

if [[ -f ~/.bash_history && ! -L ~/.bash_history ]]; then
  echo "Warning: orphan ~/.bash_history file"
  chmod og-rwx ~/.bash_history
fi

rm -rf python/dotfiles/__pycache__

if [[ -x ~/.local/dotfiles/setup.sh ]]; then
  (set -x; ~/.local/dotfiles/setup.sh)
fi
