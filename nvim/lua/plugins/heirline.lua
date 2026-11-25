-- Experimental config by Claude with heirline.nvim replacing lualine/bufferline.
-- Conditionally enabled when vim.g.statusline_plugin = "heirline".
--
-- Statusline: lualine.lua's layout and colors (lualine's theme for the
-- colorscheme, else made from its highlight groups):
--   mode | branch | path ... diagnostics, diff, hex code, indent, encoding,
--   LSP progress, gear (server attached) + filetype icon and name (venv) |
--   progress | line:column
--   * Diff counts from gitsigns: live, unsaved changes too.
--   * LSP progress: "⠹ basedpyright: Indexing 3/10 (30%)" while a server
--     works. Indent: "␣2" spaces or "⇥4" tabs. Venv: in Python buffers.
--     Filetype name: not for c, cpp, js, ts, markdown (their icon says it),
--     but for *.h (c or cpp?).
--   * Narrow windows: parts shrink or hide by priority (path full ->
--     shortened, hex code first, diagnostics last), not at fixed widths.
--   * Own statuslines for oil, nvim-tree, toggleterm, fugitive, lazy,
--     quickfix, help, man and checkhealth windows (lualine's extensions).
--
-- Winbar: each file window's path, when a tab has more than one (the global
-- statusline only names the current window's file).
--
-- Tabline: bufferline.nvim's slant look and keys from lua/plugins/bufferline.lua
-- ([b ]b, S-PageUp/Down, A-1..0, <leader>bl/bo/br), shown with 2+ buffers or
-- tab pages (their numbers on the right); same-named files with their folder,
-- long names cut. Added: move a tab with <leader>b< / <leader>b> or by
-- dragging it; middle click closes.
--
-- Statuscolumn: as init.lua's "%3l%s". Click a git sign: the hunk inline.
--
-- Clicks: lualine.lua's handlers (branch -> git branches, diagnostics ->
-- list, diff -> :Git, menus for the path, indent and filetype/servers); a
-- split's winbar path, for that window.
--
-- Without a Nerd Font (vim.g.nerd_font off: Linux console): plain characters,
-- as lualine.lua's and bufferline.lua's.
--
-- vim.g.statusline_plugin: "lualine" in init.lua, "heirline" in the dvim and
-- dvim-heirline containers (docker/dvim/dvim.lua). lualine.lua and
-- bufferline.lua skip their specs then. The conditions are functions:
-- checked after all of lua/plugins/ is read.

local nf = vim.g.nerd_font

-- Nerd Font glyph, else (Linux console) plain text: lualine.lua's and
-- bufferline.lua's fallbacks
local function g(codepoint, plain)
  return nf and vim.fn.nr2char(codepoint) or plain
end

-- stylua: ignore
local icons = {
  sep_left  = g(0xe0b0, ""), -- lualine's section separators
  sep_right = g(0xe0b2, ""),
  branch    = nf and g(0xe725) .. " " or "",
  lsp       = g(0xf013), -- gear, as lualine's lsp_status
  lock      = g(0xf033e, "[RO]"),
  dos       = g(0xe70f, "dos"),
  mac       = g(0xe711, "mac"),
  error     = nf and g(0xf015a) .. " " or "E:", -- lualine's diagnostics symbols
  warn      = nf and g(0xf002a) .. " " or "W:",
  info      = nf and g(0xf02fd) .. " " or "I:",
  hint      = nf and g(0xf0336) .. " " or "H:",
}

