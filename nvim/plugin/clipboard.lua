-- Yank/paste via the system clipboard.
-- With X11/Wayland (also ssh -X) or locally: a clipboard tool (xclip, ...).
-- Else, e.g. over SSH: copy-only OSC 52 (nvim 0.10+).
-- Paste OSC 52 is often unimplemented or blocked, so skip it.

local function use_osc52()
  if #vim.api.nvim_list_uis() == 0 then -- headless: no terminal to send to
    return false
  end
  -- Before SSH_CONNECTION: it can leak into a local terminal's env
  if vim.env.DISPLAY or vim.env.WAYLAND_DISPLAY then
    return false
  end
  if vim.env.SSH_CONNECTION then
    return true
  end
  return vim.fn.has("mac") == 0 and vim.fn.has("win32") == 0
end

if vim.g.clipboard == nil and use_osc52() and vim.fn.has("nvim-0.10") == 1 then
  local osc52 = require("vim.ui.clipboard.osc52")
  local last = {}
  local function copy(reg)
    local send = osc52.copy(reg)
    return function(lines, regtype)
      last[reg] = { lines, regtype }
      send(lines, regtype)
    end
  end
  local function paste(reg)
    return function()
      return last[reg] or { {}, "v" }
    end
  end
  vim.g.clipboard = {
    name = "OSC 52 (copy only)",
    copy = { ["+"] = copy("+"), ["*"] = copy("*") },
    paste = { ["+"] = paste("+"), ["*"] = paste("*") },
  }
end

-- Only with a clipboard (a tool or the provider above), else nvim complains
-- "No provider" on yank. Deferred: looking for a tool slows down startup.
vim.schedule(function()
  if vim.fn.has("clipboard") == 1 then
    vim.opt.clipboard = "unnamedplus"
  end
end)
