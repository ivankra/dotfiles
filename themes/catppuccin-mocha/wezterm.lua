-- Catppuccin Mocha colors, loaded by wezterm.lua
-- Scheme is built into wezterm (https://github.com/catppuccin/wezterm),
-- window chrome uses mantle/surface colors; see README.md for local assignments
local mocha = {
  base = '#1e1e2e',
  mantle = '#181825',
  crust = '#11111b',
  surface0 = '#313244',
  surface1 = '#45475a',
  overlay1 = '#7f849c',
  text = '#cdd6f4',
}

return {
  color_scheme = 'Catppuccin Mocha',
  window_frame = {
    active_titlebar_bg = mocha.mantle,
    inactive_titlebar_bg = mocha.mantle,
    active_titlebar_fg = mocha.text,
    inactive_titlebar_fg = mocha.overlay1,
    button_bg = mocha.mantle,
    button_fg = mocha.text,
    button_hover_bg = mocha.surface0,
    button_hover_fg = mocha.text,
    border_left_color = mocha.base,
    border_right_color = mocha.base,
    border_bottom_color = mocha.base,
  },
  colors = {
    tab_bar = {
      inactive_tab_edge = mocha.surface0,
      active_tab = { bg_color = mocha.surface1, fg_color = mocha.text },
      inactive_tab = { bg_color = mocha.mantle, fg_color = mocha.overlay1 },
      inactive_tab_hover = { bg_color = mocha.surface0, fg_color = mocha.overlay1 },
      new_tab = { bg_color = mocha.mantle, fg_color = mocha.overlay1 },
      new_tab_hover = { bg_color = mocha.surface0, fg_color = mocha.text },
    },
  },
}
