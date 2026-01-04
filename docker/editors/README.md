# Editors

Containerized code editors for playing around.

Neovim:
  * **[LazyVim](https://github.com/LazyVim/LazyVim)**: popular lazy.nvim-based configuration
  * **[Kickstart](https://github.com/nvim-lua/kickstart.nvim)**: minimalist educational configuration
  * **[AstroNvim](https://github.com/AstroNvim/AstroNvim)**: feature-rich configuration
  * **[LunarVim](https://github.com/LunarVim/LunarVim)**: feature-rich configuration
  * **[NvChad](https://github.com/NvChad/NvChad)**: feature-rich configuration

Emacs:
  * **[Doom Emacs](https://github.com/doomemacs/doomemacs)**
  * **[Spacemacs](https://github.com/syl20bnr/spacemacs)**

Other CLI:
  * **[Helix](https://github.com/helix-editor/helix)**: kakoune/neovim-inspired modal text editor written in Rust. Feature-rich experience out of the box, LSP, tree-sitter, multiple cursors.

GUI:
  * **[Cursor](https://www.cursor.com)**: AI-powered VS Code fork.
  * **[Zed](https://github.com/zed-industries/zed)**: collaborative code editor built in Rust, GPU-accelerated GUI (Vulkan), integration with AI agents.

## Running

Install `podman` (better rootless mode and DX over docker) and run `make` in a subdirectory to build a docker image.

Works best with CLI editors: with `alias dr='podman run --rm -it -v "$PWD:$PWD" -w "$PWD"'` in bashrc, you can navigate to a project dir and run e.g. `dr lazyvim`. Alternatively, use `run.sh` scripts. Copy/symlink to it somewhere in `$PATH`. To persist state / downloaded plugins, they map container's `/root` directory to `~/.docker/<image>` on the host.

GUI editors are messier to run in this way (GUI sandboxing is better with Flatpak). Use `run.sh` (podman run running as root in the container) or `run-x11docker.sh` (using x11docker wrapper) to start GUI, after navigating to a project's dir.
