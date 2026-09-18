# dracula-custom

Custom Dracula variant with background `#22212c`, foreground `#ffffff`.

- `../../third_party/dracula.vim/autoload/dracula_custom.vim` ([upstream](https://github.com/dracula/vim/blob/d4b0823100c702af127cba8dd5595a8f599041ec/autoload/dracula.vim), [MIT](https://github.com/dracula/vim/blob/d4b0823100c702af127cba8dd5595a8f599041ec/LICENSE)).
  - Tweaks: namespace `dracula_custom#palette`; true-color foreground `#ffffff`, background/bgdark `#22212c`, bgdarker `#000000`.
  - Adds palette entries for comments `#8095d6`, line numbers `#414d71`, `NonText` `#4c4f5d` and staged files `#43cc65`.
  - Original ANSI terminal colors and existing 256-color fallback indices are retained.
- `../../third_party/dracula.vim/colors/dracula-custom.vim` ([upstream](https://github.com/dracula/vim/blob/d4b0823100c702af127cba8dd5595a8f599041ec/colors/dracula.vim), [MIT](https://github.com/dracula/vim/blob/d4b0823100c702af127cba8dd5595a8f599041ec/LICENSE)).
  - Tweaks: scheme name `dracula-custom`, palette namespace `dracula_custom#palette`, italics off by default.
  - Comments use `#8095d6`, line numbers `#414d71`, and `NonText` `#4c4f5d`; `CursorLineNr` uses foreground, and `TabLineSel` uses background-colored text on `#6272a4`.
  - Adds nvim-tree/mini.icons highlights: staged files `#43cc65`, tree indent markers `#6272a4`.
- `../../third_party/lualine.nvim/lua/lualine/themes/dracula.lua` ([upstream](https://github.com/nvim-lualine/lualine.nvim/blob/221ce6b2d999187044529f49da6554a92f740a96/lua/lualine/themes/dracula.lua), [MIT](https://github.com/nvim-lualine/lualine.nvim/blob/221ce6b2d999187044529f49da6554a92f740a96/LICENSE)).
- `alacritty.toml`
  - Imports Dracula; overrides primary background, cursor text, footer background, hint-start foreground and hint-end background with `#22212c`.
- `gnome-terminal.dconf`
  - Local UUID/name, background `#22212c`, foreground `#ffffff`, dimmer ANSI palette.
  - Uses default bold-color behavior.
- `guake.dconf`
  - Guake palette from [Dracula](../dracula/README.md).
  - Background changed to `#22212c`.
- `kitty.conf`
  - Includes Dracula; overrides terminal background with `#22212c`.
- `ptyxis.palette` ([upstream](https://gitlab.gnome.org/chergert/ptyxis/-/blob/50.1/src/palettes/dracula.palette), [GPL-3.0-or-later](https://gitlab.gnome.org/chergert/ptyxis/-/blob/50.1/COPYING)).
  - Tweaks: name `Dracula Custom`, dark background `#22212c`, dark foreground/cursor `#ffffff`.
- `tmux.conf`
  - Sources Dracula; overrides copy-mode foreground, status background and session-label foreground with `#22212c`.
- `wezterm.lua`
  - Loads Dracula; overrides terminal background and three window-border colors with `#22212c`.
  - Titlebar, tabs and selection remain inherited, including selection foreground `#282a36`.