-- Escape % for the statusline (heirline doesn't)
local function esc(s)
  return (s:gsub("%%", "%%%%"))
end

---------------------------------------------------------------------------
-- Mode

-- Mode code -> name: lualine's, the frequent ones shortened as in lualine.lua
-- stylua: ignore
local mode_names = {
  n = "N", niI = "N", niR = "N", niV = "N", nt = "N", ntT = "N",
  no = "O-PENDING", nov = "O-PENDING", noV = "O-PENDING", ["no\22"] = "O-PENDING",
  v = "V", vs = "V", V = "V-LINE", Vs = "V-LINE", ["\22"] = "V-BLOCK", ["\22s"] = "V-BLOCK",
  s = "SELECT", S = "S-LINE", ["\19"] = "S-BLOCK",
  i = "I", ic = "I", ix = "I",
  R = "REPLACE", Rc = "REPLACE", Rx = "REPLACE", r = "REPLACE",
  Rv = "V-REPLACE", Rvc = "V-REPLACE", Rvx = "V-REPLACE",
  c = "COMMAND", cr = "COMMAND", cv = "EX", cvr = "EX", ce = "EX",
  rm = "MORE", ["r?"] = "CONFIRM", ["!"] = "SH", t = "TERM",
}

-- Mode name -> lualine theme section, as lualine's highlight.lua (else normal)
-- stylua: ignore
local mode_theme_keys = {
  I = "insert",
  V = "visual", ["V-LINE"] = "visual", ["V-BLOCK"] = "visual",
  SELECT = "visual", ["S-LINE"] = "visual", ["S-BLOCK"] = "visual",
  REPLACE = "replace", ["V-REPLACE"] = "replace",
  COMMAND = "command", EX = "command", MORE = "command", CONFIRM = "command",
  TERM = "terminal",
}

local function mode_info()
  local code = vim.api.nvim_get_mode().mode
  local name = mode_names[code] or code
  return name, mode_theme_keys[name] or "normal"
end

---------------------------------------------------------------------------
-- Colors: lualine's theme for the colorscheme, else made from its groups

-- Highlight group's color as "#rrggbb", following links and 'reverse'
local function hl_color(name, attr)
  local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
  if hl.reverse then
    hl.fg, hl.bg = hl.bg, hl.fg
  end
  return hl[attr] and string.format("#%06x", hl[attr]) or nil
end

-- Normal's background, else black/white by 'background' (transparent schemes)
local function normal_bg()
  return hl_color("Normal", "bg") or (vim.o.background == "dark" and "#000000" or "#ffffff")
end

-- The theme lualine's "auto" would use: lua/lualine/themes/<colorscheme>.lua.
-- Colorschemes ship some (tokyonight, catppuccin, ...), nvim/lua/lualine/
-- themes/ has one, and lualine itself the rest (gruvbox, dracula, ...): its
-- dir isn't on 'runtimepath' with lualine off, so it's added to
-- package.path, just while loading the theme.
local function lualine_theme(name)
  if not name then
    return nil
  end
  local mod = "lualine.themes." .. name
  local saved_path = package.path
  local dev_path = require("lazy.core.config").options.dev.path
  package.path = dev_path .. "/lualine.nvim/lua/?.lua;" .. package.path
  package.loaded[mod] = nil -- reload: e.g. tokyonight's depends on 'background'
  local ok, theme = pcall(require, mod)
  package.path = saved_path
  if ok and type(theme) == "table" and type(theme.normal) == "table" then
    return theme
  end
end

-- Theme for colorschemes without one (unokai, nvim's default): mode colors
-- from syntax groups, the rest from StatusLine/CursorLine
local function derived_theme()
  local bg = normal_bg()
  local b = { fg = hl_color("Normal", "fg"), bg = hl_color("CursorLine", "bg") or hl_color("Visual", "bg") }
  local c = { fg = hl_color("StatusLine", "fg"), bg = hl_color("StatusLine", "bg") }
  local function mode(group)
    return { a = { fg = bg, bg = hl_color(group, "fg"), gui = "bold" }, b = b, c = c }
  end
  return {
    normal = mode("Function"),
    insert = mode("String"),
    visual = mode("Statement"),
    replace = mode("Constant"),
    command = mode("Type"),
    terminal = mode("String"),
  }
end

local theme

local function load_theme()
  theme = lualine_theme(vim.g.colors_name) or derived_theme()
end

-- Colors of section "a"/"b"/"c" in a mode, as a heirline hl table
local function section(mode_key, name)
  local colors = (theme[mode_key] or {})[name] or theme.normal[name] or {}
  return { fg = colors.fg, bg = colors.bg, bold = colors.gui and colors.gui:find("bold") ~= nil or nil }
end

-- hl function for a section, in the current mode (the root sets mode_key)
local function sec(name)
  return function(self)
    return section(self.mode_key, name)
  end
end

-- Powerline arrows between sections, colored as lualine's: the glyph in
-- section fg_sec's background, over bg_sec's
local function arrow(glyph, fg_sec, bg_sec)
  return {
    provider = glyph,
    hl = function(self)
      return { fg = section(self.mode_key, fg_sec).bg, bg = section(self.mode_key, bg_sec).bg, bold = false }
    end,
  }
end

local function sep_left(from, to)
  return arrow(icons.sep_left, from, to)
end

local function sep_right(from, to)
  return arrow(icons.sep_right, to, from)
end

local redrawstatus = vim.schedule_wrap(function()
  vim.cmd.redrawstatus()
end)

-- A group's fg, bold and italic, nothing if the scheme lacks it: how
-- lualine.lua styles text in a group (LazyVim's helper). Its fg as is, not
-- swapped for 'reverse' as hl_color(), as lualine reads it.
local function group_style(name)
  local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
  return { fg = hl.fg and string.format("#%06x", hl.fg), bold = hl.bold, italic = hl.italic }
end

-- Modified filename / readonly icon: MatchParen, else (scheme gives it no
-- fg, e.g. gruvbox, nvim's default) WarningMsg. As lualine.lua.
local function modified_style()
  return group_style(group_style("MatchParen").fg and "MatchParen" or "WarningMsg")
end

---------------------------------------------------------------------------
-- Data, as lualine.lua's components

local function git_branch()
  local head = vim.b.gitsigns_head
  -- Not a file in a repo (e.g. [No Name]): the cwd's, as lualine's branch
  if (head == nil or head == "") and vim.fn.exists("*FugitiveHead") == 1 then
    head = vim.fn.FugitiveHead(7)
  end
  return head ~= "" and head or nil
end

-- Index stages in a fugitive:// name (:help fugitive-object)
local fugitive_stages = { ["0"] = "index", ["1"] = "base", ["2"] = "ours", ["3"] = "theirs" }

-- For a fugitive:// buffer: its revision, and the work tree file it's a
-- version of (nil for a commit/tree). As lualine.lua's.
local function fugitive_info(name)
  if not vim.startswith(name, "fugitive://") or vim.fn.exists("*FugitiveParse") == 0 then
    return nil
  end
  local ok, parsed = pcall(vim.fn.FugitiveParse, name)
  if not ok or type(parsed) ~= "table" or type(parsed[1]) ~= "string" then
    return nil
  end
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

-- The command in a term://dir//pid:cmd buffer name
local function term_cmd(name)
  return name:match("^term://.-//%d+:(.*)$") or name
end

-- The current buffer's name as parts for the path component:
-- { dir = "nvim/lua/plugins/", short_dir = "nvim/…/plugins/", file = "lualine.lua",
--   rev = "ed3e07a" (fugitive) }; dir and short_dir empty for terminals etc.
local function path_parts()
  local name = vim.api.nvim_buf_get_name(0)

  -- :terminal: its title, else (still the term:// name) the command
  if vim.bo.buftype == "terminal" then
    local title = vim.b.term_title
    if not title or title == "" or vim.startswith(title, "term://") then
      title = term_cmd(name)
    end
    return { dir = "", short_dir = "", file = title }
  end

  local rev, real = fugitive_info(name)
  local path
  if rev and not real then
    return { dir = "", short_dir = "", file = "commit " .. rev, commit = true }
  elseif rev then
    path = vim.fn.fnamemodify(real, ":p:~:."):gsub("(.)[\\/]$", "%1")
  else
    -- Relative to cwd if under it, else relative to ~ if under it, else absolute
    path = vim.fn.expand("%:p:~:.")
  end
  if path == "" then
    return { dir = "", short_dir = "", file = "[No Name]" }
  end

  local sep = package.config:sub(1, 1)
  local parts = vim.split(path, "[\\/]")
  local file = table.remove(parts)
  local dir = #parts > 0 and table.concat(parts, sep) .. sep or ""
  -- Shortened: first + … + last, when that's actually shorter
  local short_dir = dir
  if #parts > 2 then
    short_dir = table.concat({ parts[1], "…", parts[#parts] }, sep) .. sep
  end
  return { dir = dir, short_dir = short_dir, file = file, rev = rev }
end

-- Language servers' work in progress (indexing, loading the workspace, ...),
-- from LspProgress events (config below): { [client_id .. ":" .. token] =
-- { name, title, message, percentage, time } }. Not vim.lsp.status(): it
-- consumes the messages.
local lsp_progress = {}
local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
local spinner_ms = 120 -- per frame
local spinner_timer

-- Animate the spinner while there's any progress, redrawing ~8 times a second
local function update_spinner_timer()
  if next(lsp_progress) and not spinner_timer then
    spinner_timer = vim.uv.new_timer()
    spinner_timer:start(0, spinner_ms, redrawstatus)
  elseif not next(lsp_progress) and spinner_timer then
    spinner_timer:stop()
    spinner_timer:close()
    spinner_timer = nil
  end
  redrawstatus()
end

local function on_lsp_progress(ev)
  local params = ev.data and ev.data.params
  local value = params and params.value
  if type(value) ~= "table" then
    return
  end
  local key = ev.data.client_id .. ":" .. tostring(params.token)
  if value.kind == "end" then
    lsp_progress[key] = nil
  else
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    local p = lsp_progress[key] or { name = client and client.name or "?" }
    p.title = value.title or p.title
    p.message, p.percentage, p.time = value.message, value.percentage, vim.uv.now()
    lsp_progress[key] = p
  end
  update_spinner_timer()
end

-- The most recently updated one
local function latest_lsp_progress()
  local latest
  for _, p in pairs(lsp_progress) do
    if not latest or p.time > latest.time then
      latest = p
    end
  end
  return latest
end

-- Python virtual environment: which packages the language server sees. By
-- the name the shell prompt shows (uv's .venv: the project's), else its dir
-- name, else conda's. Python before 3.12 puts it as "(name) ".
local function python_env()
  local prompt = (vim.env.VIRTUAL_ENV_PROMPT or ""):gsub("^%((.*)%) $", "%1")
  local env = prompt ~= "" and prompt
    or vim.env.VIRTUAL_ENV and vim.fn.fnamemodify(vim.env.VIRTUAL_ENV, ":t")
    or vim.env.CONDA_DEFAULT_ENV
  return env ~= "" and env or nil
end

---------------------------------------------------------------------------
-- Components (built in config, once heirline is loaded)

-- Run fn on click, after the click is handled. minwid (optional): returns a
-- number for fn, e.g. the bar's window (click handlers run in the current
-- window, components are drawn in their own)
local function click(name, fn, minwid)
  return {
    name = "heirline_" .. name,
    minwid = minwid,
    callback = function(_, id)
      vim.schedule(function()
        fn(id)
      end)
    end,
  }
end

-- lualine.lua's click handler <name> (menus, pickers): registered as
-- require("lualine_clicks") when lazy.nvim reads lualine.lua at startup, so
-- looked up only when clicked
local function lualine_click(name)
  return function(...)
    return require("lualine_clicks")[name](...)
  end
end

local function build_statusline_winbar()
  local conditions = require("heirline.conditions")

  local Align = { provider = "%=" }

  local Mode = {
    provider = function(self)
      return " " .. self.mode_name .. " "
    end,
    hl = sec("a"),
    -- Recomputed only on mode changes. Redrawn then by one autocmd in config,
    -- not one per copy of this component (each statusline below has one).
    update = "ModeChanged",
  }

  local Branch = {
    provider = function(self)
      return " " .. icons.branch .. esc(self.branch) .. " "
    end,
    hl = sec("b"),
    on_click = click("branch", lualine_click("ll_branch_picker")),
  }

  -- Mode, then the branch if any: the arrows' colors depend on whether
  -- section b is there. Flexible: the branch goes when space runs out.
  local ModeAndBranch = {
    init = function(self)
      self.branch = git_branch()
    end,
    Mode,
    {
      fallthrough = false,
      {
        condition = function(self)
          return not self.branch
        end,
        sep_left("a", "c"),
      },
      {
        flexible = 40,
        { sep_left("a", "b"), Branch, sep_left("b", "c") },
        sep_left("a", "c"),
      },
    },
  }

  -- Path: dir (full, or shortened when space is short), file name in the
  -- scheme's Bold or the modified color, fugitive revision, readonly lock.
  -- base_hl: the winbar's colors (the statusline's come from its section).
  local function Path(base_hl)
    return {
      init = function(self)
        self.path = path_parts()
      end,
      hl = base_hl,
      -- The menu for the clicked bar's window
      on_click = click("path", lualine_click("ll_window_path_menu"), function()
        return vim.api.nvim_get_current_win()
      end),
      { provider = " " },
      {
        flexible = 30,
        {
          provider = function(self)
            return esc(self.path.dir)
          end,
        },
        {
          provider = function(self)
            return esc(self.path.short_dir)
          end,
        },
      },
      {
        provider = function(self)
          return esc(self.path.file)
        end,
        hl = function(self)
          -- The scheme's Bold (not bold if it has none), as lualine.lua. A
          -- commit's label: just bold.
          if self.path.commit then
            return { bold = true }
          end
          return vim.bo.modified and modified_style() or group_style("Bold")
        end,
      },
      {
        condition = function(self)
          return self.path.rev
        end,
        provider = function(self)
          return " @ " .. self.path.rev
        end,
      },
      {
        condition = function()
          return vim.bo.readonly
        end,
        provider = " " .. icons.lock,
        hl = function()
          return modified_style()
        end,
      },
      { provider = " " },
    }
  end

  -- Right side, in section c colors. Each one hides when space runs out,
  -- the lowest priority first.
  local function flex(priority, component)
    return { flexible = priority, component, {} }
  end

  -- Adds " <sign><n>" per nonzero count in self.counts (set by component's
  -- condition) to component, each in its group's color. items: { key, group,
  -- sign }.
  local function Counts(component, items)
    table.insert(component, { provider = " " })
    for _, item in ipairs(items) do
      local key, group, sign = unpack(item)
      table.insert(component, {
        provider = function(self)
          local n = self.counts[key]
          return n and n > 0 and sign .. n .. " " or nil
        end,
        hl = function()
          return { fg = hl_color(group, "fg") }
        end,
      })
    end
    return component
  end

  -- Not cached until diagnostics change (an update): it would keep the colors
  -- of the mode it was drawn in
  local sev = vim.diagnostic.severity
  local Diagnostics = Counts({
    condition = function(self)
      self.counts = vim.diagnostic.count(0)
      return next(self.counts) ~= nil
    end,
    on_click = click("diagnostics", lualine_click("ll_diagnostics_picker")),
  }, {
    { sev.ERROR, "DiagnosticError", icons.error },
    { sev.WARN, "DiagnosticWarn", icons.warn },
    { sev.INFO, "DiagnosticInfo", icons.info },
    { sev.HINT, "DiagnosticHint", icons.hint },
  })

  -- Live counts from gitsigns (lualine's diff only updates on save)
  local Diff = Counts({
    condition = function(self)
      local d = vim.b.gitsigns_status_dict
      self.counts = d
      return d and ((d.added or 0) + (d.changed or 0) + (d.removed or 0)) > 0
    end,
    on_click = click("diff", lualine_click("ll_git_status")),
  }, {
    { "added", "GitSignsAdd", "+" },
    { "changed", "GitSignsChange", "~" },
    { "removed", "GitSignsDelete", "-" },
  })

  -- Code of the character under the cursor (blank on an empty line)
  local HexChar = {
    provider = function()
      local res = vim.api.nvim_eval_statusline("0x%02B", {}).str
      return " " .. (res == "0x00" and "    " or res) .. " "
    end,
  }

  -- Indentation (guess-indent sets it per file): "␣2" spaces, shiftwidth
  -- wide, or "⇥4" tabs, tabstop wide. Click: menu to switch or convert.
  local Indent = {
    condition = function()
      return vim.bo.buftype == ""
    end,
    provider = function()
      if vim.bo.expandtab then
        return " ␣" .. vim.fn.shiftwidth() .. " "
      end
      return " ⇥" .. vim.bo.tabstop .. " "
    end,
    on_click = click("indent", lualine_click("ll_indent_menu")),
  }

  -- Only when unusual: non-utf-8, BOM, or non-unix line endings
  local Encoding = {
    provider = function()
      local parts = {}
      local enc = vim.bo.fenc ~= "" and vim.bo.fenc or vim.o.encoding
      if enc ~= "utf-8" or vim.bo.bomb then
        table.insert(parts, enc .. (vim.bo.bomb and "-bom" or ""))
      end
      local ff = vim.bo.fileformat
      if ff ~= "unix" then
        table.insert(parts, ({ dos = icons.dos, mac = icons.mac })[ff] or ff)
      end
      return #parts > 0 and " " .. table.concat(parts, " ") .. " " or nil
    end,
  }

  -- Language server work in progress: "⠹ basedpyright: Indexing 3/10 (30%)",
  -- shrinking to spinner and server name, then hidden, when space is short
  local function progress_text(full)
    local p = latest_lsp_progress()
    local text = spinner[math.floor(vim.uv.now() / spinner_ms) % #spinner + 1] .. " " .. p.name
    if full then
      local detail = (p.title or "") .. (p.message and " " .. p.message or "")
      text = text .. ": " .. vim.trim(detail .. (p.percentage and " (" .. p.percentage .. "%)" or ""))
      if vim.api.nvim_strwidth(text) > 50 then
        text = vim.fn.strcharpart(text, 0, 49) .. "…"
      end
    end
    return " " .. esc(text) .. " "
  end
  local LspProgress = {
    condition = function()
      return next(lsp_progress) ~= nil
    end,
    hl = function()
      return { fg = hl_color("Comment", "fg") }
    end,
    -- Shrinks only after the path shortened (30): it shows only while a
    -- server works
    flexible = 45,
    {
      provider = function()
        return progress_text(true)
      end,
    },
    {
      provider = function()
        return progress_text(false)
      end,
    },
    {},
  }

  -- The filetype's icon, then its name: not for the common ones with an
  -- icon. In Python buffers the venv the language server sees. A gear before
  -- the icon while a language server is attached. Click: the
  -- filetype menu, with the servers' entries. Narrow: just the icons, then
  -- hidden.
  local FtLsp = {
    condition = function(self)
      return self.icon and #vim.lsp.get_clients({ bufnr = 0 }) > 0
    end,
    provider = icons.lsp .. "  ", -- the icons are wider than their cell
  }
  local FtIcon = {
    condition = function(self)
      return self.icon
    end,
    -- With its space also when it's alone, as lualine's
    provider = function(self)
      return self.icon .. " "
    end,
    hl = function(self)
      return { fg = self.icon_hl and hl_color(self.icon_hl, "fg") }
    end,
  }
  local FtLabel = {
    condition = function(self)
      return self.label ~= ""
    end,
    provider = function(self)
      return esc(self.label)
    end,
  }
  local FileType = {
    condition = function()
      return vim.bo.filetype ~= ""
    end,
    init = function(self)
      local ft = vim.bo.filetype
      self.icon, self.icon_hl = nil, nil
      local ok, devicons = pcall(require, "nvim-web-devicons") -- or mini.icons' mock of it
      -- Without a Nerd Font just the name, as lualine's icons_enabled = false.
      -- By file name, else filetype, else generic: as lualine's filetype.
      if ok and nf then
        self.icon, self.icon_hl = devicons.get_icon(vim.fn.expand("%:t"))
        if not self.icon then
          self.icon, self.icon_hl = devicons.get_icon_by_filetype(ft)
        end
        if not self.icon then
          self.icon, self.icon_hl = g(0xe612), "DevIconDefault"
        end
      end
      -- No name where the icon clearly says it ("C", "JS", ...). *.h: c or cpp?
      -- As lualine.lua.
      local icon_fts = { c = true, cpp = true, javascript = true, markdown = true, typescript = true }
      local icon_only = nf and icon_fts[ft] and vim.fn.expand("%:e") ~= "h"
      local label = icon_only and "" or ft
      local env = ft == "python" and python_env()
      self.label = env and vim.trim(label .. " (" .. env .. ")") or label
    end,
    on_click = click("filetype", lualine_click("ll_filetype_menu")),
    flexible = 60,
    { { provider = " " }, FtLsp, FtIcon, FtLabel, { provider = " " } },
    { { provider = " " }, FtLsp, FtIcon, { provider = " " } },
    {},
  }

  -- Top / Bot / NN%, as lualine's progress
  local Progress = {
    provider = function()
      local cur, total = vim.fn.line("."), vim.fn.line("$")
      if cur == 1 then
        return " Top "
      elseif cur == total then
        return " Bot "
      end
      return " " .. math.floor(cur / total * 100) .. "%% "
    end,
    hl = sec("b"),
  }

  -- Line and screen column (not %c's byte column)
  local Location = { provider = " %2l:%-2v ", hl = sec("a") }

  -- Progress, then location: like the branch on the left, the arrows
  -- depend on whether progress is shown
  local ProgressAndLocation = {
    flexible = 50,
    { sep_right("c", "b"), Progress, sep_right("b", "a"), Location },
    { sep_right("c", "a"), Location },
  }

  local DefaultStatusline = {
    ModeAndBranch,
    Path(),
    Align,
    flex(70, Diagnostics),
    flex(40, Diff),
    flex(10, HexChar),
    flex(15, Indent),
    flex(35, Encoding),
    -- Language server progress right before the filetype, with its gear
    LspProgress,
    FileType,
    ProgressAndLocation,
  }

  -- Special windows: mode, then what the window is, instead of a path
  -- (lualine's extensions). label(self) -> text.
  local function Special(patterns, label)
    return {
      condition = function()
        return conditions.buffer_matches(patterns)
      end,
      Mode,
      sep_left("a", "c"),
      {
        provider = function(self)
          return " " .. esc(label(self)) .. " "
        end,
        hl = { bold = true },
      },
      Align,
      ProgressAndLocation,
    }
  end

  -- In a list for the root below: its fallthrough = false picks the first
  -- whose condition matches (a list of its own, with no condition, would
  -- always be picked)
  local special_statuslines = {
    Special({ filetype = { "^oil$" } }, function()
      local ok, oil = pcall(require, "oil")
      local dir = ok and oil.get_current_dir() or vim.api.nvim_buf_get_name(0)
      return vim.fn.fnamemodify(dir, ":~")
    end),
    Special({ filetype = { "^NvimTree$" } }, function()
      return vim.fn.fnamemodify(vim.fn.getcwd(), ":~")
    end),
    Special({ filetype = { "^toggleterm$" } }, function()
      return "ToggleTerm #" .. (vim.b.toggle_number or "?")
    end),
    Special({ filetype = { "^fugitive$" } }, function()
      return icons.branch .. (git_branch() or "") .. "  fugitive"
    end),
    Special({ filetype = { "^lazy$" } }, function()
      local stats = require("lazy").stats()
      return string.format("lazy  %d/%d plugins loaded", stats.loaded, stats.count)
    end),
    Special({ filetype = { "^qf$" } }, function()
      local is_loclist = vim.fn.getloclist(0, { filewinid = 1 }).filewinid ~= 0
      return (is_loclist and "Location List" or "Quickfix List") .. "  " .. (vim.w.quickfix_title or "")
    end),
    Special({ buftype = { "^help$" } }, function()
      return "help: " .. vim.fn.expand("%:t:r")
    end),
    Special({ filetype = { "^man$" } }, function()
      return "man: " .. vim.api.nvim_buf_get_name(0):gsub("^man://", "")
    end),
    -- Not its health:// buffer name
    Special({ filetype = { "^checkhealth$" } }, function()
      return "checkhealth"
    end),
  }

  local StatusLines = {
    -- Mode for everything below (sections' colors depend on it)
    init = function(self)
      self.mode_name, self.mode_key = mode_info()
    end,
    hl = sec("c"),
    fallthrough = false,
  }
  vim.list_extend(StatusLines, special_statuslines)
  table.insert(StatusLines, DefaultStatusline)

  local WinBar = Path(function()
    return conditions.is_active() and "WinBar" or "WinBarNC"
  end)

  return StatusLines, WinBar
end

---------------------------------------------------------------------------
-- Winbar on file windows only when there's more than one in the tab: with
-- one, the statusline already names the file.

local heirline_winbar = "%{%v:lua.require'heirline'.eval_winbar()%}"

local function file_wins()
  local wins = {}
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_win_get_config(win).relative == "" and vim.bo[buf].buftype == "" then
      wins[win] = true
    end
  end
  return wins
end

local function wants_winbar(win, wins)
  return wins[win] and vim.tbl_count(wins) > 1
end

local function update_winbars()
  local wins = file_wins()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local current = vim.api.nvim_get_option_value("winbar", { win = win, scope = "local" })
    if wants_winbar(win, wins) then
      if current ~= heirline_winbar then
        vim.api.nvim_set_option_value("winbar", heirline_winbar, { win = win, scope = "local" })
      end
    elseif current == heirline_winbar then
      vim.api.nvim_set_option_value("winbar", "", { win = win, scope = "local" })
    end
  end
end

---------------------------------------------------------------------------
-- Tabline: the buffer list, in lua/plugins/bufferline.lua's look and with its
-- keys (see the header)

-- stylua: ignore
local tab_icons = {
  -- bufferline's "slant" separators. Its sep_chars.slant lists them right
  -- one first (ui.lua: right_sep, left_sep = chars[1], chars[2]). Plain:
  -- one | between tabs, as bufferline.lua's { "|", "|" }.
  slant_left  = g(0xe0bc, ""),
  slant_right = g(0xe0be, "|"),
  close       = g(0xf0159, "×"), -- circled X (bufferline.lua: ×), then a no-break space (Tab)
  modified    = nf and "●" or "+", -- bufferline's modified_icon
  trunc_left  = g(0xf0a8, "<"),
  trunc_right = g(0xf0a9, ">"),
}

-- Listed buffers in tab order: kept order first (reordered by moving),
-- then new ones by number
local buf_order = {}

local function listed_buffers()
  local all = vim.api.nvim_list_bufs()
  local listed = {}
  for _, buf in ipairs(all) do
    listed[buf] = vim.bo[buf].buflisted or nil
  end
  local res, seen = {}, {}
  for _, buf in ipairs(vim.list_extend(vim.list_slice(buf_order), all)) do
    if listed[buf] and not seen[buf] then
      table.insert(res, buf)
      seen[buf] = true
    end
  end
  buf_order = res
  return res
end

-- Tab names: { prefix = "plugins/", name = "init.lua", suffix = " @ ed3e07a"
-- (fugitive) }. The prefix has as many parent dirs as needed to tell
-- same-named files apart (bufferline's show_duplicate_prefix).
local function tab_names(bufs)
  local parts, depth, suffix = {}, {}, {}
  for _, buf in ipairs(bufs) do
    local name = vim.api.nvim_buf_get_name(buf)
    local rev, real = fugitive_info(name)
    if vim.bo[buf].buftype == "terminal" then
      name = term_cmd(name)
    elseif rev then
      name, suffix[buf] = real or "commit", " @ " .. rev
    end
    name = name ~= "" and vim.fn.fnamemodify(name, ":~:.") or "[No Name]"
    parts[buf] = vim.split(name, "/", { trimempty = true })
    if #parts[buf] == 0 then
      parts[buf] = { name }
    end
    depth[buf] = 1
  end
  local function prefix(buf)
    local p = parts[buf]
    return table.concat(vim.list_slice(p, #p - depth[buf] + 1, #p - 1), "/") .. (depth[buf] > 1 and "/" or "")
  end
  repeat
    local by_tail, changed = {}, false
    for _, buf in ipairs(bufs) do
      -- With the fugitive suffix: it already tells the file and its version apart
      local key = prefix(buf) .. parts[buf][#parts[buf]] .. (suffix[buf] or "")
      by_tail[key] = by_tail[key] or {}
      table.insert(by_tail[key], buf)
    end
    for _, group in pairs(by_tail) do
      if #group > 1 then
        for _, buf in ipairs(group) do
          if depth[buf] < #parts[buf] then
            depth[buf] = depth[buf] + 1
            changed = true
          end
        end
      end
    end
  until not changed
  local names = {}
  for _, buf in ipairs(bufs) do
    names[buf] = { prefix = prefix(buf), name = parts[buf][#parts[buf]], suffix = suffix[buf] or "" }
  end
  return names
end

-- Cut to `limit` screen cells with "…", as bufferline: a name by dropping
-- its extension if that's enough, else at the end (truncate_name,
-- max_name_length 18); a dir prefix at the start, keeping the dirs nearest
-- the file (max_prefix_length 15)
local function truncate(s, limit, from_start)
  if vim.api.nvim_strwidth(s) <= limit then
    return s
  end
  local root = vim.fn.fnamemodify(s, ":r")
  if not from_start and root ~= s and vim.api.nvim_strwidth(root) < limit then
    return root .. "…"
  end
  local chars = vim.fn.split(s, "\\zs")
  local kept, width = {}, 0
  for i = from_start and #chars or 1, from_start and 1 or #chars, from_start and -1 or 1 do
    width = width + vim.api.nvim_strwidth(chars[i])
    if width > limit - 1 then
      break
    end
    table.insert(kept, from_start and 1 or #kept + 1, chars[i])
  end
  return from_start and "…" .. table.concat(kept) or table.concat(kept) .. "…"
end

-- What a tab shows, in order. One function for drawing and for finding the
-- tab under the mouse (tab_at), so they can't disagree.
local function tab_fields(buf, entry)
  local icon, icon_hl
  local ok, devicons = pcall(require, "nvim-web-devicons")
  if ok then
    -- By name, else (extension-less scripts like bin/git-fixup) the
    -- filetype's, else the generic one. As lua/plugins/bufferline.lua's bufferline.
    local ext = vim.fn.fnamemodify(entry.name, ":e")
    icon, icon_hl = devicons.get_icon(entry.name, ext, { default = false })
    if not icon and vim.bo[buf].filetype ~= "" then
      icon, icon_hl = devicons.get_icon_by_filetype(vim.bo[buf].filetype, { default = false })
    end
    if not icon then
      icon, icon_hl = devicons.get_icon(entry.name, ext, { default = true })
    end
  end
  return {
    icon = icon or " ",
    icon_hl = icon_hl, -- its own color, as bufferline's color_icons
    prefix = truncate(entry.prefix, 15, true),
    name = truncate(entry.name, 18) .. entry.suffix,
    state = vim.bo[buf].modified and tab_icons.modified or tab_icons.close,
  }
end

local function tab_width(f)
  local pieces = { tab_icons.slant_left, " ", f.icon, " ", f.prefix, f.name, " ", f.state, " " }
  return vim.api.nvim_strwidth(table.concat(pieces) .. tab_icons.slant_right)
end

-- nvim-tree on the left: its width is skipped, with a title (bufferline's
-- offsets). Window width + 1 for the separator column, 0 without the tree.
local function tab_offset()
  local win = vim.api.nvim_tabpage_list_wins(0)[1]
  if win and vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "NvimTree" then
    return vim.api.nvim_win_get_width(win) + 1
  end
  return 0
end

-- Position in the tab order of the tab at screen column col (1-based), nil
-- if none or heirline pages the tabs (positions unknown then): when they're
-- wider than what the offset and the tab page numbers (" 1 ", with 2+ tab
-- pages) leave, minus 2 for its arrows (heirline's _eval, page_buflist)
local function tab_at(col)
  local bufs = listed_buffers()
  local names = tab_names(bufs)
  local x = tab_offset()
  local hit
  for i, buf in ipairs(bufs) do
    local w = tab_width(tab_fields(buf, names[buf]))
    if col > x and col <= x + w then
      hit = i
    end
    x = x + w
  end
  local pages = #vim.api.nvim_list_tabpages()
  local pages_width = 0
  for nr = 1, pages > 1 and pages or 0 do
    pages_width = pages_width + #tostring(nr) + 2
  end
  return x <= vim.o.columns - pages_width - 2 and hit or nil
end

local function goto_tab(n)
  local buf = listed_buffers()[n]
  if buf then
    vim.api.nvim_set_current_buf(buf)
  end
end

local function current_tab_index()
  return vim.fn.index(listed_buffers(), vim.api.nvim_get_current_buf()) + 1 -- 0: not listed
end

local function cycle_tab(delta)
  local bufs = listed_buffers()
  local i = current_tab_index()
  if #bufs > 0 then
    goto_tab(i == 0 and 1 or (i - 1 + delta) % #bufs + 1)
  end
end

-- Move buffer buf to position `to` in the tab order
local function move_tab_to(buf, to)
  local bufs = listed_buffers()
  local from = vim.fn.index(bufs, buf) + 1
  if from == 0 or to < 1 or to > #bufs or from == to then
    return
  end
  table.remove(bufs, from)
  table.insert(bufs, to, buf)
  buf_order = bufs
  vim.cmd.redrawtabline()
end

-- Close the tabs left of / right of / other than the current one, with one
-- :Bd so Cancel on a Save prompt stops them all (as lua/plugins/bufferline.lua)
local function close_tabs(which)
  local cur = current_tab_index()
  if cur == 0 then
    return
  end
  local ids = {}
  for i, buf in ipairs(listed_buffers()) do
    if (which == "left" and i < cur) or (which == "right" and i > cur) or (which == "others" and i ~= cur) then
      table.insert(ids, buf)
    end
  end
  if #ids > 0 then
    vim.cmd("Bd " .. table.concat(ids, " "))
  end
end

-- Mouse drag of a tab: the press on a tab (its click handler) starts it,
-- <LeftDrag> on the tabline moves the tab to the one under the mouse,
-- <LeftRelease> ends it. These two keys only do that while dragging a tab,
-- else what they always do. Not <LeftMouse>: mapping it would stop
-- nvim from calling the tab's click handler.
local dragging

-- Also terminal and : line mode: a tab clicked there ends its drag there
local drag_modes = { "n", "i", "v", "t", "c" }

local function drag_keymaps()
  vim.keymap.set(drag_modes, "<LeftDrag>", function()
    if not dragging then
      return "<LeftDrag>"
    end
    local pos = vim.fn.getmousepos()
    local target = pos.screenrow == 1 and tab_at(pos.screencol)
    if target then
      move_tab_to(dragging, target)
    end
    return ""
  end, { expr = true, desc = "Drag a tab (heirline tabline)" })
  vim.keymap.set(drag_modes, "<LeftRelease>", function()
    if not dragging then
      return "<LeftRelease>"
    end
    dragging = nil
    return ""
  end, { expr = true, desc = "End dragging a tab" })
end

-- Tab colors, derived from Normal as bufferline does (config.lua's
-- derive_colors): shaded backgrounds, Comment for others' text
local tab_colors

local function shade(hex, percent)
  local rgb = {}
  for i = 1, 3 do
    local c = tonumber(hex:sub(2 * i, 2 * i + 1), 16)
    rgb[i] = math.min(255, math.max(0, math.floor(c * (100 + percent) / 100)))
  end
  return string.format("#%02x%02x%02x", rgb[1], rgb[2], rgb[3])
end

local function load_tab_colors()
  local bg = normal_bg()
  local normal_fg = hl_color("Normal", "fg")
  local comment_fg = hl_color("Comment", "fg") or normal_fg
  local rgb = vim.tbl_map(function(i)
    return tonumber(bg:sub(i, i + 1), 16)
  end, { 2, 4, 6 })
  local bright = (0.299 * rgb[1] + 0.587 * rgb[2] + 0.114 * rgb[3]) / 255 > 0.5
  tab_colors = {
    fill = shade(bg, bright and -20 or -45),
    inactive = { fg = comment_fg, bg = shade(bg, bright and -12 or -25) },
    visible = { fg = comment_fg, bg = shade(bg, -8) },
    selected = { fg = normal_fg, bg = bg, bold = true },
    modified = hl_color("String", "fg"),
    comment = comment_fg,
  }
end

local function build_tabline()
  local utils = require("heirline.utils")

  local function state_colors(self)
    return self.is_active and tab_colors.selected or self.is_visible and tab_colors.visible or tab_colors.inactive
  end
  local function slant_hl(self)
    return { fg = tab_colors.fill, bg = state_colors(self).bg, bold = false }
  end
  local function bufnr(self)
    return self.bufnr
  end
  local function bd(buf)
    vim.cmd("Bd " .. buf)
  end

  local Tab = {
    init = function(self)
      self.f = tab_fields(self.bufnr, self.names[self.bufnr])
    end,
    hl = state_colors,
    -- Left: switch (and start a drag), middle/right: close
    on_click = {
      name = "heirline_tab",
      minwid = bufnr,
      callback = function(_, buf, _, button)
        if button == "l" then
          dragging = buf
          vim.api.nvim_win_set_buf(0, buf)
        else
          vim.schedule(function()
            bd(buf)
          end)
        end
      end,
    },
    { provider = tab_icons.slant_left, hl = slant_hl },
    { provider = " " },
    {
      provider = function(self)
        return self.f.icon
      end,
      hl = function(self)
        return { fg = self.f.icon_hl and hl_color(self.f.icon_hl, "fg") }
      end,
    },
    { provider = " " },
    {
      provider = function(self)
        return esc(self.f.prefix)
      end,
      hl = function()
        return { fg = tab_colors.comment, bold = false, italic = true }
      end,
    },
    {
      provider = function(self)
        return esc(self.f.name)
      end,
    },
    { provider = " " },
    {
      provider = function(self)
        return self.f.state
      end,
      hl = function(self)
        if vim.bo[self.bufnr].modified then
          return { fg = tab_colors.modified }
        end
      end,
      -- The close button (as the whole tab's middle/right click)
      on_click = click("tab_close", bd, bufnr),
    },
    { provider = "\194\160" }, -- no-break space: WezTerm spills the glyph into an ASCII one
    { provider = tab_icons.slant_right, hl = slant_hl },
  }

  local Offset = {
    condition = function(self)
      self.offset_width = tab_offset()
      return self.offset_width > 0
    end,
    {
      provider = function(self)
        local title = " File Explorer"
        return title .. string.rep(" ", self.offset_width - 1 - vim.api.nvim_strwidth(title))
      end,
      hl = function()
        return { fg = hl_color("Directory", "fg"), bg = hl_color("NvimTreeNormal", "bg") or tab_colors.fill }
      end,
    },
    {
      provider = "│",
      hl = function()
        return { fg = hl_color("WinSeparator", "fg"), bg = tab_colors.fill }
      end,
    },
  }

  local trunc_hl = function()
    return { fg = tab_colors.comment, bg = tab_colors.fill }
  end
  local Buffers = utils.make_buflist(
    Tab,
    { provider = " " .. tab_icons.trunc_left .. " ", hl = trunc_hl },
    { provider = " " .. tab_icons.trunc_right .. " ", hl = trunc_hl },
    listed_buffers,
    false -- no cache: listed_buffers() is cheap and the order changes
  )

  -- Tab pages on the right when there's more than one (bufferline's
  -- show_tab_indicators)
  local TabPages = {
    condition = function()
      return #vim.api.nvim_list_tabpages() > 1
    end,
    utils.make_tablist({
      provider = function(self)
        return "%" .. self.tabnr .. "T " .. self.tabnr .. " %T"
      end,
      hl = function(self)
        return self.is_active and tab_colors.selected or tab_colors.inactive
      end,
    }),
  }

  return {
    init = function(self)
      self.names = tab_names(listed_buffers())
    end,
    hl = function()
      return { fg = tab_colors.comment, bg = tab_colors.fill }
    end,
    Offset,
    Buffers,
    { provider = "%=" },
    TabPages,
  }
end

-- Shown with 2+ buffers or tab pages (bufferline's always_show_bufferline = false)
local function update_showtabline()
  local want = (#listed_buffers() > 1 or #vim.api.nvim_list_tabpages() > 1) and 2 or 0
  if vim.o.showtabline ~= want then
    vim.o.showtabline = want
  end
end

local function tab_keymaps()
  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { desc = desc })
  end
  -- As bufferline's in lua/plugins/bufferline.lua, in tab order
  for _, keys in ipairs({ { "n", "[b", "]b" }, { { "n", "i" }, "<S-PageUp>", "<S-PageDown>" } }) do
    map(keys[1], keys[2], function()
      cycle_tab(-1)
    end, "Prev buffer")
    map(keys[1], keys[3], function()
      cycle_tab(1)
    end, "Next buffer")
  end
  for n = 1, 10 do
    map("n", "<A-" .. (n % 10) .. ">", function()
      goto_tab(n)
    end, "Go to buffer " .. n)
  end
  map("n", "<leader>bl", function()
    close_tabs("left")
  end, "Delete buffers to the Left")
  map("n", "<leader>bo", function()
    close_tabs("others")
  end, "Delete Other buffers")
  map("n", "<leader>br", function()
    close_tabs("right")
  end, "Delete buffers to the Right")
  -- New: move the current buffer's tab
  map("n", "<leader>b<", function()
    move_tab_to(vim.api.nvim_get_current_buf(), current_tab_index() - 1)
  end, "Move buffer tab left")
  map("n", "<leader>b>", function()
    move_tab_to(vim.api.nvim_get_current_buf(), current_tab_index() + 1)
  end, "Move buffer tab right")
  drag_keymaps()
end

---------------------------------------------------------------------------
-- Statuscolumn: as init.lua's "%3l%s" (number, then the sign column). A
-- click on a git sign previews its hunk; on a number, nvim's default: the
-- cursor goes there (its diagnostics show below it, virtual_lines in
-- lsp.lua). nvim calls the same handler for every line (:help
-- 'statuscolumn'), so the line comes from the mouse position.

local function at_clicked_line(fn)
  return function()
    local pos = vim.fn.getmousepos()
    if pos.winid == 0 or pos.line == 0 then
      return
    end
    vim.schedule(function()
      vim.api.nvim_set_current_win(pos.winid)
      if vim.api.nvim_win_get_cursor(pos.winid)[1] == pos.line then
        return fn()
      end
      vim.api.nvim_win_set_cursor(pos.winid, { pos.line, 0 })
      -- Once the CursorMoved for that has fired: gitsigns' inline preview
      -- closes on cursor movement
      vim.api.nvim_create_autocmd("CursorMoved", { once = true, callback = vim.schedule_wrap(fn) })
    end)
  end
end

local function build_statuscolumn()
  return {
    {
      -- Not just %3l: it's empty on virtual lines (diagnostic messages
      -- below the cursor line), and nvim takes the click areas from a
      -- single drawn line: if that's one, the sign's is shifted (0.12.6)
      provider = function()
        return vim.v.virtnum == 0 and "%3l" or "   "
      end,
    },
    {
      provider = "%s",
      on_click = {
        name = "heirline_stc_sign",
        -- gitsigns finds the hunk at the cursor (also deletions at the file's
        -- start or end, staged ones); nothing without one
        callback = at_clicked_line(function()
          local ok, gs = pcall(require, "gitsigns")
          if ok then
            gs.preview_hunk_inline()
          end
        end),
      },
    },
  }
end

return {
  {
    "rebelot/heirline.nvim",
    dev = true,
    cond = function()
      return vim.g.statusline_plugin == "heirline"
    end,
    lazy = false, -- the statusline is there from the first screen
    dependencies = { vim.g.icons_plugin },
    config = function()
      load_theme()
      load_tab_colors()
      local StatusLines, WinBar = build_statusline_winbar()
      require("heirline").setup({
        statusline = StatusLines,
        winbar = WinBar,
        tabline = build_tabline(),
        statuscolumn = build_statuscolumn(),
        opts = {
          -- heirline sets the winbar on BufWinEnter etc.; this decides
          -- where. update_winbars() below handles splits/closes.
          disable_winbar_cb = function(args)
            local win = vim.api.nvim_get_current_win()
            if vim.api.nvim_win_get_buf(win) ~= args.buf then
              win = vim.fn.bufwinid(args.buf)
            end
            return not wants_winbar(win, file_wins())
          end,
        },
      })

      local group = vim.api.nvim_create_augroup("HeirlineUser", { clear = true })
      -- Mode shown: redraw on changes, also those nvim doesn't redraw the
      -- statusline for (operator-pending, ...)
      vim.api.nvim_create_autocmd("ModeChanged", { group = group, callback = redrawstatus })
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = group,
        callback = function()
          load_theme()
          load_tab_colors()
          require("heirline.utils").on_colorscheme({})
        end,
      })
      vim.api.nvim_create_autocmd("LspProgress", { group = group, callback = on_lsp_progress })
      -- A server that stops mid-task sends no "end"
      vim.api.nvim_create_autocmd("LspDetach", {
        group = group,
        callback = function(ev)
          for key in pairs(lsp_progress) do
            if vim.startswith(key, ev.data.client_id .. ":") then
              lsp_progress[key] = nil
            end
          end
          update_spinner_timer()
        end,
      })
      vim.api.nvim_create_autocmd({ "WinNew", "WinClosed", "BufWinEnter", "TabEnter" }, {
        group = group,
        callback = vim.schedule_wrap(update_winbars),
      })
      vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete", "BufWipeout", "TabNew", "TabClosed", "VimEnter" }, {
        group = group,
        callback = vim.schedule_wrap(update_showtabline),
      })
      vim.api.nvim_create_autocmd("OptionSet", {
        group = group,
        pattern = "buflisted",
        callback = vim.schedule_wrap(update_showtabline),
      })
      update_showtabline()
      tab_keymaps()
    end,
  },
}
