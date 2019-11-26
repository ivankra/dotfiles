#!/bin/bash
# Create ~/.dotfiles directory for all users, cloning from system repository
# installed by dotfiles package. If directory exists and HEAD does not match
# system repository's revision, it will be erased and cloned from scratch.
# Setup script is re-run on update for each user under the user's account.
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

PKG_REV=$(cd "$PKG_REPO" && git show-ref --hash refs/heads/master)

for USER in $(getent passwd | cut -d : -f 1); do
  if [[ "$USER" != "root" && "$(id -u "$USER" || echo 0)" -lt 1000 ]]; then
    continue
  fi

  USER_SHELL="$(getent passwd "$USER" | cut -d : -f 7)"
  if [[ "$USER_SHELL" == "/bin/false" || "$USER_SHELL" == *nologin ]]; then
    continue
  fi

  USER_HOME="$(getent passwd "$USER" | cut -d : -f 6)"
  if [[ -f "$USER_HOME/.dotfiles-update-optout" || ! -d "$USER_HOME" ]]; then
    continue
  fi

  USER_REPO="$USER_HOME/.dotfiles"
  if [[ -d "$USER_REPO" ]]; then
    if ! [[ -f "$USER_REPO/MANAGED" ]]; then
      continue
    fi

    USER_REV=$(cd "$USER_REPO" && git rev-parse HEAD || echo "<err>")
    if [[ "$USER_REV" == "$PKG_REV" ]]; then
      continue
    fi

    echo "Updating $USER_REPO (previous HEAD: $USER_REV)"
    (set -x; rm -rf "$USER_REPO")
  else
    echo "Creating $USER_REPO"
  fi

  (set -x; sudo -u "$USER" git clone --shared "$PKG_REPO" "$USER_REPO")

  sudo -u "$USER" touch "$USER_REPO/MANAGED"
  echo "This repository is managed by /usr/local/share/dotfiles/update.sh script. Local changes will be lost. Delete this file to prevent automatic updates." >"$USER_REPO/MANAGED"

  rm -rf "$USER_REPO/.git/hooks"

  if ! (set -x; sudo -u "$USER" /bin/bash "$USER_REPO/setup.sh"); then
    echo "Warning: $USER_REPO/setup.sh failed"
    continue
  fi
done
