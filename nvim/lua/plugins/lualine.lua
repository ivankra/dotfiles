-- Statusline with lualine.nvim, one for all windows:
--   mode | branch | path ... diagnostics, diff, hex code, indent, encoding,
--   LSP progress, filetype | progress | line:column
-- * Path: relative to the cwd, shortened when space runs out, the file name
--   colored when modified. Fugitive buffers show their revision, terminals
--   their title.
-- * Diff counts come from gitsigns: live, unsaved changes included.
-- * Filetype: a gear before its icon while a language server is attached,
--   and the venv in Python buffers.
-- * Narrow windows hide the less useful parts first.
-- * Clicks: the branch and diagnostics open pickers, the diff :Git, and the
--   path, indent and filetype open menus (nvim's popup menu, as VS Code's).

-- Helpers {{{

-- LazyVim's helper, verbatim (M.format in lua/lazyvim/util/lualine.lua):
local function format_hl(component, text, hl_group)
  text = text:gsub("%%", "%%%%")
  if not hl_group or hl_group == "" then
    return text
  end
  ---@type table<string, string>
  component.hl_cache = component.hl_cache or {}
  local lualine_hl_group = component.hl_cache[hl_group]
  if not lualine_hl_group then
    local utils = require("lualine.utils.utils")
    ---@type string[]
    local gui = vim.tbl_filter(function(x)
      return x
    end, {
      utils.extract_highlight_colors(hl_group, "bold") and "bold",
      utils.extract_highlight_colors(hl_group, "italic") and "italic",
    })

    lualine_hl_group = component:create_hl({
      fg = utils.extract_highlight_colors(hl_group, "fg"),
      gui = #gui > 0 and table.concat(gui, ",") or nil,
    }, "LV_" .. hl_group) --[[@as string]]
    component.hl_cache[hl_group] = lualine_hl_group
  end
  return component:format_hl(lualine_hl_group) .. text .. component:get_default_hl()
end

-- Bold in the section's own colors (no group: lualine fills fg/bg in from
-- the theme for each mode). For what LazyVim has no style for.
local function format_bold(component, text)
  component.bold_hl = component.bold_hl or component:create_hl({ gui = "bold" }, "LV_SectionBold")
  return component:format_hl(component.bold_hl) .. text:gsub("%%", "%%%%") .. component:get_default_hl()
end

-- Modified file name / readonly icon: MatchParen's color, else (the scheme
-- gives it no fg, e.g. gruvbox, nvim's default) WarningMsg's
local function modified_hl()
  return vim.api.nvim_get_hl(0, { name = "MatchParen", link = false }).fg and "MatchParen" or "WarningMsg"
end

-- For cond: shown only when the statusline is at least width columns wide
local function min_width(width)
  return function()
    local w = vim.o.laststatus == 3 and vim.o.columns or vim.fn.winwidth(0)
    return w >= width
  end
end

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

-- }}}

