-- bufferline.nvim: the buffers as tabs.

-- Close the buffers left of / right of / other than the current one in
-- bufferline order, via a single :Bd so that Cancel on one Save prompt stops
-- the rest too. Bufferline's own BufferLineClose* run close_command once per
-- buffer, so Cancel would only skip that one buffer.
---@param which "left"|"right"|"others"
local function close_buffers(which)
  local elements = require("bufferline").get_elements().elements
  local current = vim.api.nvim_get_current_buf()
  local index
  for i, element in ipairs(elements) do
    if element.id == current then
      index = i
    end
  end
  if not index then
    return
  end
  local ids = {}
  for i, element in ipairs(elements) do
    if (which == "left" and i < index) or (which == "right" and i > index) or (which == "others" and i ~= index) then
      table.insert(ids, element.id)
    end
  end
  if #ids > 0 then
    vim.cmd("Bd " .. table.concat(ids, " "))
  end
end

return {
  {
    "akinsho/bufferline.nvim",
    dev = true,
    event = "VimEnter",
    dependencies = { vim.g.icons_plugin },
    opts = {
      options = {
        always_show_bufferline = false, -- hide if only one buffer
        tab_size = 0, -- tabs as wide as their name (default: padded to 18)
        -- Default is "bdelete! %d", which silently discards unsaved changes.
        -- :Bd (mini.bufremove, lua/plugins/init.lua) asks Save/No/Cancel like :q and keeps
        -- the window layout.
        close_command = "Bd %d",
        right_mouse_command = "Bd %d",
        separator_style = vim.g.nerd_font and "slant" or { "|", "|" },
        -- Names without an icon of their own: the filetype's, not the generic one.
        -- Else (nil) bufferline's own lookup by name.
        get_element_icon = function(element)
          local ok, devicons = pcall(require, "nvim-web-devicons")
          local name = vim.fn.fnamemodify(element.path, ":t")
          if ok and element.filetype ~= "" and not devicons.get_icon(name, nil, { default = false }) then
            return devicons.get_icon_by_filetype(element.filetype, { default = false })
          end
        end,
        -- Close buttons: a plain ×, not the default Nerd Font glyph, which
        -- WezTerm draws two cells wide (square glyph followed by a space)
        buffer_close_icon = "×",
        close_icon = "×",
        -- Without a Nerd Font: plain characters for its other glyphs
        modified_icon = not vim.g.nerd_font and "+" or nil,
        left_trunc_marker = not vim.g.nerd_font and "<" or nil,
        right_trunc_marker = not vim.g.nerd_font and ">" or nil,
        indicator = not vim.g.nerd_font and { style = "none" } or nil,
        offsets = {
          {
            filetype = "NvimTree",
            text = "File Explorer",
            highlight = "Directory",
            text_align = "left",
            separator = true,
          },
        },
      },
      -- Disable italic for active tab
      highlights = {
        buffer_selected = { italic = false },
      },
    },
    keys = {
      { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev buffer" },
      { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
      -- Insert mode too, as nvim/init.lua's :bprevious/:bnext fallbacks
      { "<S-PageUp>", "<cmd>BufferLineCyclePrev<cr>", mode = { "n", "i" }, desc = "Prev buffer" },
      { "<S-PageDown>", "<cmd>BufferLineCycleNext<cr>", mode = { "n", "i" }, desc = "Next buffer" },
      {
        "<leader>bl",
        function()
          close_buffers("left")
        end,
        desc = "Delete buffers to the Left",
      },
      {
        "<leader>bo",
        function()
          close_buffers("others")
        end,
        desc = "Delete Other buffers",
      },
      {
        "<leader>br",
        function()
          close_buffers("right")
        end,
        desc = "Delete buffers to the Right",
      },
      -- Alt+N to switch to buffer N (vscode-like keymaps)
      { "<A-1>", "<cmd>BufferLineGoToBuffer 1<cr>", desc = "Go to buffer 1" },
      { "<A-2>", "<cmd>BufferLineGoToBuffer 2<cr>", desc = "Go to buffer 2" },
      { "<A-3>", "<cmd>BufferLineGoToBuffer 3<cr>", desc = "Go to buffer 3" },
      { "<A-4>", "<cmd>BufferLineGoToBuffer 4<cr>", desc = "Go to buffer 4" },
      { "<A-5>", "<cmd>BufferLineGoToBuffer 5<cr>", desc = "Go to buffer 5" },
      { "<A-6>", "<cmd>BufferLineGoToBuffer 6<cr>", desc = "Go to buffer 6" },
      { "<A-7>", "<cmd>BufferLineGoToBuffer 7<cr>", desc = "Go to buffer 7" },
      { "<A-8>", "<cmd>BufferLineGoToBuffer 8<cr>", desc = "Go to buffer 8" },
      { "<A-9>", "<cmd>BufferLineGoToBuffer 9<cr>", desc = "Go to buffer 9" },
      { "<A-0>", "<cmd>BufferLineGoToBuffer 10<cr>", desc = "Go to buffer 10" },
    },
  },
}
