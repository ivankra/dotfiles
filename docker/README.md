# docker

Containerized editors and coding agents.

Each subdirectory is one docker image, named after the image it builds.

Agents:
  * [`agents-base`](agents-base/): base image, Debian sid with dev tools
  * [`agy`](agy/): [Antigravity CLI](https://antigravity.google/product/antigravity-cli), Google's replacement for the deprecated Gemini CLI
  * [`claude`](claude/): [Claude Code](https://claude.ai/code)
  * [`codex`](codex/): [Codex](https://github.com/openai/codex)
  * [`kimi`](kimi/): [Kimi Code](https://www.kimi.com/code/en)
  * [`opencode`](opencode/): [opencode](https://github.com/sst/opencode)
  * [`qodercli`](qodercli/): [Qoder CLI](https://qoder.com)

Editors:
  * [`editors-base`](editors-base/): base image, Debian sid with IDE tooling, LSPs etc.
  * [`dvim`](dvim/): dockerized NeoVim for trying out new plugins
  * [`nvim-lazy`](nvim-lazy/): [LazyVim](https://github.com/LazyVim/LazyVim), popular lazy.nvim-based NeoVim configuration
  * [`nvim-kickstart`](nvim-kickstart/): [Kickstart](https://github.com/nvim-lua/kickstart.nvim), minimalist educational NeoVim configuration
  * [`nvim-astro`](nvim-astro/): [AstroNvim](https://github.com/AstroNvim/AstroNvim), feature-rich NeoVim configuration
  * [`nvim-lunar`](nvim-lunar/): [LunarVim](https://github.com/LunarVim/LunarVim), feature-rich NeoVim configuration
  * [`nvim-chad`](nvim-chad/): [NvChad](https://github.com/NvChad/NvChad), feature-rich NeoVim configuration
  * [`doom-emacs`](doom-emacs/): [Doom Emacs](https://github.com/doomemacs/doomemacs)
  * [`spacemacs`](spacemacs/): [Spacemacs](https://github.com/syl20bnr/spacemacs)
  * [`helix`](helix/): [Helix](https://github.com/helix-editor/helix), kakoune/neovim-inspired modal text editor written in Rust. Feature-rich experience out of the box, LSP, tree-sitter, multiple cursors.

GUI apps:
  * [`cursor`](cursor/): [Cursor](https://www.cursor.com), AI-powered VS Code fork.
  * [`logseq`](logseq/): [Logseq](https://github.com/logseq/logseq)
  * [`vscode`](vscode/): [Visual Studio Code](https://code.visualstudio.com)
  * [`zed`](zed/): [Zed](https://github.com/zed-industries/zed), collaborative code editor built in Rust, GPU-accelerated GUI (Vulkan), integration with AI agents.

## Running

Run `make` in a subdirectory to build an image and install its launcher
script/symlink into `~/.local/bin/<image>`.
Most launchers make use of `dr` script (see below).

`podman` is recommended over `docker` for better rootless mode and DX.

To persist state / downloaded plugins, the images map the container's
`/root` directory to `~/.docker/<launcher>` on the host. An image can have
several launchers (`LAUNCHERS` in its Makefile, e.g. `claude claude2`), each
a symlink named after its variant with its own `/root`.

GUI editors are messier to sandbox via docker (Flatpak does it
better). For `cursor` and `vscode`, `run.sh` runs podman as root in
the container, and the alternative `run-x11docker.sh` goes through the
[x11docker](https://github.com/mviereck/x11docker) wrapper instead.
`zed` needs the GPU, so its `run.sh` is x11docker-based.

## dr

`dr` is a standalone script essentially wrapping
`docker run --rm -it -v $PWD:$PWD -w $PWD`
(using `podman`, `docker`, Apple's `container`, whichever is available)
to run a container with bind-mounted current directory.

Useful directly, for anything not worth a directory here:

```sh
$ dr debian:sid bash
$ dr -p 8080:8080 docker.io/library/nginx
```

## Portability

This directory is self-contained, most stuff should work independently
of dotfiles repo. Except for `dvim`: its `run.sh` copies `~/.dotfiles`
into the container and runs `setup.sh` there.
