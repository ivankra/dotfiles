#!/bin/bash
# Installs/reinstall dotfiles. Can be rerun multiple times.
set -e -u -o pipefail
source "${BASH_SOURCE[0]%/*}/setup.lib.sh"

if ! [[ -f "$HOME/.dotfiles/setup.sh" && "$HOME/.dotfiles/setup.sh" -ef "$0" ]]; then
  if [[ $UID == 0 ]]; then
    SCRIPT_PATH=$(readlink -f "$0")
    SCRIPT_USER=$(stat -c %U "$SCRIPT_PATH")
    if [[ "$SCRIPT_PATH" == "/home/$SCRIPT_USER/"* ]]; then
      echo "Will run setup under $SCRIPT_USER"
      (set -x; sudo -u "$SCRIPT_USER" "$SCRIPT_PATH")
      exit $?
    fi
  fi
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

setup_ln bash_logout
setup_ln bashrc
setup_ln gdbinit
setup_ln hushlogin
setup_ln inputrc
setup_ln profile
setup_ln vim
setup_ln vimrc

if hash tmux >/dev/null 2>&1; then
  setup_ln tmux.conf
fi
if hash htop >/dev/null 2>&1; then
  setup_ln htoprc ~/.config/htop/htoprc
fi
if hash ipython >/dev/null 2>&1 || hash ipython3 >/dev/null 2>&1; then
  #setup_gen <(./jupyter/jupyter_notebook_config.json.sh) ~/.dotfiles/jupyter/jupyter_notebook_config.json
  setup_ln ipython_config.py ~/.ipython/profile_default/ipython_config.py
fi
if hash jupyter >/dev/null 2>&1 || hash jupyter-notebook >/dev/null 2>&1; then
  setup_ln jupyter
fi
if hash R >/dev/null 2>&1; then
  setup_ln Rprofile
fi

if [[ $UID != 0 ]]; then
  setup_cp mpv-input.conf ~/.config/mpv/input.conf
  setup_cp vlcrc ~/.config/vlc/vlcrc
  setup_gen <(./mpv.conf.sh) ~/.config/mpv/mpv.conf
  if hash tkdiff >/dev/null 2>&1; then
    setup_ln tkdiffrc
  fi
  if hash xonsh >/dev/null 2>&1; then
    setup_ln xonshrc
  fi
  if [[ "$OSTYPE" != darwin* ]]; then
    setup_ln fcitx5 ~/.config/fcitx5
    setup_cp okularpartrc ~/.config/okularpartrc
    setup_ln plasma-localerc ~/.config/plasma-localerc
    setup_cp qpdfview-shortcuts.conf ~/.config/qpdfview/shortcuts.conf
    setup_gen --backup <(./qpdfview.sh) ~/.config/qpdfview/qpdfview.conf
    setup_gen <(./qt5ct.sh) ~/.config/qt5ct/qt5ct.conf
    setup_ln xinitrc
    setup_ln xsessionrc

    mkdir -p ~/.local/share/applications
    rm -f ~/.local/share/applications/gnome-system-monitor.desktop
    if hash code >/dev/null 2>&1; then
      envsubst <code.desktop >~/.local/share/applications/code.desktop
      setup_ln code ~/.local/bin/code
    fi
    if hash keepassxc >/dev/null 2>&1; then
      setup_cp keepassxc.desktop ~/.local/share/applications/org.keepassxc.KeePassXC.desktop
      setup_ln keepassxc.ini ~/.config/keepassxc/keepassxc.ini
    fi
    if hash virt-manager >/dev/null 2>&1; then
      setup_cp virt-manager.desktop ~/.local/share/applications/virt-manager.desktop
    fi
  fi
elif [[ -x /usr/sbin/synaptic ]]; then
  mkdir -m 0700 -p ~/.config/synaptic
  rm -rf ~/.synaptic
  setup_cp synaptic.conf ~/.config/synaptic/synaptic.conf
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

# don't show welcome message and mess up with prompt on first run
if hash byobu >/dev/null 2>&1; then
  for f in ~/.byobu/{prompt,.welcome-displayed}; do
    if ! [[ -f "$f" ]]; then
      mkdir -m 0700 -p ~/.byobu
      (set -x; touch "$f")
    fi
  done
fi

if ! [[ -d ~/.local/bin ]]; then
  (set -x; mkdir -p ~/.local/bin)
fi

if [[ -d ~/.gnupg/ ]]; then
  chmod og-rwx ~/.gnupg
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

setup_xfs_symlinks() {
  local xfsroot="/xfs"
  local xfshome="/xfs/$USER"
  local it

  if [[ "$OSTYPE" == darwin* ]]; then
    return 0
  fi

  if ! [[ -d "$xfshome" ]]; then
    if [[ $UID != 0 && -d "$xfsroot" ]] && mountpoint "$xfsroot" >/dev/null 2>&1; then
      mkdir -m 0750 "$xfshome" >/dev/null 2>&1 || true
    fi
    if ! [[ -d "$xfshome" ]]; then
      # Remove possible dead symlinks, unless it seems like xfs isn't mounted
      for it in ~/.local/share/containers ~/.cache; do
        if [[ -L "$it" && ! -d "$it" ]]; then
          if [[ "$(readlink "$it")" == $xfsroot/* ]] && fgrep " $xfsroot " /etc/fstab >/dev/null 2>&1; then
            continue
          fi
          rm -f "$it"
        fi
      done
      return 0
    fi
  fi

  if [[ $UID == 0 ]]; then
    return 0
  fi

  if ! [[ -d ~/.local/share ]]; then
    mkdir -p -m 0700 ~/.local ~/.local/share
  fi

  for it in "$xfshome/containers=$HOME/.local/share/containers" "$xfshome/cache=$HOME/.cache"; do
    local src="${it#*=}"
    local target="${it%=*}"
    if ! [[ -d "$target" ]]; then
      mkdir -m 0750 "$target" || true
      if ! [[ -d "$target" ]]; then
        continue
      fi
    fi
    if [[ -d "$src" ]]; then
      continue
    fi
    if [[ -L "$src" ]]; then
      rm -f "$src" || true
    fi
    ln -sf "$target" "$src"
    echo "Symlinked $src -> $target"
  done
}
setup_xfs_symlinks

rm -rf python/dotfiles/__pycache__

if [[ -x ~/.local/dotfiles/setup.sh ]]; then
  (set -x; ~/.local/dotfiles/setup.sh)
fi
