-- Dracula with local tweaks, run by nvim/lua/plugins/colorscheme.lua
-- Colors from vim/colors/dracula-dark.vim, an overlay on third_party/dracula.vim
-- Local preference: disable italics.
vim.g.dracula_italic = 0
-- dracula-dark isn't in dracula.vim's colors/, so lazy.nvim won't load it on demand
require("lazy").load({ plugins = { "dracula.vim" } })
vim.cmd.colorscheme("dracula-dark")
