# sonokai

Sonokai, `default` style. Terminal colors come from alacritty-theme's `sonokai.toml`, whose ANSI mapping matches sonokai's own terminal colors (blue as color 4, orange as color 6); the other terminals are converted from `alacritty.toml`.

- `../../third_party/sonokai/colors/sonokai.vim` ([upstream](https://github.com/sainnhe/sonokai/blob/b023c5280b16fe2366f5e779d8d2756b3e5ee9c3/colors/sonokai.vim), [MIT](https://github.com/sainnhe/sonokai/blob/b023c5280b16fe2366f5e779d8d2756b3e5ee9c3/LICENSE))
  - `vim.vim`/`nvim.lua`: `default` style, italic comments disabled.
- `alacritty.toml` ([upstream](https://github.com/alacritty/alacritty-theme/blob/ab88d5a80d676b5dc6157e91aba8067f2078dc94/themes/sonokai.toml), [Apache-2.0](https://github.com/alacritty/alacritty-theme/blob/ab88d5a80d676b5dc6157e91aba8067f2078dc94/LICENSE))
- `gnome-terminal.dconf`: converted from `alacritty.toml`, with a fixed random profile UUID.
- `guake.dconf`: converted from `gnome-terminal.dconf`.
- `kitty.conf`: converted from `alacritty.toml`.
  - Tab bar/borders use the sonokai palette (`bg1`/`bg4`/`grey`, active border `filled_blue`); normal tab font styles.
- `ptyxis.palette`: converted from `alacritty.toml`.
  - Ptyxis' built-in `Sonokai` (from Gogh) swaps blue/orange and uses the background as color 0.
- `tmux.conf`
  - Local layout as in other themes; colors follow the author's [tmuxline config](https://github.com/sainnhe/dotfiles/blob/67f2e6a53d7577e62cfa25fdae2362d9de66fd2d/.tmux/tmuxline/sonokai.tmux.conf).
- `wezterm.lua`
  - Terminal colors from `alacritty.toml`, inline; titlebar and tab bar use `bg1`/`bg4`/`grey`.
- gedit: missing.
