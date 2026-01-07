# dotfiles package

Builds and installs a Debian package that automatically
manages `~/.dotfiles` updates for all users on the system.

Run `make` or `./build.sh` to build .deb from live `~/.dotfiles`
on the current system. Submodules must be initialized locally
before build.

## Overview

```
~/.dotfiles                 # source directory on dev machine
  ├── modules/<name>/       # git submodules (neovim plugins etc)
  └── third_party/<name> -> ../modules/<name>   # symlinks for neovim etc

    ↓ build.sh

/usr/local/share/dotfiles/
  ├── dotfiles.git          # bare repo, shallow, HEAD -> "dotfiles" tag
  └── modules/<name>.git    # bare repos for each submodule

    ↓ update.sh (postinst, systemd service)

/usr/local/share/dotfiles/
  └── modules/<name>/       # shared working tree checkouts, no .git

~/.dotfiles (per user)      # mutable checkout with git clone --shared
  ├── .git/                 # uses alternates to dotfiles.git
  └── third_party/<name> -> /usr/local/share/dotfiles/modules/<name>
  └── MANAGED               # permits automated updates, delete to opt out

```

## build.sh

Creates `dotfiles_<version>_all.deb` from live `~/.dotfiles` and its
submodules on the development machine.

  1. Clones `~/.dotfiles` as a shallow bare repo to `dotfiles.git`
  2. Tags HEAD as `dotfiles` to pin exact git commit to check out
  3. Clones each submodule from `modules/<name>` as `modules/<name>.git`
    - All submodules must be at `modules/<name>` in the repo
  4. Includes Firefox policies.json for system-wide install as well
  5. Creates DEBIAN control files, systemd service.
  6. Package version: `YYYYMMDD.HHMM.<commit-hash-8>`

## update.sh

Runs as root on target system (via postinst and systemd service).

  1. **Checks out shared submodules** (once per package install)
    - `modules/<name>.git` -> `modules/<name>/` (working tree, .git removed)
    - These are read-only, shared by all users

  2. **Per-user setup**
    - For each user:
      - UID >= 1000 or root
      - shell not `/bin/false` or `*nologin`
      - Home directory exists
      - Not opted out with `~/.dotfiles-update-optout` or by pre-existing `~/.dotfiles/` without `~/.dotfiles/MANAGED`.
    - Clone `dotfiles.git` with `--shared` (uses git alternates, saves space)
    - Repoint `third_party/*` symlinks from `../modules/<name>` to `/usr/local/share/dotfiles/modules/<name>`
    - Run user's `setup.sh`

  3. **Update /etc/skel/** for new user creation

## Misc notes

`/usr/local/share/dotfiles/` is read-only after install (postinst).
Except `modules/` dir stays writable for checkout on first run.

`file://` prefix for clones: `git clone --depth=1` ignores depth
for local paths; `file://` forces protocol that respects it.

`dotfiles` tag: reliable reference for shallow clones. Branch names
can be ambiguous, tag is explicit.

Why `third_party/*/` symlinks? Git doesn't like replacing submodules
with symlinks in `modules/`, hence an extra indirection with symlinks in
`third_party/` is required.
