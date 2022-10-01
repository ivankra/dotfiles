#!/bin/bash
# dejavu: checks out browser directories from ~/.dejavu.git into tmpfs at
# /run/user/$UID/dejavu on startup, updates symlinks.

set -e -o pipefail

export HOME=${HOME:-/home/$USER}
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/run/user/$UID}

REPO="$HOME/.dejavu.git"
WORKTREE="$XDG_RUNTIME_DIR/dejavu"

setup_link() {
  TARGET="$1"
  LINK="$2"

  # Dummy file instead of directory disables linking that directory
  if [[ -f "$TARGET" ]]; then
    echo "Target $TARGET disabled"
    if [[ -L "$LINK" && "$LINK" -ef "$TARGET" ]]; then
      rm -f "$LINK"
      echo "Removed link $LINK"
      mkdir -p "$LINK"
      chmod 0700 "$LINK"
    fi
    return 0
  fi

  mkdir -p "$TARGET"
  chmod 0700 "$TARGET"

  # Create/fix link
  if [[ -L "$LINK" ]]; then
    if ! [[ "$TARGET/" -ef "$LINK/" ]]; then
      rm -f "$LINK"
      ln -s "$TARGET" "$LINK"
      echo "Created link: $LINK -> $TARGET"
    fi
  else
    rm -rf "$LINK"
    mkdir -p "$(basename "$LINK")"
    ln -s "$TARGET" "$LINK"
    echo "Replaced $LINK with a link: $LINK -> $TARGET"
  fi
}

startup() {
  if ! [[ -d "$REPO" ]]; then
    echo "Error: $REPO does not exist"
    exit 1
  fi

  if ! [[ -d "$XDG_RUNTIME_DIR" ]]; then
    echo "Error: $$XDG_RUNTIME_DIR ($XDG_RUNTIME_DIR) does not exist"
    exit 1
  fi

  chmod 0700 "$REPO"
  cd "$REPO"

  rm -rf "$WORKTREE"
  git worktree prune
  git worktree add "$WORKTREE" master

  chmod 0700 "$WORKTREE"

  if ! [[ -f "$WORKTREE/.gitignore" ]]; then
    echo "cache" >>"$WORKTREE/.gitignore"
  fi

  #setup_link "$WORKTREE/cache" "$HOME/.cache"
  setup_link "$WORKTREE/chromium" "$HOME/.config/chromium"
  setup_link "$WORKTREE/google-chrome" "$HOME/.config/google-chrome"
  setup_link "$WORKTREE/mozilla" "$HOME/.mozilla"

  # Symlinking keyrings directory causes problems, copy it instead
  if [[ -d "$WORKTREE/keyrings" ]]; then
    rm -rf "$HOME/.local/share/keyrings"
    mkdir -m 0700 -p "$HOME/.local/share"
    cp -a "$WORKTREE/keyrings" "$HOME/.local/share/"
    chmod og-rwx "$HOME/.local/share/keyrings"
    ln -sf "$WORKTREE/keyrings" "$HOME/.local/share/keyrings/git"
    echo "Copied keyrings into ~/.local/share/keyrings"
  fi

  if [[ -x "$WORKTREE/startup.sh" ]]; then
    bash "$WORKTREE/startup.sh"
  elif [[ -x ~/.dotfiles/services/dejavu/startup.sh ]]; then
    bash ~/.dotfiles/services/dejavu/startup.sh
  fi
}

startup
