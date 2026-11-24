-- Autocommands
-- Mostly following https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua

local function augroup(name)
  return vim.api.nvim_create_augroup("dotfiles_" .. name, { clear = true })
end

-- Pick up changes made to files outside nvim {{{
--
-- hotreload.nvim (via lua/plugins/init.lua) reloads unmodified buffers right
-- away on nvim 0.10-0.12; 0.13 does this itself. This autocmd catches the rest.
--
-- 'autoread' (on by default) reloads a changed file only when nvim checks it.
-- :checktime runs that check, so call it on focus, on buffer switch, when a
-- terminal closes and after :stop. Buffers with unsaved changes get a prompt
-- instead.

local function checktime()
  -- checktime checks all buffers; it errors in the cmdline window
  if vim.fn.getcmdwintype() == "" then
    pcall(vim.cmd, "checktime") -- not vim.cmd.checktime: 0.8+
  end
end

local checktime_events = {
  "FocusGained", -- in tmux, needs `set -g focus-events on` in tmux.conf
  "BufEnter",
  "TermClose",
  "TermLeave",
  "VimResume",
}

vim.api.nvim_create_autocmd(checktime_events, {
  group = augroup("checktime"),
  callback = function(ev)
    checktime()

    -- Refresh nvim-tree if it's open, on focus only: its filesystem watchers
    -- cover the rest, this catches what they miss.
    local tree_api = package.loaded["nvim-tree.api"]
    if ev.event == "FocusGained" and tree_api then
      -- pcall around the lookups too, in case the API isn't fully there
      pcall(function()
        if tree_api.tree.is_visible() then
          tree_api.tree.reload()
        end
      end)
    end
  end,
})

--- }}}

-- Highlight on yank  {{{
-- Like Vim's hlyank package

vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function()
    -- vim.hl is 0.11+ (vim.highlight before); 0.13 deprecates on_yank() for hl_op()
    if vim.fn.has("nvim-0.13") == 1 then
      vim.hl.hl_op()
    else
      (vim.hl or vim.highlight).on_yank()
    end
  end,
})

--- }}}

-- Resize splits if the window got resized {{{
-- Equal sizes in every tab.
-- nvim-tree and toggleterm keep theirs ('winfixwidth'/'winfixheight').

vim.api.nvim_create_autocmd("VimResized", {
  group = augroup("resize_splits"),
  callback = function()
    -- One tab, or the cmdline window (no switching tabs there): this tab only
    if vim.fn.tabpagenr("$") == 1 or vim.fn.getcmdwintype() ~= "" then
      pcall(vim.cmd, "wincmd =")
      return
    end
    -- tabdo ends in the last tab: go back, via the previous tab so that
    -- g<Tab> still goes there (LazyVim only returns to the current one)
    local current, previous = vim.fn.tabpagenr(), vim.fn.tabpagenr("#")
    vim.cmd("tabdo wincmd =")
    if previous > 0 then
      vim.cmd("tabnext " .. previous)
    end
    vim.cmd("tabnext " .. current)
  end,
})

--- }}}

-- Go to last location when opening a buffer {{{
-- Reopen files where the cursor was last time (the '" mark, kept in shada),
-- with its folds open and the line centered.
-- Like vim's defaults.vim, and :h restore-cursor. Not in commit messages and
-- rebase todos (new text each time), hex dumps or diffs.

vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup("last_loc"),
  callback = function(ev)
    -- Filetype detection's autocmds are defined before plugin/ files run, so
    -- it's usually set by now. Otherwise ask for it (0.8+: older
    -- vim.filetype.match() takes other arguments)
    local ft = vim.bo[ev.buf].filetype
    if ft == "" and vim.fn.has("nvim-0.8") == 1 then
      ft = vim.filetype.match({ buf = ev.buf }) or ""
    end
    if ft:find("commit") or ft == "gitrebase" or ft == "xxd" or vim.wo.diff then
      return
    end
    local line = vim.api.nvim_buf_get_mark(ev.buf, '"')[1]
    local last = vim.api.nvim_buf_line_count(ev.buf)
    if line >= 1 and line <= last then
      -- zv: open folds to show the cursor line ({{{ }}} markers start closed).
      -- zz: center it (the scroll position itself isn't saved in shada).
      vim.cmd('normal! g`"zvzz')
      -- Near the end of the file, centering leaves ~ lines below it: put the
      -- last line at the bottom of the window instead (like vim-lastplace)
      if vim.fn.line("w$") == last then
        local view = vim.fn.winsaveview()
        vim.cmd("keepjumps normal! Gzb")
        view.topline = vim.fn.line("w0")
        vim.fn.winrestview(view)
      end
    end
  end,
})

--- }}}

