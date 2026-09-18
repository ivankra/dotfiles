-- Sonokai colors, loaded by wezterm.lua
-- Terminal colors from alacritty.toml (alacritty-theme sonokai.toml),
-- window chrome from sonokai#get_palette('default') in third_party/sonokai
local s = {
  black = '#181819',
  bg0 = '#2c2e34',
  bg1 = '#33353f',
  bg2 = '#363944',
  bg4 = '#414550',
  fg = '#e2e2e3',
  grey = '#7f8490',
}

return {
  colors = {
    foreground = s.fg,
    background = s.bg0,
    cursor_bg = s.fg,
    cursor_fg = s.bg0,
    cursor_border = s.fg,
    selection_bg = s.bg4,
    ansi = { '#181819', '#fc5d7c', '#9ed072', '#e7c664', '#76cce0', '#b39df3', '#f39660', '#e2e2e3' },
    brights = { '#7f8490', '#fc5d7c', '#9ed072', '#e7c664', '#76cce0', '#b39df3', '#f39660', '#e2e2e3' },
    tab_bar = {
      inactive_tab_edge = s.bg4,
      active_tab = { bg_color = s.bg4, fg_color = s.fg },
      inactive_tab = { bg_color = s.bg1, fg_color = s.grey },
      inactive_tab_hover = { bg_color = s.bg2, fg_color = s.grey },
      new_tab = { bg_color = s.bg1, fg_color = s.grey },
      new_tab_hover = { bg_color = s.bg2, fg_color = s.fg },
    },
  },
  window_frame = {
    active_titlebar_bg = s.bg1,
    inactive_titlebar_bg = s.bg1,
    active_titlebar_fg = s.fg,
    inactive_titlebar_fg = s.grey,
    button_bg = s.bg1,
    button_fg = s.fg,
    button_hover_bg = s.bg4,
    button_hover_fg = s.fg,
    border_left_color = s.bg0,
    border_right_color = s.bg0,
    border_bottom_color = s.bg0,
  },
}
