# Containers

Containerized editors and coding agents, for playing around and for sandboxing.

Each subdirectory is one image, named after the image it builds. The two
`*-base` directories are shared foundations, not meant to be run directly.
Alongside them is [`dr`](dr), the run wrapper the agent launchers use.

## Agents

Built on `agents-base` (Debian sid with dev tools).

  * `agy`: **[Antigravity CLI](https://antigravity.google/product/antigravity-cli)**,
    Google's replacement for the deprecated Gemini CLI
  * `claude`: **[Claude Code](https://claude.ai/code)**
  * `codex`: **[Codex](https://github.com/openai/codex)**
  * `kimi`: **[Kimi Code](https://www.kimi.com/code/en)**
  * `opencode`: **[opencode](https://github.com/sst/opencode)**
  * `qodercli`: **[Qoder CLI](https://qoder.com)**

## Editors

Built on `editors-base` (Debian sid with IDE tooling, LSPs etc).

Neovim:
  * `nvim-lazy`: **[LazyVim](https://github.com/LazyVim/LazyVim)**, popular lazy.nvim-based configuration
  * `nvim-kickstart`: **[Kickstart](https://github.com/nvim-lua/kickstart.nvim)**, minimalist educational configuration
  * `nvim-astro`: **[AstroNvim](https://github.com/AstroNvim/AstroNvim)**, feature-rich configuration
  * `nvim-lunar`: **[LunarVim](https://github.com/LunarVim/LunarVim)**, feature-rich configuration
  * `nvim-chad`: **[NvChad](https://github.com/NvChad/NvChad)**, feature-rich configuration

Emacs:
  * `doom-emacs`: **[Doom Emacs](https://github.com/doomemacs/doomemacs)**
  * `spacemacs`: **[Spacemacs](https://github.com/syl20bnr/spacemacs)**

Other CLI:
  * `helix`: **[Helix](https://github.com/helix-editor/helix)**,
    kakoune/neovim-inspired modal text editor written in Rust. Feature-rich
    experience out of the box, LSP, tree-sitter, multiple cursors.

GUI:
  * `cursor`: **[Cursor](https://www.cursor.com)**, AI-powered VS Code fork.
  * `vscode`: **[Visual Studio Code](https://code.visualstudio.com)**
  * `zed`: **[Zed](https://github.com/zed-industries/zed)**, collaborative code
    editor built in Rust, GPU-accelerated GUI (Vulkan), integration with AI
    agents.

## Running

Install `podman` (better rootless mode and DX over docker) and run
`make` in a subdirectory to build an image.

`make build` also puts a launcher at `~/.local/bin/<image>`, so every
one of these is on `$PATH`: navigate to a project dir and run e.g.
`kimi` or `nvim-lazy`. No aliases needed. Two kinds:

  * **Agents** get a generated script wrapping `./dr` (itself
    a wrapper for `podman run --rm -it -v "$PWD:$PWD" -w "$PWD"`).
    Rules in `agents-base/build.mk`; a per-agent `Makefile` is
    just an `include` of it, plus an optional `ARGS :=`
    line for flags to pass to the CLI.
  * **Editors** get a symlink to the directory's `run.sh`,
    which carries the XDG/X11/GPU plumbing those images need,
    so editing a `run.sh` takes effect immediately.
    Rules in `editors-base/build.mk`; a per-editor `Makefile` is
    an `include` of it, plus an optional `BASE :=` line naming
    the image it builds on (empty for images built straight
    from a distro tag).

Every editor directory has a `run.sh`; `make build` fails without one.

Neither kind overwrites a file it did not create, so a real `claude` or
`zed` already in `~/.local/bin` is safe.

To persist state / downloaded plugins, the images map the container's
`/root` directory to `~/.docker/<image>` on the host.

This directory is self-contained: copy it anywhere and `make` works,
with no dotfiles install needed. Everything resolves relative to the
`build.mk` that is running, so launchers point back at wherever you put
it. `dvim` is the exception: its `run.sh` copies `~/.dotfiles` into the
container and runs `setup.sh` there.

GUI editors are messier to sandbox this way (Flatpak does it
better). For `cursor` and `vscode`, `run.sh` runs podman as root in
the container, and the alternative `run-x11docker.sh` goes through the
[x11docker](https://github.com/mviereck/x11docker) wrapper instead. `zed`
needs the GPU, so its `run.sh` is x11docker-based.

## dr

`dr` is a standalone Python script wrapping `podman run` (or `docker`,
or Apple's `container`, whichever is available) with the flags for
working in the current directory:

```
dr [options] [run args] IMAGE|DOCKERFILE [image args]
```

  * `--rm -it`, `$PWD` bind-mounted at the same path inside the
    container and set as the working directory
  * `.git` mounted read-only when there is one
  * a unique container name, so several can run at once
  * host directories for any `-v` created before the run, which is
    how the launchers get their `~/.docker/<image>` state dir
  * arguments split three ways: in `dr -v ~/.cache:/root/.cache myimage
    --version` the `-v` goes to podman and the `--version` to the image
  * a file instead of an image name is built as a Dockerfile first,
    then run, passing through any `--build-arg`

`dr --complete` backs the bash completion in `bashrc`, offering cached
image names plus Dockerfiles and directories in `$PWD`.

Useful directly, for anything not worth a directory here:

```sh
dr debian:sid bash
dr -p 8080:8080 docker.io/library/nginx
```

`../bin/dr` is a symlink to it, to get it on `$PATH`.
