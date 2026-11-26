# dvim

Dockerized Neovim with my dotfiles config for trying out new plugins
without touching the host setup.

`make` builds the image and links these launchers into `~/.local/bin`, all
pointing at `run.sh`. Each one loads a different plugin set:

  * `dvim`: IDE-like setup with treesitter and mason
  * `dvim-obsidian`: [obsidian.nvim](https://github.com/obsidian-nvim/obsidian.nvim), with `$PWD` as the vault
  * `dvim-snacks`: [snacks.nvim](https://github.com/folke/snacks.nvim)'s file explorer instead of nvim-tree
  * `dvim-neotree`: [neo-tree](https://github.com/nvim-neo-tree/neo-tree.nvim) instead of nvim-tree
  * `dvim-claudecode`: `dvim` plus [claudecode.nvim](https://github.com/coder/claudecode.nvim), Claude Code in a split (keys under `<leader>a`); see below

Unlike the other images here, dvim is not standalone. It runs the regular
nvim config from [`../../nvim`](../../nvim), with extra plugins layered on
top:

  * `run.sh` mounts the host's `~/.dotfiles` at `~/.dotfiles` as an overlay
    (writes dropped on exit), with the volume `dr-<name>` as the container's
    `$HOME`. On first run of each launcher it runs `setup.sh` there, which
    links `nvim/` to `~/.config/nvim` etc., the same as on the host.
  * `nvim/init.lua` sets `vim.g.in_container`. Outside a container,
    lazy.nvim loads plugins only from the `third_party/` submodules and never
    fetches. Inside a container, it falls back to git and installs any
    missing plugins, so the first start of nvim downloads everything.
  * `nvim/lua/plugins/dvim.lua` is a symlink to [`dvim.lua`](dvim.lua), so
    lazy.nvim picks it up along with the other plugin specs. On the host it
    returns `{}`. In the container it reads the hostname, which `run.sh` sets
    to the launcher name, and returns that variant's plugins.

Host edits to the dotfiles apply on the next start. State, i.e. setup.sh's
links and the plugins lazy.nvim installed, stays in the volume `dr-<name>`,
so later runs start straight away. To start over (or rerun `setup.sh`), run
`podman volume rm dr-<name>`.

## dvim-claudecode

Runs the [`claude`](../claude) image (build it there) with its volume
`dr-claude` as `$HOME`, so Claude's login is shared. No `setup.sh` there:
only `~/.config/nvim` is linked.
