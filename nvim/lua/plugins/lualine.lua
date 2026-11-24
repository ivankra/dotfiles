-- TODO: consider heirline.lua - clickable GUI

-- LazyVim formatting helper function
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/util/lualine.lua
-- hl_groups: a group, or a list of them: the first that has a fg color is
-- used (only fg is taken, and e.g. gruvbox's MatchParen is bg-only).
-- The cache is per component, and lualine recreates components on
-- ColorScheme, so the choice is made again for each scheme.
local function format_hl(component, text, hl_groups)
  text = text:gsub("%%", "%%%%")
  if type(hl_groups) == "string" then
    hl_groups = { hl_groups }
  end
  if not hl_groups or #hl_groups == 0 or hl_groups[1] == "" then
    return text
  end

  local key = table.concat(hl_groups, ",")
  component.hl_cache = component.hl_cache or {}
  local lualine_hl_group = component.hl_cache[key]

  if not lualine_hl_group then
    local utils = require("lualine.utils.utils")
    local hl_group = hl_groups[#hl_groups]
    for _, group in ipairs(hl_groups) do
      if utils.extract_highlight_colors(group, "fg") then
        hl_group = group
        break
      end
    end
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
    component.hl_cache[key] = lualine_hl_group
  end

  return component:format_hl(lualine_hl_group) .. text .. component:get_default_hl()
end

-- Bold text in the section's own colors. Not via format_hl(..., "Bold"):
-- only some colorschemes define a `Bold` group (not gruvbox/sonokai/dracula).
local function format_bold(component, text)
  text = text:gsub("%%", "%%%%")
  -- No fg/bg given, so lualine fills them in from the theme for each mode
  component.bold_hl = component.bold_hl or component:create_hl({ gui = "bold" }, "LV_Bold")
  return component:format_hl(component.bold_hl) .. text .. component:get_default_hl()
end

-- Filetypes shown as just their icon (no name) in lualine_x: the icon
-- already says what the type is, so the name would just repeat it
local icon_only_fts = {
  bash = true,       -- "$" icon
  c = true,          -- "C" icon
  cpp = true,        -- "C++" icon
  dockerfile = true, -- Docker whale
  go = true,         -- "GO" icon
  javascript = true, -- "JS" icon
  markdown = true,   -- markdown logo
  python = true,     -- Python logo
  sh = true,         -- "$" icon
  tex = true,        -- "TeX" icon
  typescript = true, -- "TS" icon
  vim = true,        -- Vim "V" logo
}

-- Modified filename / readonly icon: MatchParen's color, else (scheme gives
-- it no fg, e.g. gruvbox, nvim's default) WarningMsg's
local modified_hl = { "MatchParen", "WarningMsg" }

-- Index stages in a fugitive:// name (:help fugitive-object)
local fugitive_stages = { ["0"] = "index", ["1"] = "base", ["2"] = "ours", ["3"] = "theirs" }

-- For a fugitive:// buffer (:Gedit HEAD:%, the old side of :Gdiffsplit):
-- its revision, and the work tree file it's a version of (nil for a
-- commit/tree). Commits by short hash: the name has the hash that HEAD,
-- HEAD~1 etc. resolved to, not the ref typed.
local function fugitive_info(name)
  if not vim.startswith(name, "fugitive://") or vim.fn.exists("*FugitiveParse") == 0 then
    return nil
  end
  local ok, parsed = pcall(vim.fn.FugitiveParse, name)
  if not ok or type(parsed) ~= "table" or type(parsed[1]) ~= "string" then
    return nil
  end
  -- "<hash>:<path>", "<hash>" or ":<stage>:<path>"
  local stage, rel = parsed[1]:match("^:(%d):(.*)$")
  local rev
  if stage then
    rev = fugitive_stages[stage] or stage
  else
    local commit
    commit, rel = parsed[1]:match("^([^:]*):?(.*)$")
    rev = commit:sub(1, 7)
  end
  return rev, rel ~= "" and vim.fn.FugitiveReal(name) or nil
end

local function ll_pretty_path()
  return function(self)
    local name = vim.api.nvim_buf_get_name(0)

    -- :terminal (toggleterm's have an extension below): its title. That
    -- starts out as the term://~/dir//1234:cmd buffer name until the program
    -- sets one (bash does, htop/python don't), so then just the command.
    if vim.bo.buftype == "terminal" then
      local title = vim.b.term_title
      if not title or title == "" or vim.startswith(title, "term://") then
        title = name:match("^term://.-//%d+:(.*)$") or name
      end
      return (title:gsub("%%", "%%%%"))
    end

    -- Relative to cwd if under it, else relative to ~ if under it, else absolute
    local rev, real = fugitive_info(name)
    local path
    if rev and not real then
      return format_bold(self, "commit " .. rev)
    elseif rev then
      -- Without :p's trailing / for a tree (:Gedit HEAD:dir)
      path = vim.fn.fnamemodify(real, ":p:~:."):gsub("(.)[\\/]$", "%1")
    else
      path = vim.fn.expand("%:p:~:.")
    end
    if path == "" then
      return ""
    end

    local sep = package.config:sub(1, 1)
    local parts = vim.split(path, "[\\/]")

    -- Shorten path with ellipsis if needed (show first + … + last 2)
    local max_parts = 3
    if #parts > max_parts then
      parts = { parts[1], "…", unpack(parts, #parts - max_parts + 2, #parts) }
    end

    -- Format filename with bold highlighting.
    -- Modified buffers are shown by color only (modified_hl), no extra marker.
    if vim.bo.modified then
      parts[#parts] = format_hl(self, parts[#parts], modified_hl)
    else
      parts[#parts] = format_bold(self, parts[#parts])
    end

    -- Format directory
    local dir = ""
    if #parts > 1 then
      dir = table.concat({ unpack(parts, 1, #parts - 1) }, sep)
      -- Escape % for the statusline (the filename is escaped by format_*)
      dir = dir:gsub("%%", "%%%%") .. sep
    end

    -- Add readonly indicator
    local readonly = ""
    if vim.bo.readonly then
      readonly = format_hl(self, " 󰌾 ", modified_hl)
    end

    -- fugitive:// buffer: which version of the file this is
    if rev then
      rev = " @ " .. rev
    end

    return dir .. parts[#parts] .. (rev or "") .. readonly
  end
end

-- Short names for lualine's mode names. Its map lacks cr/cvr (command line
-- after <Insert>) and shows such codes raw, so they're named here too.
-- stylua: ignore
local mode_short = {
  NORMAL   = "N",
  VISUAL   = "V",
  INSERT   = "I",
  SHELL    = "SH",
  TERMINAL = "TERM",
  cr       = "COMMAND",
  cvr      = "EX",
}

local function ll_hex_char()
  local res = vim.api.nvim_eval_statusline("0x%02B", {}).str
  if res == "0x00" then
    return "    "
  else
    return res
  end
end

-- Only shown when unusual: non-utf-8, BOM, or non-unix line endings.
-- Returning "" makes lualine skip the component, separator and padding too.
local function ll_encoding()
  local parts = {}
  local enc = vim.bo.fenc ~= "" and vim.bo.fenc or vim.o.encoding
  if enc ~= "utf-8" or vim.bo.bomb then
    table.insert(parts, enc .. (vim.bo.bomb and "-bom" or ""))
  end
  local ff = vim.bo.fileformat
  if ff ~= "unix" then
    local ff_icon = { dos = "", mac = "" }
    table.insert(parts, ff_icon[ff] or ff)
  end
  return table.concat(parts, " ")
end

-- %v: screen column, not %c's byte column (2x on Cyrillic text)
local function ll_location()
  return vim.api.nvim_eval_statusline("%2l:%-2v", {}).str
end

local function min_width(width)
  return function()
    local w = vim.o.laststatus == 3 and vim.o.columns or vim.fn.winwidth(0)
    return w >= width
  end
end

return {
  {
    "nvim-lualine/lualine.nvim",
    dev = true,
    -- Unless heirline's is used instead (init.lua). A function: checked
    -- after all of lua/plugins/ is read, so dvim.lua can switch it.
    cond = function()
      return vim.g.statusline_plugin == "lualine"
    end,
    dependencies = { vim.g.icons_provider },
    opts = {
      options = {
        theme = 'auto',
        component_separators = { left = "", right = "" },
        globalstatus = true,
      },
      -- Own statusline for these windows (by filetype) instead of the
      -- sections below, whose path would show e.g. oil:///home/...
      extensions = { "oil", "nvim-tree", "toggleterm", "fugitive", "lazy", "quickfix", "man" },
      sections = {
        lualine_a = {
          {
            "mode",
            fmt = function(mode)
              return mode_short[mode] or mode
            end,
          },
        },
        lualine_b = {
          { "branch", icon = "", cond = min_width(100) },
        },
        lualine_c = {
          -- { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
          { ll_pretty_path() },
        },
        lualine_x = {
          -- Narrowing hides the least useful first: hex code, then
          -- branch/diff (100), diagnostics last of these
          { "diagnostics", cond = min_width(70) },
          {
            "diff",
            cond = min_width(100),
            -- gitsigns' counts: live, unsaved changes too. lualine's own runs
            -- git diff on the saved file, only on save and buffer switch.
            source = function()
              local g = vim.b.gitsigns_status_dict
              if g then
                return { added = g.added, modified = g.changed, removed = g.removed }
              end
            end,
          },
          { ll_hex_char, cond = min_width(120) },
          { ll_encoding, cond = min_width(60) },
          -- { "filetype", icons_enabled = false, cond = min_width(60) },
          {
            "filetype",
            cond = min_width(60),
            -- Common types: icon only. fmt runs before apply_icon(), so
            -- toggle icon_only per buffer (returning "" would drop the icon too)
            fmt = function(ft, self)
              self.options.icon_only = icon_only_fts[ft] == true
              return ft
            end,
          },
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
