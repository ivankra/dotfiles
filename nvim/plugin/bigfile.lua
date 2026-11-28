-- Big files: fewer features
--
-- Following snacks.bigfile/LazyVim: set ft=bigfile to turn off heavy plugins,
-- while keeping real ft in 'syntax' to enable regex-based syntax highlighting.
--
-- :set ft=<real> to turn everything back on.

-- 0.8+: vim.filetype.match({ ... }). Once: re-sourcing would wrap the wrapper
if vim.fn.has("nvim-0.8") == 0 or vim.g.loaded_bigfile then
  return
end
vim.g.loaded_bigfile = true

-- Big: >1.5MB or >1000 avg chars/line (e.g. minified JS/JSON)
-- Lower than vimrc's 10MB - nvim has more features to turn off.
local size_limit = 1.5 * 1024 * 1024
local line_length_limit = 1000

-- The buffer, not the file on disk: a .gz is bigger unpacked. Unloaded
-- buffers have no lines
local function is_big(buf)
  if not vim.api.nvim_buf_is_loaded(buf) then
    return false
  end
  local lines = vim.api.nvim_buf_line_count(buf)
  local size = vim.api.nvim_buf_get_offset(buf, lines)
  return size > size_limit or (size - lines) / lines > line_length_limit
end

local match = vim.filetype.match

-- From the name and first lines only: most detectors read at most 1000,
-- sh's reads them all (66ms for 2.6MB). Returns ft, on_detect
local function real_filetype(buf, filename)
  filename = filename or vim.api.nvim_buf_get_name(buf)
  return match({
    filename = filename ~= "" and filename or nil,
    contents = vim.api.nvim_buf_get_lines(buf, 0, 1000, false),
  })
end

-- Big buffers' real filetype, for 'syntax'. Kept for reloads: they fire
-- FileType again, and their detection fails for some (sh: did_filetype())
local real_filetypes = {}

-- Wrapped, not a vim.filetype.add() rule: exact filenames (tags, Cargo.lock)
-- are matched before any rule. nvim's detection (filetype.lua) calls this,
-- then on_detect (sets e.g. b:is_bash for sh syntax) and :setf.
---@diagnostic disable-next-line: duplicate-set-field
function vim.filetype.match(args)
  local buf = args.buf == 0 and vim.api.nvim_get_current_buf() or args.buf
  if not buf or not is_big(buf) then
    return match(args)
  end
  local ft, on_detect = real_filetype(buf, args.filename)
  real_filetypes[buf] = ft or real_filetypes[buf]
  return "bigfile", on_detect
end

local group = vim.api.nvim_create_augroup("dotfiles_bigfile", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "bigfile",
  callback = function(ev)
    local buf = ev.buf
    -- Missing if set by hand (:set ft=bigfile)
    local ft = real_filetypes[buf] or real_filetype(buf) or ""

    -- Reloads (:e, autoread) fire this again: reapply, but notify once (logs)
    local notified = vim.b[buf].bigfile
    vim.b[buf].bigfile = true
    vim.b[buf].completion = false -- blink.cmp
    -- matchparen scans the whole (long) line, up to 300ms per cursor move.
    -- Per buffer, unlike snacks' global :NoMatchParen
    vim.b[buf].matchparen_timeout = 1
    vim.b[buf].matchparen_insert_timeout = 1
    -- This window; marker folding rescans the file on each change
    vim.opt_local.foldmethod = "manual"
    vim.opt_local.list = false
    -- Scheduled: syntax.vim's FileType autocmd sets "bigfile" after this one.
    -- Skipped if the filetype changed meanwhile (modeline, :set ft=)
    vim.schedule(function()
      if vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].filetype == "bigfile" then
        vim.bo[buf].syntax = ft
      end
    end)

    if notified then
      return
    end
    local size = vim.fn.getfsize(vim.api.nvim_buf_get_name(buf))
    vim.notify(
      ("Big file%s: heavy neovim plugins disabled.%s"):format(
        size > 0 and (" (%.1fMB)"):format(size / 1024 / 1024) or "",
        ft ~= "" and (" :set ft=%s to turn them on"):format(ft) or ""
      )
    )
  end,
})

-- Another filetype set by hand: undo. LSP, treesitter and colorizer restart
-- on FileType by themselves, gitsigns and guess-indent only on read.
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  callback = function(ev)
    local buf = ev.buf
    if ev.match == "bigfile" or not vim.b[buf].bigfile then
      return
    end
    vim.b[buf].bigfile = nil
    vim.b[buf].completion = nil
    vim.b[buf].matchparen_timeout = nil
    vim.b[buf].matchparen_insert_timeout = nil
    -- Global values unless the new ftplugin set its own, in every window
    -- (splits copied ours)
    for _, win in ipairs(vim.fn.win_findbuf(buf)) do
      vim.api.nvim_win_call(win, function()
        if vim.wo.foldmethod == "manual" then
          vim.cmd("setlocal foldmethod<")
        end
        if not vim.wo.list then
          vim.cmd("setlocal list<")
        end
      end)
    end
    if package.loaded.gitsigns then
      require("gitsigns").attach(buf)
    end
    -- context: still respects .editorconfig indent settings
    if package.loaded["guess-indent"] then
      require("guess-indent").set_from_buffer(buf, true, true)
    end
  end,
})
