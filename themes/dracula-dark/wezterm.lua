-- Dracula with local tweaks, loaded by wezterm.lua
-- Background #21222c
local wezterm = require 'wezterm'
local theme = dofile(wezterm.home_dir .. '/.dotfiles/themes/dracula/wezterm.lua')

local bg = '#21222c'
theme.colors.background = bg
theme.window_frame.border_left_color = bg
theme.window_frame.border_right_color = bg
theme.window_frame.border_bottom_color = bg
return theme
