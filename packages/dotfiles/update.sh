#!/bin/bash
# Create ~/.dotfiles directory for all users, cloning from system repository
# installed by dotfiles package. If directory exists and HEAD does not match
# system repository's revision, it will be erased and cloned from scratch.
# On update, runs the setup script under the user's account.
#
# Created repositories will have an untracked MANAGED file that marks it as
# updatable by this script. Deleting it stops further updates.
# Creating ~/.dotfiles-update-optout stops updates as well.

set -e -u -o pipefail

PKG_REPO="/usr/local/share/dotfiles/dotfiles.git"
if ! [[ -d "$PKG_REPO" ]]; then
  echo "Missing $PKG_REPO"
  exit 1
fi

if [[ $UID != 0 ]]; then
  echo "Must be run under root"
  exit 1;
fi

FORCE=0
if [[ "$#" != 0 && ("$1" == "-f" || "$1" == "--force") ]]; then
  FORCE=1
fi

PKG_REV=$(cd "$PKG_REPO" && git show-ref --hash refs/heads/master)

MANAGED_MSG="This repository is managed by /usr/local/share/dotfiles/update.sh script. Local changes will be lost. Delete this file to prevent automatic updates."

getent passwd | while IFS=':' read USER _ USER_UID _ _ USER_HOME USER_SHELL; do
  if [[ ( "$USER" != "root" && "$USER_UID" -lt 1000 ) ||
        "$USER_SHELL" == "/bin/false" || "$USER_SHELL" == *nologin ||
        ! -d "$USER_HOME" || -f "$USER_HOME/.dotfiles-update-optout" ]]; then
    continue
  fi

  USER_REPO="$USER_HOME/.dotfiles"
  if [[ -d "$USER_REPO" ]]; then
    if ! [[ -f "$USER_REPO/MANAGED" ]]; then
      continue
    fi

    USER_REV=$(cd "$USER_REPO" && git rev-parse HEAD || echo "<err>")
    if [[ "$USER_REV" == "$PKG_REV" ]] && !((FORCE)); then
      continue
    fi

    echo "Updating $USER_REPO (previous HEAD: $USER_REV)"
    (set -x; rm -rf "$USER_REPO")
  else
    echo "Creating $USER_REPO"
  fi

  (set -x; sudo -u "$USER" git clone --shared "$PKG_REPO" "$USER_REPO")

  sudo -u "$USER" touch "$USER_REPO/MANAGED"
  echo "$MANAGED_MSG" >"$USER_REPO/MANAGED"

  rm -rf "$USER_REPO/.git/hooks"

  if ! (set -x; cd "$USER_REPO"; sudo -u "$USER" /bin/bash "$USER_REPO/setup.sh"); then
    echo "Warning: $USER_REPO/setup.sh failed"
    continue
  fi
done

# Update /etc/skel/
SKEL_REV=$(cd /etc/skel/.dotfiles && git rev-parse HEAD || echo "<err>")
if [[ "$SKEL_REV" != "$PKG_REV" ]]; then
  echo "Regenerating /etc/skel/"
  rm -rf /etc/skel_new
  mkdir -p -m 0755 /etc/skel_new
  USER_REPO=/etc/skel_new/.dotfiles
  git clone --shared "$PKG_REPO" "$USER_REPO"
  echo "$MANAGED_MSG" >"$USER_REPO/MANAGED"
  mkdir -p -m 0755 "$USER_REPO/.git/info"
  echo "MANAGED" >"$USER_REPO/.git/info/ignore"
  chown -R nobody:nogroup /etc/skel_new
  if ! (set -x; sudo -u nobody bash -c 'export HOME=/etc/skel_new; $HOME/.dotfiles/setup.sh'); then
    echo "Warning: /etc/skel_new/.dotfiles/setup.sh failed"
    rm -rf /etc/skel_new
    continue
  fi
  chown -R root:root /etc/skel_new
  rm -rf /etc/skel
  mv /etc/skel_new /etc/skel
  echo "Moved /etc/skel_new/ -> /etc/skel/"
fi