-- Popup menus {{{

-- What clicking the path, indent and filetype opens, as VS Code's: nvim's
-- own popup menu (as its right-click one), at the mouse.

---@class MenuItem
---@field label string
---@field action fun()
---@field checked? boolean marked with •
---@field map? string description of a normal mode mapping doing the same: its keys are shown

-- Actions of each menu, by name: an entry can only run a command
local menu_actions = {}

-- Entry i of menu name chosen: runs its action. The entries' command, via
-- the table registered at the end of this file.
local function ll_on_menu_choice(name, i)
  -- Scheduled: an entry runs while the menu still has control (E565)
  vim.schedule(menu_actions[name][i])
end

-- Keys of the mapping with this description, in this buffer or globally,
-- with ␣ for the <leader> Space. The shortest of several: ␣e, not <C-B>.
local function mapping_keys(desc)
  local best
  for _, map in ipairs(vim.list_extend(vim.api.nvim_buf_get_keymap(0, "n"), vim.api.nvim_get_keymap("n"))) do
    if map.desc == desc then
      local keys = vim.fn.keytrans(map.lhs):gsub("<Space>", "␣")
      if not best or vim.api.nvim_strwidth(keys) < vim.api.nvim_strwidth(best) then
        best = keys
      end
    end
  end
  return best
end

-- Opens menu name at the mouse. items: MenuItem, or "-" for a divider. In
-- the terminal the menu doesn't show the menus' own shortcut column (<Tab>
-- in a name), and at the screen's right edge it cuts entries rather than
-- moving left: keys are padded in by hand, when they fit.
---@param items (MenuItem|"-")[]
local function popup_menu(name, items)
  local marks = vim.iter(items):any(function(item)
    return type(item) == "table" and item.checked
  end)
  local keys, width, keys_width = {}, 0, 0
  for i, item in ipairs(items) do
    if type(item) == "table" then
      keys[i] = item.map and mapping_keys(item.map)
      width = math.max(width, vim.api.nvim_strwidth(item.label))
      keys_width = math.max(keys_width, keys[i] and vim.api.nvim_strwidth(keys[i]) or 0)
    end
  end
  -- The menu starts at the click
  if (marks and 2 or 0) + width + 2 + keys_width > vim.o.columns - vim.fn.getmousepos().screencol then
    keys = {}
  end

  pcall(vim.cmd, "aunmenu ]" .. name)
  menu_actions[name] = {}
  for i, item in ipairs(items) do
    if type(item) ~= "table" then
      vim.cmd(("anoremenu ]%s.-%d- <Nop>"):format(name, i))
    else
      local label = (marks and (item.checked and "• " or "  ") or "") .. item.label
      if keys[i] then
        label = label .. (" "):rep(width - vim.api.nvim_strwidth(item.label) + 2) .. keys[i]
      end
      table.insert(menu_actions[name], item.action)
      vim.cmd(
        ("anoremenu ]%s.%s <Cmd>lua require('lualine_clicks').ll_on_menu_choice('%s', %d)<CR>"):format(
          name,
          vim.fn.escape(label, " .\\&|"),
          name,
          #menu_actions[name]
        )
      )
    end
  end
  vim.cmd("popup! ]" .. name)
end

-- }}}

-- Mode {{{

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

local function ll_mode_fmt(mode)
  return mode_short[mode] or mode
end

-- }}}

-- Telescope picker. None before 0.11 (no telescope)
local function telescope(picker)
  if vim.fn.exists(":Telescope") == 2 then
    vim.cmd("Telescope " .. picker)
  end
end

-- Branch {{{

local function ll_branch_picker()
  telescope("git_branches")
end

-- }}}

