-- Dracula colors, loaded by wezterm.lua
-- Scheme 'Dracula (Official)' is built into wezterm, as recommended by
-- https://github.com/dracula/wezterm
-- Tweak theming to match Ptyxis in Dracula colors
local dracula = {
  bg = '#282a36',
  fg = '#f8f8f2',
  comment = '#6272a4',
}
local chrome = {
  bg = '#2d303f',
  tab = '#373a48',
  hover = '#333645',
  edge = '#3c3f4d',
}

return {
  color_scheme = 'Dracula (Official)',
  window_frame = {
    active_titlebar_bg = chrome.bg,
    inactive_titlebar_bg = chrome.bg,
    active_titlebar_fg = dracula.fg,
    inactive_titlebar_fg = dracula.comment,
    button_bg = chrome.bg,
    button_fg = dracula.fg,
    button_hover_bg = chrome.edge,
    button_hover_fg = dracula.fg,
    border_left_color = dracula.bg,
    border_right_color = dracula.bg,
    border_bottom_color = dracula.bg,
  },
  colors = {
    -- Inverse-style selection
    selection_fg = dracula.bg,
    selection_bg = dracula.fg,
    tab_bar = {
      inactive_tab_edge = chrome.edge,
      active_tab = { bg_color = chrome.tab, fg_color = dracula.fg },
      inactive_tab = { bg_color = chrome.bg, fg_color = dracula.comment },
      inactive_tab_hover = { bg_color = chrome.tab, fg_color = dracula.comment },
      new_tab = { bg_color = chrome.bg, fg_color = dracula.comment },
      new_tab_hover = { bg_color = chrome.hover, fg_color = dracula.fg },
    },
  },
}
