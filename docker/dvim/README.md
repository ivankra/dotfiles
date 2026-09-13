# dvim

Dockerized Neovim with my dotfiles config for trying out new plugins
without touching the host setup.

`make` builds the image and links these launchers into `~/.local/bin`, all
pointing at `run.sh`. Each one loads a different plugin set:

  * `dvim`: IDE-like setup (treesitter, mason, lspconfig, conform, blink.cmp, gitsigns)
  * `dvim-neorg`: [neorg](https://github.com/nvim-neorg/neorg)
  * `dvim-org`: [orgmode](https://github.com/nvim-orgmode/orgmode) + [org-roam](https://github.com/chipsenkbeil/org-roam.nvim)
  * `dvim-oxide`: [markdown-oxide](https://github.com/Feel-ix-343/markdown-oxide) LSP
  * `dvim-obsidian`: [obsidian.nvim](https://github.com/obsidian-nvim/obsidian.nvim), with `$PWD` as the vault

Unlike the other images here, dvim is not standalone. It runs the regular
nvim config from [`../../nvim`](../../nvim), with extra plugins layered on
top:

  * On first run of each launcher, `run.sh` copies `~/.dotfiles` into
    `~/.docker/<name>`, which is mounted as the container's `$HOME`, and runs
    `setup.sh` there. That links `nvim/` to `~/.config/nvim`, the same
    as on the host.
  * `nvim/init.lua` sets `vim.g.in_container`. Outside a container,
    lazy.nvim loads plugins only from the `third_party/` submodules and never
    fetches. Inside a container, it falls back to git and installs any
    missing plugins, so the first start of nvim downloads everything.
  * `nvim/lua/plugins/dvim.lua` is a symlink to [`dvim.lua`](dvim.lua), so
    lazy.nvim picks it up along with the other plugin specs. On the host it
    returns `{}`. In the container it reads the hostname, which `run.sh` sets
    to the launcher name, and returns that variant's plugins.

State, including the dotfiles copy and the plugins lazy.nvim installed, stays
in `~/.docker/<name>`, so later runs start straight away. Changes to the
dotfiles on the host don't reach that copy. To pick them up, delete
`~/.docker/<name>`, and the next run sets it up again from scratch.
