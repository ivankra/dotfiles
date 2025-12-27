-- TODO: consider heirline.lua - clickable GUI

-- LazyVim formatting helper function
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/util/lualine.lua
local function format_hl(component, text, hl_group)
  text = text:gsub("%%", "%%%%")
  if not hl_group or hl_group == "" then
    return text
  end

  component.hl_cache = component.hl_cache or {}
  local lualine_hl_group = component.hl_cache[hl_group]

  if not lualine_hl_group then
    local utils = require("lualine.utils.utils")
    local gui = vim.tbl_filter(function(x)
      return x
    end, {
      utils.extract_highlight_colors(hl_group, "bold") and "bold",
      utils.extract_highlight_colors(hl_group, "italic") and "italic",
    })

    lualine_hl_group = component:create_hl({
      fg = utils.extract_highlight_colors(hl_group, "fg"),
      gui = #gui > 0 and table.concat(gui, ",") or nil,
    }, "LV_" .. hl_group)
    component.hl_cache[hl_group] = lualine_hl_group
  end

  return component:format_hl(lualine_hl_group) .. text .. component:get_default_hl()
end

local function ll_pretty_path()
  return function(self)
    local path = vim.fn.expand("%:p")
    if path == "" then
      return ""
    end

    -- Make path relative to cwd
    local cwd = vim.fn.getcwd()
    if path:find(cwd, 1, true) == 1 then
      path = path:sub(#cwd + 2)
    end

    local sep = package.config:sub(1, 1)
    local parts = vim.split(path, "[\\/]")

    -- Shorten path with ellipsis if needed (show first + last 3)
    local max_parts = 3
    if #parts > max_parts then
      parts = { parts[1], "…", unpack(parts, #parts - max_parts + 2, #parts) }
    end

    -- Format filename with bold highlighting
    if vim.bo.modified then
      parts[#parts] = parts[#parts] .. ""
      parts[#parts] = format_hl(self, parts[#parts], "MatchParen")
    else
      parts[#parts] = format_hl(self, parts[#parts], "Bold")
    end

    -- Format directory
    local dir = ""
    if #parts > 1 then
      dir = table.concat({ unpack(parts, 1, #parts - 1) }, sep)
      dir = dir .. sep
    end

    -- Add readonly indicator
    local readonly = ""
    if vim.bo.readonly then
      readonly = format_hl(self, " 󰌾 ", "MatchParen")
    end

    return dir .. parts[#parts] .. readonly
  end
end

local mode_map = {
  ["n"]      = "N",        -- NORMAL
  ["no"]     = "OP",       -- O-PENDING
  ["nov"]    = "OP",       -- O-PENDING
  ["noV"]    = "OP",       -- O-PENDING
  ["no\22"]  = "OP",       -- O-PENDING
  ["niI"]    = "N",        -- NORMAL
  ["niR"]    = "N",        -- NORMAL
  ["niV"]    = "N",        -- NORMAL
  ["nt"]     = "N",        -- NORMAL
  ["ntT"]    = "N",        -- NORMAL
  ["v"]      = "V",        -- VISUAL
  ["vs"]     = "V",        -- VISUAL
  ["V"]      = "VL",       -- V-LINE
  ["Vs"]     = "VL",       -- V-LINE
  ["\22"]    = "VB",       -- V-BLOCK
  ["\22s"]   = "VB",       -- V-BLOCK
  ["s"]      = "S",        -- SELECT
  ["S"]      = "SL",       -- S-LINE
  ["\19"]    = "SB",       -- S-BLOCK
  ["i"]      = "I",        -- INSERT
  ["ic"]     = "I",        -- INSERT
  ["ix"]     = "I",        -- INSERT
  ["R"]      = "R",        -- REPLACE
  ["Rc"]     = "R",        -- REPLACE
  ["Rx"]     = "R",        -- REPLACE
  ["Rv"]     = "VR",       -- V-REPLACE
  ["Rvc"]    = "VR",       -- V-REPLACE
  ["Rvx"]    = "VR",       -- V-REPLACE
  ["c"]      = "C",        -- COMMAND
  ["cv"]     = "EX",       -- EX
  ["ce"]     = "EX",       -- EX
  ["r"]      = "R",        -- REPLACE
  ["rm"]     = "MORE",     -- MORE
  ["r?"]     = "CONFIRM",  -- CONFIRM
  ["!"]      = "SH",       -- SHELL
  ["t"]      = "T",        -- TERMINAL
}

local function ll_mode()
  local mode_code = vim.api.nvim_get_mode().mode
  return mode_map[mode_code] or mode_code
end

local function ll_hex_char()
  local res = vim.api.nvim_eval_statusline("0x%02B", {}).str
  if res == "0x00" then
    return "    "
  else
    return res
  end
end

local function ll_encoding()
  local enc = vim.bo.fenc or vim.o.encoding
  local ff = vim.bo.fileformat
  local ff_icon = { unix = "", dos = "  ", mac = "  " }
  return string.format("%s%s", enc, ff_icon[ff] or ff)
end

local function ll_location()
  return vim.api.nvim_eval_statusline("%2l:%-2c", {}).str
end

local function min_width(width)
  return function()
    local w = vim.o.laststatus == 3 and vim.o.columns or vim.fn.winwidth(0)
    return w >= width
  end
end

local function max_width(width)
  return function()
    local w = vim.o.laststatus == 3 and vim.o.columns or vim.fn.winwidth(0)
    return w <= width
  end
end

return {
  {
    "nvim-lualine/lualine.nvim",
    dev = true,
    dependencies = { vim.g.icons_provider },
    opts = {
      options = {
        theme = 'auto',
        component_separators = { left = "", right = "" },
        globalstatus = true,
      },
      sections = {
        lualine_a = {
          { "mode" },
        },
        lualine_b = {
          { "branch", icon = "", cond = min_width(100) },
        },
        lualine_c = {
          -- { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
          { ll_pretty_path() },
        },
        lualine_x = {
          { "diagnostics", cond = min_width(100) },
          { "diff", cond = min_width(100) },
          { ll_hex_char, cond = min_width(80) },
          { ll_encoding, cond = min_width(60) },
          -- { "filetype", icons_enabled = false, cond = min_width(60) },
          { "filetype", cond = min_width(60) },
        },
        lualine_y = {
          { "progress", cond = min_width(60) },
        },
        lualine_z = {
          { ll_location, cond = min_width(40) },
        },
      },
    }
  }
}
