-- Dracula colors, loaded by wezterm.lua
-- Scheme 'Dracula (Official)' is built into wezterm, as recommended by
-- https://github.com/dracula/wezterm
-- Tweak theming to match Ptyxis in Dracula colors
local dracula = {
  bg = '#282a36',
  fg = '#f8f8f2',
}
-- WezTerm tabs touch each other (Ptyxis has gaps between them), so hover
-- is kept well below the active tab's shade to keep the two apart
local chrome = {
  bg = '#2d303f',
  tab = '#3a3d4c',
  hover = '#313443',
  edge = '#3c3f4d',
  label = '#919099',  -- neutral grey of Ptyxis's tab labels
}

return {
  color_scheme = 'Dracula (Official)',
  window_frame = {
    active_titlebar_bg = chrome.bg,
    inactive_titlebar_bg = chrome.bg,
    active_titlebar_fg = dracula.fg,
    inactive_titlebar_fg = chrome.label,
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
      inactive_tab = { bg_color = chrome.bg, fg_color = chrome.label },
      inactive_tab_hover = { bg_color = chrome.hover, fg_color = chrome.label },
      new_tab = { bg_color = chrome.bg, fg_color = chrome.label },
      new_tab_hover = { bg_color = chrome.hover, fg_color = dracula.fg },
    },
  },
}
