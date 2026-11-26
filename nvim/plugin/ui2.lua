-- ui2: nvim 0.12's new message and command line UI (experimental, :help ui2)
--
-- * The command line shows only while typing a command (cmdheight=0), in
--   place of the statusline.
-- * Messages appear in a borderless corner window and go away after a few
--   seconds, with no "Press ENTER" prompts. g< shows the last one in full.
-- * LSP progress shows (e.g. "3/10 (30%) ⠙ Indexing server"), with each task
--   updated in place rather than adding a message per update.
-- * What the command line used to show is in the statusline instead
--   (lua/plugins/lualine.lua): macro recording, pending keys, search count.

if vim.fn.has("nvim-0.12") == 0 then
  return
end

local ok, ui2 = pcall(require, "vim._core.ui2")
if not ok then
  return
end

local group = vim.api.nvim_create_augroup("dotfiles_ui2", { clear = true })

-- Runs fn, which changes window heights, with 'splitkeep' "screen", as ui2
-- does for 'cmdheight'. Else ("cursor") the text can scroll a line, for some
-- cursor rows. 'splitkeep' is restored even if fn fails.
local function keep_screen(fn)
  local splitkeep = vim.o.splitkeep
  vim.o.splitkeep = "screen"
  local ok, err = pcall(fn)
  vim.o.splitkeep = splitkeep
  if not ok then
    error(err, 0)
  end
end

-- Typing a command takes a row (cmdheight 1): hide the statusline meanwhile,
-- so windows keep their size instead of shifting up a row. Only for the
-- outermost command line, not a nested one (<C-R>= while typing a command).
local laststatus
vim.api.nvim_create_autocmd("CmdlineEnter", {
  group = group,
  callback = function()
    if vim.v.event.cmdlevel == 1 then
      keep_screen(function()
        laststatus, vim.o.laststatus = vim.o.laststatus, 0
      end)
    end
  end,
})

vim.api.nvim_create_autocmd("CmdlineLeave", {
  group = group,
  callback = function()
    if vim.v.event.cmdlevel == 1 and laststatus then
      keep_screen(function()
        -- With 'cmdheight' back to 0 at the same time: ui2 does that only
        -- a moment later, and a frame would show both lines meanwhile
        vim.o.cmdheight = 0
        vim.o.laststatus, laststatus = laststatus, nil
      end)
    end
  end,
})

-- LSP progress: as progress messages in the message window.
-- Roughly as LazyVim (noice): "3/10 (30%) ⠙ Title server".
local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
local tasks = {} -- by message id: { title, frame }
vim.api.nvim_create_autocmd("LspProgress", {
  group = group,
  callback = function(ev)
    local value, client = ev.data.params.value, vim.lsp.get_client_by_id(ev.data.client_id)
    if type(value) ~= "table" or not client then
      return
    end
    local id = ("lsp.%d.%s"):format(client.id, tostring(ev.data.params.token))
    local task = tasks[id] or { frame = 0 }
    task.title = value.title or task.title
    local chunks
    if value.kind == "end" then
      tasks[id] = nil
      chunks = { { "✓ ", "Constant" } }
    else
      tasks[id], task.frame = task, task.frame % #spinner + 1
      local percent = value.percentage and (" (%d%%)"):format(value.percentage) or ""
      chunks = { { (value.message or "") .. percent .. " " }, { spinner[task.frame] .. " ", "Constant" } }
    end
    vim.list_extend(chunks, { { (task.title or "") .. " ", "NonText" }, { client.name, "Title" } })
    vim.api.nvim_echo(chunks, false, {
      id = id,
      kind = "progress",
      source = "vim.lsp",
      status = value.kind == "end" and "success" or "running",
    })
  end,
})

-- Messages: in their own window rather than the command line (targets), with
-- no border. 'winborder' applies to it, unlike to ui2's other windows; set on
-- FileType, so registered before enable(), which creates the windows.
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = "msg",
  callback = function(ev)
    for _, win in ipairs(vim.fn.win_findbuf(ev.buf)) do
      vim.api.nvim_win_set_config(win, { border = "none" })
    end
  end,
})

ui2.enable({ msg = { targets = "msg" } })
vim.opt.cmdheight = 0 -- command line only while typing a command
vim.opt.showcmdloc = "statusline" -- pending keys: in the statusline (%S)

-- ui2 learns of 'cmdheight' once after startup: a prompt then (e.g. for a swap
-- file) has it at 1 meanwhile, which ui2 would keep. So set it again after
-- startup, scheduled: OptionSet, which ui2 follows, doesn't fire in autocmds.
vim.api.nvim_create_autocmd("VimEnter", {
  group = group,
  once = true,
  callback = function()
    vim.schedule(function()
      vim.o.cmdheight = 0
    end)
  end,
})
