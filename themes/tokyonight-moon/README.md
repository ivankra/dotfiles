# tokyonight-moon

The terminal files, `wezterm` and `vim` are symlinks into `third_party/tokyonight.nvim`.

- `alacritty.toml` ([upstream](https://github.com/folke/tokyonight.nvim/blob/cdc07ac78467a233fd62c493de29a17e0cf2b2b6/extras/alacritty/tokyonight_moon.toml), [Apache-2.0](https://github.com/folke/tokyonight.nvim/blob/cdc07ac78467a233fd62c493de29a17e0cf2b2b6/LICENSE))
- `gnome-terminal.dconf` ([upstream](https://github.com/folke/tokyonight.nvim/blob/cdc07ac78467a233fd62c493de29a17e0cf2b2b6/extras/gnome_terminal/tokyonight_moon.dconf), [Apache-2.0](https://github.com/folke/tokyonight.nvim/blob/cdc07ac78467a233fd62c493de29a17e0cf2b2b6/LICENSE))
  - `<PROFILE_UUID>` replaced by a fixed UUID.
- `guake.dconf`: converted from `gnome-terminal.dconf`.
- `kitty.conf` ([upstream](https://github.com/folke/tokyonight.nvim/blob/cdc07ac78467a233fd62c493de29a17e0cf2b2b6/extras/kitty/tokyonight_moon.conf), [Apache-2.0](https://github.com/folke/tokyonight.nvim/blob/cdc07ac78467a233fd62c493de29a17e0cf2b2b6/LICENSE))
- `tmux.conf` ([upstream](https://github.com/folke/tokyonight.nvim/blob/cdc07ac78467a233fd62c493de29a17e0cf2b2b6/extras/tmux/tokyonight_moon.tmux), [Apache-2.0](https://github.com/folke/tokyonight.nvim/blob/cdc07ac78467a233fd62c493de29a17e0cf2b2b6/LICENSE))
- `vim` ([upstream](https://github.com/folke/tokyonight.nvim/tree/cdc07ac78467a233fd62c493de29a17e0cf2b2b6/extras/vim), [Apache-2.0](https://github.com/folke/tokyonight.nvim/blob/cdc07ac78467a233fd62c493de29a17e0cf2b2b6/LICENSE))
- `wezterm` ([upstream](https://github.com/folke/tokyonight.nvim/tree/cdc07ac78467a233fd62c493de29a17e0cf2b2b6/extras/wezterm), [Apache-2.0](https://github.com/folke/tokyonight.nvim/blob/cdc07ac78467a233fd62c493de29a17e0cf2b2b6/LICENSE))
- `wezterm.lua`
  - Selects `tokyonight_moon` from `wezterm/`
  - Local titlebar/border assignments use the Moon palette.
