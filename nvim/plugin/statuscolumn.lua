-- Status column:
--   * line number
--   * sign column: one sign wide, shared by gitsigns and diagnostics,
--     with clickable signs.

vim.opt.number = true -- Show line numbers
vim.opt.numberwidth = 3
vim.opt.signcolumn = "yes" -- Always show sign column

-- 'statuscolumn' is 0.9+, and %l only follows 'number'/'relativenumber' since 0.10
if vim.fn.has("nvim-0.10") == 1 then
  vim.opt.statuscolumn = "%3l%@v:lua.SignClick@%s%X"
end

-- Click on the sign column, for the sign shown (the highest priority one):
--   git hunk:   left: preview inline, right: in a float
--   diagnostic: left: in a float, right: code actions
-- Global: 'statuscolumn' click regions (%@) only call v:lua.<global>.
function _G.SignClick(_, _, button)
  local pos = vim.fn.getmousepos()
  if pos.line == 0 then
    return
  end
  vim.api.nvim_set_current_win(pos.winid)
  vim.api.nvim_win_set_cursor(pos.winid, { pos.line, 0 })

  local row = pos.line - 1
  local signs = vim.api.nvim_buf_get_extmarks(0, -1, { row, 0 }, { row, -1 }, { type = "sign", details = true })
  table.sort(signs, function(a, b)
    return (a[4].priority or 0) > (b[4].priority or 0)
  end)
  if not signs[1] then
    return
  end
  local ns = ""
  for name, id in pairs(vim.api.nvim_get_namespaces()) do
    if id == signs[1][4].ns_id then
      ns = name
    end
  end

  -- Scheduled, after nvim has finished handling the click: else the cursor
  -- events it sends close a float right away (as statuscol.nvim does too)
  vim.schedule(function()
    if ns:find("diagnostic") then
      if button == "l" then
        vim.diagnostic.open_float()
      elseif button == "r" then
        vim.lsp.buf.code_action()
      end
    elseif ns:find("^gitsigns") then
      if button == "l" then
        require("gitsigns").preview_hunk_inline()
      elseif button == "r" then
        require("gitsigns").preview_hunk()
      end
    end
  end)
end

-- A wrapped line's continuation marked where its line number would be
-- (busier screen; else 'showbreak', see init.lua):
-- if vim.fn.has("nvim-0.10") == 1 then
--  vim.opt.statuscolumn = "%{%v:virtnum > 0 && (&nu || &rnu) ? '%=↪' : '%3l'%}%s"
-- end

-- A LineNr-colored bar in the sign column when there are no signs, to blend in with gitsigns:
-- _G.get_statuscol = function()
--   local signs = vim.fn.sign_getplaced(vim.api.nvim_get_current_buf(), {group = "*", lnum = vim.v.lnum})[1].signs
--   if #signs > 0 then return "%3l%s" else return "%3l%#LineNr#│%" end
-- end
-- vim.o.statuscolumn = "%!v:lua.get_statuscol()"
