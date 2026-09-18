-- Tokyo Night Moon colors, loaded by wezterm.lua
-- Scheme from tokyonight.nvim's extras via wezterm/ symlink,
-- window chrome from the moon palette (lua/tokyonight/colors/moon.lua)
local wezterm = require 'wezterm'

local moon = {
  bg = '#222436',
  bg_dark = '#1e2030',
  bg_highlight = '#2f334d',
  fg = '#c8d3f5',
  dark3 = '#545c7e',
}

return {
  color_scheme_dirs = { wezterm.home_dir .. '/.config/theme/wezterm' },
  color_scheme = 'tokyonight_moon',
  window_frame = {
    active_titlebar_bg = moon.bg_dark,
    inactive_titlebar_bg = moon.bg_dark,
    active_titlebar_fg = moon.fg,
    inactive_titlebar_fg = moon.dark3,
    button_bg = moon.bg_dark,
    button_fg = moon.fg,
    button_hover_bg = moon.bg_highlight,
    button_hover_fg = moon.fg,
    border_left_color = moon.bg,
    border_right_color = moon.bg,
    border_bottom_color = moon.bg,
  },
}
