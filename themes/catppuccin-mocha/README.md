# catppuccin-mocha

- `../../third_party/catppuccin.vim/colors/catppuccin_mocha.vim` ([upstream](https://github.com/catppuccin/vim/blob/ee7d87e1c3f753069dae41df139f7d3fd914f7e9/colors/catppuccin_mocha.vim), [MIT](https://github.com/catppuccin/vim/blob/ee7d87e1c3f753069dae41df139f7d3fd914f7e9/LICENSE))
- `alacritty.toml` ([upstream](https://github.com/catppuccin/alacritty/blob/f6cb5a5c2b404cdaceaff193b9c52317f62c62f7/catppuccin-mocha.toml), [MIT](https://github.com/catppuccin/alacritty/blob/f6cb5a5c2b404cdaceaff193b9c52317f62c62f7/LICENSE))
- `gedit.xml` ([upstream](https://github.com/catppuccin/gedit/blob/c118958d28298d80c869f06d4b8a794df9e0c2c5/themes/catppuccin-mocha.xml), [MIT](https://github.com/catppuccin/gedit/blob/c118958d28298d80c869f06d4b8a794df9e0c2c5/LICENSE))
  - Note: uses the gedit 46+ format.
- `gnome-terminal.dconf` ([upstream](https://github.com/catppuccin/gnome-terminal/blob/75e57457f58a34baf2ec7d9e13556ca53d598395/install.py), [MIT](https://github.com/catppuccin/gnome-terminal/blob/75e57457f58a34baf2ec7d9e13556ca53d598395/LICENSE))
  - Generated profile: matches the installer’s Mocha keys and UUID.
  - Reference: [palette.json](https://github.com/catppuccin/palette/blob/v1.7.1/palette.json)
- `guake.dconf`: converted from `gnome-terminal.dconf`.
- `kitty.conf` ([upstream](https://github.com/catppuccin/kitty/blob/43098316202b84d6a71f71aaf8360f102f4d3f1a/themes/mocha.conf), [MIT](https://github.com/catppuccin/kitty/blob/43098316202b84d6a71f71aaf8360f102f4d3f1a/LICENSE))
  - Tweak: normal font styles for active/inactive tabs.
- `tmux.conf`
  - Local layout and color assignments using the Mocha palette.
  - Overlay0 pane border, lavender active border and mauve session accent follow the reference; mantle status background and surface1 current-window background are local choices.
  - Reference: [catppuccin_options_tmux.conf](https://github.com/catppuccin/tmux/blob/d2d25bd3393fe43f19eb4fff6cdd2bdf5578e622/catppuccin_options_tmux.conf)
- `wezterm.lua`
  - Selects the built-in `Catppuccin Mocha` scheme; titlebar, borders and tab bar use local Mocha assignments.
