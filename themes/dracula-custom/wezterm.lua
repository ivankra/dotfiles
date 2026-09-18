-- Dracula with local tweaks, loaded by wezterm.lua
-- Background #22212c
local wezterm = require 'wezterm'
local theme = dofile(wezterm.home_dir .. '/.dotfiles/themes/dracula/wezterm.lua')

local bg = '#22212c'
theme.colors.background = bg
theme.window_frame.border_left_color = bg
theme.window_frame.border_right_color = bg
theme.window_frame.border_bottom_color = bg
return theme
