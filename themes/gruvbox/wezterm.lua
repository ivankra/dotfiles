-- Gruvbox Dark Hard colors, loaded by wezterm.lua
-- Terminal colors from kitty.conf (kitty-themes gruvbox-dark-hard),
-- window chrome from the gruvbox palette (https://github.com/morhetz/gruvbox)
local gb = {
  bg0_h = '#1d2021',
  bg0 = '#282828',
  bg0_s = '#32302f',
  bg1 = '#3c3836',
  bg2 = '#504945',
  gray = '#928374',
  fg1 = '#ebdbb2',
}

return {
  colors = {
    foreground = gb.fg1,
    background = gb.bg0_h,
    cursor_bg = '#bdae93',
    cursor_fg = '#665c54',
    cursor_border = '#bdae93',
    selection_fg = gb.fg1,
    selection_bg = '#d65d0e',
    ansi = { '#3c3836', '#cc241d', '#98971a', '#d79921', '#458588', '#b16286', '#689d6a', '#a89984' },
    brights = { '#928374', '#fb4934', '#b8bb26', '#fabd2f', '#83a598', '#d3869b', '#8ec07c', '#fbf1c7' },
    tab_bar = {
      inactive_tab_edge = gb.bg2,
      active_tab = { bg_color = gb.bg1, fg_color = gb.fg1 },
      inactive_tab = { bg_color = gb.bg0, fg_color = gb.gray },
      inactive_tab_hover = { bg_color = gb.bg0_s, fg_color = gb.gray },
      new_tab = { bg_color = gb.bg0, fg_color = gb.gray },
      new_tab_hover = { bg_color = gb.bg0_s, fg_color = gb.fg1 },
    },
  },
  window_frame = {
    active_titlebar_bg = gb.bg0,
    inactive_titlebar_bg = gb.bg0,
    active_titlebar_fg = gb.fg1,
    inactive_titlebar_fg = gb.gray,
    button_bg = gb.bg0,
    button_fg = gb.fg1,
    button_hover_bg = gb.bg1,
    button_hover_fg = gb.fg1,
    border_left_color = gb.bg0_h,
    border_right_color = gb.bg0_h,
    border_bottom_color = gb.bg0_h,
  },
}