-- Path {{{

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

    -- Shorten only when too long for the window (the rest of the statusline
    -- takes ~90 columns): middle dirs to "…" one at a time, down to first +
    -- … + last dir + file at most
    local budget = math.max(20, vim.o.columns - 90)
    while #parts > 4 and vim.api.nvim_strwidth(table.concat(parts, sep)) > budget do
      if parts[2] == "…" then
        table.remove(parts, 3)
      else
        parts[2] = "…"
      end
    end

    -- Format filename in the scheme's Bold, as LazyVim.
    -- Modified buffers are shown by color only (modified_hl), no extra marker.
    if vim.bo.modified then
      parts[#parts] = format_hl(self, parts[#parts], modified_hl())
    else
      parts[#parts] = format_hl(self, parts[#parts], "Bold")
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
      readonly = format_hl(self, vim.g.nerd_font and " 󰌾 " or " [RO]", modified_hl())
    end

    -- fugitive:// buffer: which version of the file this is
    if rev then
      rev = " @ " .. rev
    end

    return dir .. parts[#parts] .. (rev or "") .. readonly
  end
end

-- Path menu

-- Copies text to the unnamed register, and the system clipboard when nvim
-- has one (a clipboard tool, or OSC 52: plugin/clipboard.lua)
local function copy_action(text)
  return function()
    vim.fn.setreg('"', text)
    if vim.fn.has("clipboard") == 1 then
      vim.fn.setreg("+", text)
    end
    vim.notify("Copied " .. text)
  end
end

-- For window win's file, e.g. a split's winbar's. Nothing switches to the
-- window until an entry is chosen.
---@param win integer
local function ll_window_path_menu(win)
  local buf = vim.api.nvim_win_get_buf(win)
  local file = vim.api.nvim_buf_get_name(buf)
  local rev, real = fugitive_info(file)
  if rev then
    file = real -- the work tree file it's a version of; none for a commit
  elseif vim.bo[buf].buftype ~= "" then
    return
  end
  if not file or file == "" then
    return
  end
  local function in_window(cmd)
    return function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_set_current_win(win)
      end
      vim.cmd(cmd)
    end
  end
  popup_menu("LualinePath", {
    {
      label = "Open folder (oil)",
      action = in_window("Oil " .. vim.fn.fnameescape(vim.fs.dirname(file))),
      map = "Open parent directory (oil)",
    },
    { label = "Show in file tree", action = in_window("NvimTreeFindFile") },
    "-",
    { label = "Copy path", action = copy_action(file) },
    { label = "Copy relative path", action = copy_action(vim.fn.fnamemodify(file, ":~:.")) },
    { label = "Copy file name", action = copy_action(vim.fs.basename(file)) },
  })
end

-- For the current window's file: the statusline's
local function ll_path_menu()
  ll_window_path_menu(vim.api.nvim_get_current_win())
end

-- }}}

-- Diagnostics {{{

local function ll_diagnostics_picker()
  telescope("diagnostics bufnr=0")
end

-- }}}

-- Diff {{{

-- Live diff counts from gitsigns.
-- Lualine's own runs git diff, only on save and buffer switch.
local function ll_diff_gitsigns()
  local g = vim.b.gitsigns_status_dict
  if g then
    return { added = g.added, modified = g.changed, removed = g.removed }
  end
end

local function ll_git_status()
  vim.cmd("Git")
end

-- }}}

-- Hex code: 0xXX {{{

local function ll_hex_char()
  local res = vim.api.nvim_eval_statusline("0x%02B", {}).str
  if res == "0x00" then
    return "    "
  else
    return res
  end
end

-- }}}

-- Indent (e.g. "␣2", "⇥8") {{{

local function ll_indent()
  if vim.bo.buftype ~= "" then
    return ""
  end
  return vim.bo.expandtab and "␣" .. vim.fn.shiftwidth() or "⇥" .. vim.bo.tabstop
end

-- Sets buffer options, showing exactly what was set: ":setlocal sw=2 sts=-1"
local function setlocal_notify(args, done)
  vim.cmd("setlocal " .. args)
  if package.loaded.lualine then
    require("lualine").refresh() -- else it shows the option at its next refresh
  end
  vim.cmd.redrawstatus()
  vim.notify((done and done .. ", " or "") .. ":setlocal " .. args)
end

-- Re-indents with tabs or spaces: only each line's leading whitespace
-- (:retab! also changes spaces inside lines). Tabs are shiftwidth wide then,
-- so it looks the same.
local function convert_indent(to_tabs)
  local sw = vim.fn.shiftwidth()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local n = 0
  for i, line in ipairs(lines) do
    local lead = line:match("^[ \t]*")
    local width = vim.fn.strdisplaywidth(lead) -- tabs by the current 'tabstop'
    local new = to_tabs and ("\t"):rep(math.floor(width / sw)) .. (" "):rep(width % sw) or (" "):rep(width)
    if new ~= lead then
      lines[i], n = new .. line:sub(#lead + 1), n + 1
    end
  end
  if n > 0 then
    vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
  end
  setlocal_notify(
    to_tabs and "noexpandtab tabstop=" .. sw or "expandtab",
    n .. (n == 1 and " line" or " lines") .. " re-indented"
  )
end

local function ll_indent_menu()
  local expandtab, sw = vim.bo.expandtab, vim.fn.shiftwidth()
  local items = {
    {
      label = "Use spaces",
      checked = expandtab,
      action = function()
        setlocal_notify("expandtab")
      end,
    },
    {
      label = "Use tabs",
      checked = not expandtab,
      action = function()
        setlocal_notify(("noexpandtab tabstop=%d softtabstop=-1"):format(sw)) -- a tab per level
      end,
    },
    "-",
    {
      label = "Convert to spaces",
      action = function()
        convert_indent(false)
      end,
    },
    {
      label = "Convert to tabs",
      action = function()
        convert_indent(true)
      end,
    },
    "-",
  }
  -- The width the statusline shows: shiftwidth with spaces, tabstop with tabs
  local shown = expandtab and sw or vim.bo.tabstop
  for _, width in ipairs({ 2, 4, 8 }) do
    table.insert(items, {
      label = "Width " .. width,
      checked = width == shown,
      action = function()
        -- softtabstop -1 (shiftwidth's): ftplugins and guess-indent set a
        -- number, e.g. python's 4, which Tab and Backspace would still use
        setlocal_notify(("shiftwidth=%d softtabstop=-1"):format(width) .. (expandtab and "" or " tabstop=" .. width))
      end,
    })
  end
  popup_menu("LualineIndent", items)
end

-- }}}

-- Encoding {{{

-- Encoding only shown when unusual: non-utf-8, BOM, or non-unix line endings.
local function ll_encoding()
  local parts = {}
  local enc = vim.bo.fenc ~= "" and vim.bo.fenc or vim.o.encoding
  if enc ~= "utf-8" or vim.bo.bomb then
    table.insert(parts, enc .. (vim.bo.bomb and "-bom" or ""))
  end
  local ff = vim.bo.fileformat
  if ff ~= "unix" then
    local ff_icon = vim.g.nerd_font and { dos = "", mac = "" } or {}
    table.insert(parts, ff_icon[ff] or ff)
  end
  return table.concat(parts, " ")
end

-- }}}

-- Filetype {{{

-- The filetype's name (its icon is left of the path), and in Python the venv:
-- its shell prompt name, else dir name, else conda's. A gear in front while a
-- language server is attached.
local function ll_filetype_fmt(ft)
  local label = ft
  local prompt = (vim.env.VIRTUAL_ENV_PROMPT or ""):gsub("^%((.*)%) $", "%1") -- "(name) " before 3.12
  local env = prompt ~= "" and prompt
    or vim.env.VIRTUAL_ENV and vim.fn.fnamemodify(vim.env.VIRTUAL_ENV, ":t")
    or vim.env.CONDA_DEFAULT_ENV
  if ft == "python" and env and env ~= "" then
    label = label .. " (" .. env .. ")"
  end
  if #vim.lsp.get_clients({ bufnr = 0 }) > 0 then
    label = (vim.g.nerd_font and "\u{f013} " or "LSP ") .. label
  end
  return label
end

-- Filetype menu: the filetype, formatting, toggles, language servers

-- conform.nvim's formatting (as <leader>cf), with what it runs:
-- "Format (ruff)" for ruff_fix/ruff_format/ruff_organize_imports, the
-- server ("Format (clangd)") when it falls back to it. Nil if nothing would.
local function format_menu_item()
  local ok, conform = pcall(require, "conform")
  if not ok then
    return nil
  end
  local formatters, lsp = conform.list_formatters_to_run(0)
  local names = vim.tbl_map(function(f)
    return vim.fs.basename(f.command)
  end, formatters)
  if lsp then
    -- The servers conform asks: as its lsp_format.get_format_clients()
    for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0, method = "textDocument/formatting" })) do
      table.insert(names, client.name)
    end
  end
  if #names == 0 then
    return nil
  end
  return {
    label = "Format (" .. table.concat(vim.fn.uniq(names), ", ") .. ")",
    action = function()
      conform.format({ async = true })
    end,
    map = "Format buffer/selection",
  }
end

-- :lsp restart/stop [name] (0.12), else nvim-lspconfig's :LspRestart/:LspStop
local function lsp_command(verb, name)
  local cmd = vim.fn.exists(":lsp") == 2 and "lsp " .. verb or "Lsp" .. verb:gsub("^%l", string.upper)
  vim.cmd(cmd .. (name and " " .. name or ""))
end

-- Servers stopped from the menu. Disabled (:lsp disable), not just stopped:
-- else they'd attach again to the next file opened. Offered to start again.
local stopped_servers = {}

local function lsp_menu_items()
  local items = {}
  local function add(label, action)
    table.insert(items, { label = label, action = action })
  end
  add("LSP info", function()
    vim.cmd("checkhealth vim.lsp")
  end)
  add("LSP log", function()
    vim.cmd("tabnew " .. vim.fn.fnameescape(vim.lsp.log.get_filename()))
  end)
  -- Servers installed since startup (lua/plugins/lsp.lua)
  if vim.fn.exists(":LspRescan") == 2 then
    add("LSP rescan", function()
      vim.cmd("LspRescan")
    end)
  end
  -- mason-lspconfig's (dvim): picks one of the filetype's servers
  if vim.fn.exists(":LspInstall") == 2 then
    add("Install LSP…", function()
      vim.cmd("LspInstall")
    end)
  end

  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients > 1 then -- with one, its own entry
    add("Restart all", function()
      lsp_command("restart")
    end)
  end
  for _, client in ipairs(clients) do
    add("Restart " .. client.name, function()
      lsp_command("restart", client.name)
    end)
  end
  for _, client in ipairs(clients) do
    add("Stop " .. client.name, function()
      if vim.lsp.is_enabled and vim.lsp.is_enabled(client.name) then
        vim.lsp.enable(client.name, false)
        stopped_servers[client.name] = true
      else -- not started by vim.lsp.enable()
        lsp_command("stop", client.name)
      end
    end)
  end

  local ft = vim.bo.filetype
  local starts = 0
  for _, name in ipairs(vim.fn.sort(vim.tbl_keys(stopped_servers))) do
    local filetypes = vim.lsp.config[name].filetypes
    -- For this filetype, unless enabled again since (:lsp enable)
    if not vim.lsp.is_enabled(name) and (not filetypes or vim.list_contains(filetypes, ft)) then
      starts = starts + 1
      add("Start " .. name, function()
        stopped_servers[name] = nil
        vim.lsp.enable(name) -- attaches it to the open buffers too
      end)
    end
  end
  -- None attached, e.g. after :lsp stop: the enabled ones, as
  -- vim.lsp.enable() starts them for a new buffer (:lsp enable would enable
  -- every config). Its autocmd group exists once one was enabled.
  if #clients == 0 and starts == 0 and vim.fn.exists("#nvim.lsp.enable#FileType") == 1 then
    add("Start servers", function()
      vim.api.nvim_exec_autocmds("FileType", { group = "nvim.lsp.enable", buffer = 0 })
    end)
  end
  return items
end

local function ll_filetype_menu()
  local items = {
    {
      label = "Filetype: " .. vim.bo.filetype,
      action = function()
        telescope("filetypes")
      end,
    },
    {
      -- e.g. after adding a shebang or renaming the file
      label = "Autodetect",
      action = function()
        vim.cmd("filetype detect")
      end,
    },
    "-",
  }
  local format = format_menu_item()
  if format then
    vim.list_extend(items, { format, "-" })
  end
  -- Inferred types and parameter names inline (as <leader>uh, per buffer)
  if #vim.lsp.get_clients({ bufnr = 0, method = "textDocument/inlayHint" }) > 0 then
    local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
    table.insert(items, {
      label = "Inlay hints",
      checked = enabled,
      action = function()
        vim.lsp.inlay_hint.enable(not enabled, { bufnr = 0 })
      end,
      map = "Toggle inlay hints",
    })
  end
  -- In all buffers, as <leader>ud
  local diagnostics = vim.diagnostic.is_enabled()
  table.insert(items, {
    label = "Diagnostics",
    checked = diagnostics,
    action = function()
      vim.diagnostic.enable(not diagnostics)
    end,
    map = "Toggle Diagnostics",
  })
  table.insert(items, "-")
  if vim.fn.exists(":ConformInfo") == 2 then
    table.insert(items, {
      label = "Formatter info",
      action = function()
        vim.cmd("ConformInfo")
      end,
    })
  end
  popup_menu("LualineFiletype", vim.list_extend(items, lsp_menu_items()))
end

-- }}}

-- Command line info {{{

-- What the command line would show when hidden (cmdheight=0, see init.lua)
local function cmdline_hidden()
  return vim.o.cmdheight == 0
end

-- A highlight group's foreground, for a component's color: as LazyVim, which
-- colors these with Snacks.util.color(). A function: follows colorscheme changes.
local function fg_of(group)
  return function()
    local fg = vim.api.nvim_get_hl(0, { name = group, link = false }).fg
    return fg and { fg = string.format("#%06x", fg) } or nil
  end
end

-- Macro being recorded
local function ll_recording()
  local reg = vim.fn.reg_recording()
  return reg ~= "" and "recording @" .. reg or ""
end

-- Keys of a pending command (count, operator, register): nvim's live %S (it
-- redraws it while a command is pending, lualine can't). Not in Visual mode,
-- where it's the selection size, nor with raw key bytes ("~@": arrows, mouse).
-- While which-key waits (g, <Space>, ...), its keys. Refreshed per key (below).
local function ll_showcmd()
  local wk = package.loaded["which-key.state"]
  local keys = wk and wk.state and wk.state.node.keys -- in key notation already
  if keys and keys ~= "" then
    -- With a count typed before. Not a register as which-key's own title has
    -- it: v:register stays set after which-key is left with Esc.
    keys = (vim.v.count > 0 and vim.v.count or "") .. keys
    return " " .. keys:gsub("%%", "%%%%") .. " "
  end
  if vim.fn.mode():find("^[vVsS\22\19]") then -- Visual, Select (also blockwise)
    return ""
  end
  -- %( %): no padding when empty
  return vim.api.nvim_eval_statusline("%S", {}).str:find("~@", 1, true) and "" or "%( %S %)"
end

-- }}}

-- Location {{{

-- %v: screen column, not %c's byte column (2x on Cyrillic text)
local function ll_location()
  return vim.api.nvim_eval_statusline("%2l:%-2v", {}).str
end

-- }}}

-- Registered as require("lualine_clicks"): the click handlers, for
-- experimenting with other statusline plugins, and the menus' own callback
package.loaded.lualine_clicks = {
  ll_branch_picker = ll_branch_picker,
  ll_window_path_menu = ll_window_path_menu,
  ll_diagnostics_picker = ll_diagnostics_picker,
  ll_git_status = ll_git_status,
  ll_indent_menu = ll_indent_menu,
  ll_filetype_menu = ll_filetype_menu,
  ll_on_menu_choice = ll_on_menu_choice, -- what the menu entries run (popup_menu)
}

return {
  {
    "nvim-lualine/lualine.nvim",
    dev = true,
    -- 0.10+: the components below use vim.iter, vim.lsp.get_clients,
    -- vim.diagnostic.is_enabled etc. (lualine itself would run on older).
    -- Older nvim keeps its own statusline.
    cond = function()
      return vim.g.statusline_plugin == "lualine" and vim.fn.has("nvim-0.10") == 1
    end,
    dependencies = { vim.g.icons_plugin },
    opts = {
      options = {
        theme = "auto",
        component_separators = { left = "", right = "" },
        section_separators = not vim.g.nerd_font and { left = "", right = "" } or nil,
        icons_enabled = vim.g.nerd_font,
        globalstatus = true,
      },
      -- Own statusline for these windows (by filetype) instead of the sections below
      extensions = { "oil", "nvim-tree", "toggleterm", "fugitive", "lazy", "quickfix", "man" },
      sections = {
        lualine_a = {
          { "mode", fmt = ll_mode_fmt },
        },
        lualine_b = {
          { "branch", icon = "", on_click = ll_branch_picker, cond = min_width(100) },
        },
        lualine_c = {
          -- Separated from the path when shown: by lualine's default component
          -- separator (Nerd Font chevron)
          {
            "diagnostics",
            on_click = ll_diagnostics_picker,
            cond = min_width(70),
            separator = vim.g.nerd_font and "\u{e0b1}" or ">",
          },
          -- The filetype's icon (its name is on the right)
          {
            "filetype",
            icon_only = true,
            separator = "",
            padding = { left = 1, right = 0 },
            cond = function()
              return vim.g.nerd_font
            end,
          },
          { ll_pretty_path(), on_click = ll_path_menu },
        },
        lualine_x = {
          { ll_showcmd, cond = cmdline_hidden, color = fg_of("Statement"), padding = 0 },
          { ll_recording, cond = cmdline_hidden, color = fg_of("Constant") },
          { "diff", source = ll_diff_gitsigns, on_click = ll_git_status, cond = min_width(100) },
          { ll_hex_char, cond = min_width(120) },
          { ll_indent, on_click = ll_indent_menu, cond = min_width(110) },
          { ll_encoding, cond = min_width(60) },
          {
            "filetype",
            fmt = ll_filetype_fmt,
            icons_enabled = false,
            on_click = ll_filetype_menu,
            cond = min_width(60),
          },
        },
        lualine_y = {
          { "progress", cond = min_width(60) },
          { "searchcount", cond = cmdline_hidden },
        },
        lualine_z = {
          { ll_location, cond = min_width(40) },
        },
      },
    },
    config = function(_, opts)
      local lualine = require("lualine")
      lualine.setup(opts)
      -- While typing a command (laststatus=0, plugin/ui2.lua), split windows'
      -- statuslines: drawn as the separator they replace
      local statusline = lualine.statusline
      lualine.statusline = function(...)
        if vim.o.laststatus == 0 then
          local horiz = vim.opt.fillchars:get().horiz or "─"
          return ("%%#WinSeparator#%%{repeat('%s', winwidth(0))}"):format(horiz)
        end
        return statusline(...)
      end
      vim.api.nvim_create_autocmd({ "CmdlineEnter", "CmdlineLeave" }, {
        group = vim.api.nvim_create_augroup("LualineCmdline", { clear = true }),
        callback = function()
          vim.schedule(function() -- after ui2.lua's laststatus change
            lualine.refresh({ scope = "tabpage", place = { "statusline" }, force = true })
          end)
        end,
      })
      -- Not among lualine's refresh events. On RecordingLeave the register is
      -- still being recorded: refresh once that's done.
      vim.api.nvim_create_autocmd({ "RecordingEnter", "RecordingLeave" }, {
        group = vim.api.nvim_create_augroup("LualineRecording", { clear = true }),
        callback = function()
          vim.schedule(require("lualine").refresh)
        end,
      })
      -- Pending keys (ll_showcmd): after each key has been handled. Checked
      -- each time: plugin/ui2.lua sets cmdheight=0 only after this runs.
      -- One refresh queued at a time: keys that come in faster (pasted,
      -- mappings) share it. None while a macro runs: on_key sees each of its
      -- keys, and a long @q queued a refresh per key, all run after it ended.
      -- The next key typed, or lualine's timer, refreshes after it.
      local refresh_pending = false
      vim.on_key(function()
        if refresh_pending or not cmdline_hidden() or vim.fn.reg_executing() ~= "" then
          return
        end
        refresh_pending = true
        vim.schedule(function()
          refresh_pending = false
          require("lualine").refresh()
        end)
      end, vim.api.nvim_create_namespace("LualineShowcmd"))
    end,
  },
}