-- Close some filetypes with <q> {{{
-- And keep them out of the buffer list (so out of bufferline and hbac.nvim's
-- count too). Their buffer is deleted: :help, :copen etc. make a new one.

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = {
    "checkhealth",
    "gitsigns-blame",
    "help",
    "qf",
  },
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false
    -- Scheduled: after the filetype's own ftplugin mappings
    vim.schedule(function()
      if not vim.api.nvim_buf_is_valid(ev.buf) then
        return
      end
      -- Keep a q the buffer has already, e.g. nvim 0.11+'s :checkhealth one,
      -- which also stops checks still running (0.13)
      for _, map in ipairs(vim.api.nvim_buf_get_keymap(ev.buf, "n")) do
        if map.lhs == "q" then
          return
        end
      end
      vim.keymap.set("n", "q", function()
        -- :close fails in the last window (E444); deleting the buffer then
        -- shows another one in it instead
        pcall(vim.cmd, "close")
        pcall(vim.api.nvim_buf_delete, ev.buf, { force = true })
      end, { buffer = ev.buf, silent = true, desc = "Quit buffer" })
    end)
  end,
})

--- }}}

-- Unlist man pages opened inline {{{
-- From :Man and K. nvim's man ftplugin already closes them with q.

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("man_unlisted"),
  pattern = "man",
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false
  end,
})

--- }}}

-- Wrap in text filetypes {{{

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("wrap"),
  pattern = { "text", "plaintex", "typst", "gitcommit", "markdown", "quarto", "rmd" },
  callback = function()
    vim.opt_local.wrap = true
  end,
})

--- }}}

-- Re-apply .editorconfig when the filetype changes {{{
-- nvim applies it on BufRead, after the ftplugin, but a later filetype change
-- (:filetype detect, :set ft=..., lualine's filetype menu) runs the ftplugin
-- again, which can reset 'shiftwidth' etc. (python: 4).

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("editorconfig_filetype"),
  callback = function(ev)
    -- What nvim's editorconfig plugin applied (a table), or false if it's
    -- disabled for this buffer. Nil: not applied yet, the BufRead coming up
    -- does it (FileType runs first when opening a file).
    if type(vim.b[ev.buf].editorconfig) == "table" and vim.g.editorconfig ~= false then
      local ok, editorconfig = pcall(require, "editorconfig") -- 0.9+
      if ok then
        editorconfig.config(ev.buf)
      end
    end
  end,
})

--- }}}

-- Auto create dir when saving a file {{{
-- In case some intermediate directory does not exist: :e new/dir/file, :w
-- (else E212). Not for URLs like fugitive:// or oil://.

vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup("auto_create_dir"),
  callback = function(ev)
    if ev.match:match("^%w%w+:[\\/][\\/]") then
      return
    end
    local file = vim.uv.fs_realpath(ev.match) or ev.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

--- }}}

-- Terminals start in insert mode, <Esc><Esc> leaves it {{{
-- <CR> in normal mode enters it again.
-- Keymaps are buffer-local, set as each terminal opens.

vim.api.nvim_create_autocmd("TermOpen", {
  group = augroup("term_setup"),
  pattern = "term://*",
  callback = function(ev)
    vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], { buffer = ev.buf, silent = true, desc = "Exit terminal mode" })
    vim.keymap.set("n", "<CR>", "i", { buffer = ev.buf, silent = true, desc = "Enter terminal mode" })

    -- Only if it's the current buffer: a plugin may start a terminal in a
    -- hidden buffer, and then this would put the current one in Insert mode
    if ev.buf == vim.api.nvim_get_current_buf() then
      vim.cmd("startinsert")
      -- No line numbers or signs in terminals (0.10+ does this itself)
      if vim.fn.has("nvim-0.10") == 0 then
        vim.opt_local.number, vim.opt_local.signcolumn = false, "no"
      end
    end
  end,
})

--- }}}

-- Shorter 'timeoutlen' in terminal mode {{{
-- Because of <Esc><Esc>, a single Esc reaches the terminal app only after
-- 'timeoutlen'. Shorten it in terminal mode so Esc-heavy apps (vi-mode shell,
-- fzf, lazygit) lag less. The same value is the double-tap window, so not
-- too short: 150ms was easy to miss.

local term_timeoutlen = 250
local saved_timeoutlen

vim.api.nvim_create_autocmd("ModeChanged", {
  group = augroup("term_timeoutlen"),
  pattern = { "*:t", "t:*" },
  callback = function()
    if vim.v.event.new_mode == "t" then
      saved_timeoutlen = saved_timeoutlen or vim.o.timeoutlen
      vim.o.timeoutlen = term_timeoutlen
    elseif saved_timeoutlen then
      vim.o.timeoutlen = saved_timeoutlen
      saved_timeoutlen = nil
    end
  end,
})

--- }}}

-- Treesitter highlighting for languages whose parsers ship with nvim {{{

if vim.fn.has("nvim-0.10") == 1 then
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("BundledTreesitter", { clear = true }),
    pattern = { "c", "lua", "vim", "markdown", "query" }, -- help: nvim's own ftplugin
    callback = function(ev)
      pcall(vim.treesitter.start, ev.buf) -- no-op if this build lacks the parser
    end,
  })
end

--- }}}
