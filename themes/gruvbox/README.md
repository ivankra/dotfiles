# gruvbox

Gruvbox dark, hard contrast (background `#1d2021`). Terminal colors come from kitty-themes' `gruvbox-dark-hard`; the other terminals are converted from `kitty.conf`.

- `../../third_party/gruvbox.vim/colors/gruvbox.vim` ([upstream](https://github.com/morhetz/gruvbox/blob/5d15b2765f59754d7ac263c88a0f6e3e58124951/colors/gruvbox.vim), [MIT](https://github.com/gruvbox-community/gruvbox/blob/180ad85971343df68be3422a5630fa84e45a9ab2/LICENSE.md))
  - `vim.vim` sets `g:gruvbox_contrast_dark = 'hard'` and disables italic comments, matching the gruvbox.nvim options in `nvim/lua/plugins/colorscheme.lua`.
  - MIT per upstream's README; the license text is from the maintained gruvbox-community fork by the same author.
- `alacritty.toml`: converted from `kitty.conf`.
- `gedit.xml` ([upstream](https://github.com/morhetz/gruvbox-contrib/blob/150e9ca30fcd679400dc388c24930e5ec8c98a9f/gedit/gruvbox-dark.xml), [LGPL-2.1](https://gitlab.gnome.org/GNOME/gtksourceview/-/blob/5.18.0/COPYING))
  - Tweaks: gedit 46+ format, id/name `gruvbox-dark-hard`, text background `dark0_hard`.
- `gnome-terminal.dconf`: converted from `kitty.conf`, with a fixed random profile UUID.
- `guake.dconf`: converted from `gnome-terminal.dconf`.
- `kitty.conf` ([upstream](https://github.com/kovidgoyal/kitty-themes/blob/b95a97da1fad87263452590d74212499bd120de7/themes/gruvbox-dark-hard.conf), [MIT](https://github.com/gruvbox-community/gruvbox/blob/180ad85971343df68be3422a5630fa84e45a9ab2/LICENSE.md))
  - Tweak: normal font styles for active/inactive tabs.
- `ptyxis.palette` ([upstream](https://gitlab.gnome.org/chergert/ptyxis/-/blob/50.1/src/palettes/Gruvbox.palette))
  - Ptyxis' built-in `Gruvbox` is medium contrast; tweaks: name, `[Dark]` replaced with `kitty.conf` colors.
- `tmux.conf`
  - Local layout as in other themes, in the gruvbox palette; orange session accent matches kitty's active tab.
- `wezterm.lua`
  - Terminal colors from `kitty.conf`, inline rather than a built-in scheme name.
  - Titlebar and tab bar use gruvbox `bg0`/`bg1`/`gray`.
