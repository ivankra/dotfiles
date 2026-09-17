local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

config.adjust_window_size_when_changing_font_size = false
config.audible_bell = 'Disabled'
config.check_for_updates = false
config.color_scheme = 'Dracula (Official)'
config.default_cursor_style = 'SteadyBlock'
config.font = wezterm.font('Iosevka', { weight = 'Medium' })
config.font_size = 12.0
config.inactive_pane_hsb = { brightness = 0.7 }
config.initial_cols = 120
config.initial_rows = 40
config.scrollback_lines = 1000000
config.use_resize_increments = true
config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE'
config.window_padding = { left = '2px', right = '2px', top = '10px', bottom = '2px' }

local is_mac = wezterm.target_triple:find('darwin') ~= nil

-- Tab bar font; macOS sizes render smaller, and SF Pro is only there if
-- installed from Apple's developer site
local tab_font = wezterm.font('Noto Sans')
local tab_font_size = 10.0
if is_mac then
  tab_font = wezterm.font_with_fallback({ 'SF Pro Text', 'Helvetica Neue' })
  tab_font_size = 13.0
  config.font_size = 14.0  -- as in iterm2/dark.json
end

-- macOS keeps its native traffic-light buttons (the default there)
if not is_mac then
  -- Needs debian/wezterm/01-gnome-hidpi.patch to be sized right on HiDPI
  config.integrated_title_button_style = 'Gnome'
end

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
config.window_frame = {
  font = tab_font,
  font_size = tab_font_size,
  active_titlebar_bg = chrome.bg,
  inactive_titlebar_bg = chrome.bg,
  active_titlebar_fg = dracula.fg,
  inactive_titlebar_fg = dracula.comment,
  button_bg = chrome.bg,
  button_fg = dracula.fg,
  button_hover_bg = chrome.edge,
  button_hover_fg = dracula.fg,
  border_left_width = '2px',
  border_right_width = '2px',
  border_bottom_height = '2px',
  border_left_color = dracula.bg,
  border_right_color = dracula.bg,
  border_bottom_color = dracula.bg,
}
config.tab_max_width = 32
config.colors = {
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
}

-- Roomier tab labels
wezterm.on('format-tab-title', function(tab, _, _, _, _, max_width)
  local title = tab.tab_title
  if title == '' then
    title = tab.active_pane.title
  end
  return '   ' .. wezterm.truncate_right(title, max_width - 6) .. '   '
end)

-- Ctrl+PgUp/PgDn switch tabs, but reach the app when there's only one tab
local function switch_tab_or_send(key, delta)
  return {
    key = key,
    mods = 'CTRL',
    action = wezterm.action_callback(function(window, pane)
      if #window:mux_window():tabs() > 1 then
        window:perform_action(act.ActivateTabRelative(delta), pane)
      else
        window:perform_action(act.SendKey { key = key, mods = 'CTRL' }, pane)
      end
    end),
  }
end
config.keys = {
  switch_tab_or_send('PageUp', -1),
  switch_tab_or_send('PageDown', 1),
}

-- Open links with Ctrl+click only; a plain click just selects
config.mouse_bindings = {
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'NONE',
    action = act.CompleteSelection 'PrimarySelection',
  },
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'CTRL',
    action = act.OpenLinkAtMouseCursor,
  },
  -- Swallow the press so programs with mouse reporting (e.g. nvim) don't see it
  {
    event = { Down = { streak = 1, button = 'Left' } },
    mods = 'CTRL',
    action = act.Nop,
  },
}

return config
