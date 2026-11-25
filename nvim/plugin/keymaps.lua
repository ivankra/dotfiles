-- Global key bindings

-- Window navigation: Ctrl+hjkl/arrows, Shift+arrows {{{
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Go to left window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Go to lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Go to upper window" })
-- Also what the default <C-l> does: clear search highlight, update diffs
vim.keymap.set("n", "<C-l>", "<Cmd>nohlsearch|diffupdate|redraw!<CR><C-w>l", { desc = "Go to right window + redraw" })
vim.keymap.set("n", "<S-Left>", "<C-w><C-h>", { desc = "Go to left window" })
vim.keymap.set("n", "<S-Down>", "<C-w><C-j>", { desc = "Go to lower window" })
vim.keymap.set("n", "<S-Up>", "<C-w><C-k>", { desc = "Go to upper window" })
vim.keymap.set("n", "<S-Right>", "<C-w>l", { desc = "Go to right window", silent = true })
--- }}}

-- Switch buffers: Shift+PgUp/PgDown, [b, ]b, <leader>bb {{{
-- Bufferline will override some of these when loaded on VimEnter, after this file
vim.keymap.set({ "n", "i" }, "<S-PageUp>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
vim.keymap.set({ "n", "i" }, "<S-PageDown>", "<cmd>bnext<cr>", { desc = "Next buffer" })
vim.keymap.set("n", "[b", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
vim.keymap.set("n", "]b", "<cmd>bnext<cr>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to other buffer" })
--- }}}

-- Add comment below/above: gco/gcO {{{
-- Opens a line, comments a placeholder x with the built-in gcc (0.10+), then
-- deletes the x, staying in insert mode after the comment marker
if vim.fn.has("nvim-0.10") == 1 then
  vim.keymap.set("n", "gco", "o<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add comment below" })
  vim.keymap.set("n", "gcO", "O<esc>Vcx<esc><cmd>normal gcc<cr>fxa<bs>", { desc = "Add comment above" })
end
--- }}}

-- Toggle quickfix/location list: <leader>xq/<leader>xl {{{
-- Errors (e.g. E776: No location list) as a notification
local function toggle_list(is_open, close, open)
  local ok, err = pcall(is_open() and close or open)
  if not ok then
    vim.notify(err, vim.log.levels.ERROR)
  end
end
vim.keymap.set("n", "<leader>xq", function()
  toggle_list(function()
    return vim.fn.getqflist({ winid = 0 }).winid ~= 0
  end, vim.cmd.cclose, vim.cmd.copen)
end, { desc = "Quickfix list" })
vim.keymap.set("n", "<leader>xl", function()
  toggle_list(function()
    return vim.fn.getloclist(0, { winid = 0 }).winid ~= 0
  end, vim.cmd.lclose, vim.cmd.lopen)
end, { desc = "Location list" })
--- }}}

-- Navigate diagnostics: ]e/[e errors, ]w/[w warnings {{{
if vim.diagnostic.jump then
  local function diagnostic_goto(next, severity)
    return function()
      vim.diagnostic.jump({
        count = (next and 1 or -1) * vim.v.count1,
        severity = vim.diagnostic.severity[severity],
      })
    end
  end
  vim.keymap.set("n", "]e", diagnostic_goto(true, "ERROR"), { desc = "Next error" })
  vim.keymap.set("n", "[e", diagnostic_goto(false, "ERROR"), { desc = "Prev error" })
  vim.keymap.set("n", "]w", diagnostic_goto(true, "WARN"), { desc = "Next warning" })
  vim.keymap.set("n", "[w", diagnostic_goto(false, "WARN"), { desc = "Prev warning" })
end
--- }}}

-- Clear search highlight: Esc
vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })

-- Current file's directory: <leader>cd
vim.keymap.set("n", "<leader>cd", ":cd %:p:h<CR>", { desc = "Change to current file's directory" })

-- Typing %%/ in command mode expands to current file's directory
-- fnameescape(): a dir like notes#1 would otherwise expand # to the alternate file
vim.cmd([[cabbr <expr> %% getcmdtype() == ':' ? fnameescape(expand('%:p:h')) : '%%']])
