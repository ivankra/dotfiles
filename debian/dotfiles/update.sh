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

PKG_DIR="/usr/local/share/dotfiles"
PKG_REPO="$PKG_DIR/dotfiles.git"
if ! [[ -d "$PKG_REPO" ]]; then
  echo "Missing $PKG_REPO"
  exit 1
fi

if [[ $UID != 0 ]]; then
  echo "Must be run under root"
  exit 1;
fi

if ! grep -qF "$PKG_REPO" /etc/gitconfig 2>/dev/null; then
  git config --system --add safe.directory "$PKG_REPO"
fi

# Checkout shared submodule working trees from packaged bare repos.
# User repos' third_party/ symlinks will be repointed to these.
for sm_git in "$PKG_DIR"/modules/*.git; do
  [[ -d "$sm_git" ]] || continue
  sm_name="$(basename "$sm_git" .git)"
  sm_wt="$PKG_DIR/modules/$sm_name"
  sm_tmp="$PKG_DIR/modules/$sm_name.tmp"

  # Skip if already checked out
  [[ -d "$sm_wt" ]] && continue

  if ! grep -qF "$sm_git" /etc/gitconfig 2>/dev/null; then
    git config --system --add safe.directory "$sm_git"
  fi

  echo "Checking out $sm_name"
  rm -rf "$sm_tmp"
  if ! git clone -q -b dotfiles "$sm_git" "$sm_tmp" 2>/dev/null; then
    echo "Warning: failed to checkout $sm_name"
    continue
  fi
  rm -rf "$sm_tmp/.git"
  mv "$sm_tmp" "$sm_wt"
done

FORCE=0
if [[ "$#" != 0 && ("$1" == "-f" || "$1" == "--force") ]]; then
  FORCE=1
fi

PKG_REV=$(cd "$PKG_REPO" && git show-ref --hash refs/tags/dotfiles)

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
    if [[ "$USER_REV" != "$PKG_REV" ]] || ((FORCE)); then
      echo "Updating $USER_REPO (previous HEAD: $USER_REV)"
      (set -x; rm -rf "$USER_REPO")
    fi
  else
    echo "Creating $USER_REPO"
  fi

  if ! [[ -d "$USER_REPO" ]]; then
    (set -x; sudo -u "$USER" git clone --shared -b dotfiles "$PKG_REPO" "$USER_REPO")
  fi

  # Repoint third_party/ symlinks from ../modules/<name> to shared checkouts
  for link in "$USER_REPO"/third_party/*; do
    [[ -L "$link" ]] || continue
    target="$(readlink "$link")"
    if [[ "$target" =~ ^\.\.\/modules\/([^/]+)/?$ ]]; then
      sm_name="${BASH_REMATCH[1]}"
      sm_wt="$PKG_DIR/modules/$sm_name"
      if [[ -d "$sm_wt" ]]; then
        rm "$link"
        sudo -u "$USER" ln -s "$sm_wt" "$link"
      fi
    fi
  done

  # Fresh clone: create MANAGED, remove hooks, run setup
  if ! [[ -f "$USER_REPO/MANAGED" ]]; then
    sudo -u "$USER" tee "$USER_REPO/MANAGED" >/dev/null <<<"$MANAGED_MSG"

    rm -rf "$USER_REPO/.git/hooks"

    if ! (set -x; cd "$USER_REPO"; sudo -u "$USER" /bin/bash "$USER_REPO/setup.sh"); then
      echo "Warning: $USER_REPO/setup.sh failed"
      continue
    fi
  fi
done

# Update /etc/skel/
SKEL_REV=$(cd /etc/skel/.dotfiles && git rev-parse HEAD || echo "<err>")
if [[ "$SKEL_REV" != "$PKG_REV" ]]; then
  echo "Regenerating /etc/skel/"
  rm -rf /etc/skel_new
  mkdir -p -m 0755 /etc/skel_new
  USER_REPO=/etc/skel_new/.dotfiles
  git clone --shared -b dotfiles "$PKG_REPO" "$USER_REPO"

  # Repoint third_party/ symlinks from ../modules/<name> to shared checkouts
  for link in "$USER_REPO"/third_party/*; do
    [[ -L "$link" ]] || continue
    target="$(readlink "$link")"
    if [[ "$target" =~ ^\.\.\/modules\/([^/]+)/?$ ]]; then
      sm_name="${BASH_REMATCH[1]}"
      sm_wt="$PKG_DIR/modules/$sm_name"
      if [[ -d "$sm_wt" ]]; then
        rm "$link"
        ln -s "$sm_wt" "$link"
      fi
    fi
  done

  echo "$MANAGED_MSG" >"$USER_REPO/MANAGED"
  mkdir -p -m 0755 "$USER_REPO/.git/info"
  echo "MANAGED" >"$USER_REPO/.git/info/exclude"
  chown -R nobody:nogroup /etc/skel_new
  if ! (set -x; sudo -u nobody bash -c 'export HOME=/etc/skel_new; $HOME/.dotfiles/setup.sh'); then
    echo "Warning: /etc/skel_new/.dotfiles/setup.sh failed"
    rm -rf /etc/skel_new
  else
    chown -R root:root /etc/skel_new
    rm -rf /etc/skel
    mv /etc/skel_new /etc/skel
    echo "Moved /etc/skel_new/ -> /etc/skel/"
  fi
fi
