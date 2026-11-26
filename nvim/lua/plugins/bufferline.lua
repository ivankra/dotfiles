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

-- Drag a bufferline tab with the mouse: pressing a tab switches to it and
-- starts the drag (left_mouse_command below), <LeftDrag> on the tabline moves
-- it to the tab under the mouse, <LeftRelease> ends it. Else these keys do
-- what they always do. Not <LeftMouse>: mapping it would stop bufferline's
-- click handler.
local dragging = false

-- Buffer whose tab is at screen column col, as bufferline's hover finds it
-- (ui.lua on_hover_over): after nvim-tree's offset, the visible tabs' widths
local function tab_at(col)
  local state = require("bufferline.state")
  local pos = state.left_offset_size
  for _, item in ipairs(state.visible_components) do
    if col > pos and col <= pos + item.length then
      return item.id
    end
    pos = pos + item.length
  end
end

-- Also terminal and : line mode: a tab clicked there ends its drag there
local drag_modes = { "n", "i", "v", "t", "c" }

-- Colored file icon on the current buffer's tab only, the others in their
-- tab's text color. Bufferline's color_icons option is all or nothing: wrap
-- set_icon_highlight(), which makes the icon's highlight from the devicon's
-- group, to make it from the tab's text group instead.
local function plain_inactive_icons()
  local highlights = require("bufferline.highlights")
  local visibility = require("bufferline.constants").visibility
  local set_icon_highlight = highlights.set_icon_highlight
  highlights.set_icon_highlight = function(state, hls, base_hl)
    if state ~= visibility.SELECTED then
      -- Visible in another window, or hidden
      base_hl = (state == visibility.INACTIVE and hls.buffer_visible or hls.background).hl_group
    end
    return set_icon_highlight(state, hls, base_hl)
  end
end

local function drag_keymaps()
  vim.keymap.set(drag_modes, "<LeftDrag>", function()
    if not dragging then
      return "<LeftDrag>"
    end
    local pos = vim.fn.getmousepos()
    local target = pos.screenrow == 1 and tab_at(pos.screencol)
    if target then
      vim.schedule(function()
        local ids = vim.tbl_map(function(e)
          return e.id
        end, require("bufferline").get_elements().elements)
        local from = vim.fn.index(ids, vim.api.nvim_get_current_buf())
        local to = vim.fn.index(ids, target)
        -- One step at a time: bufferline's move_to() swaps the two tabs
        for _ = 1, math.abs(to - from) do
          require("bufferline.commands").move(to > from and 1 or -1)
        end
      end)
    end
    return ""
  end, { expr = true, desc = "Drag a buffer tab" })
  vim.keymap.set(drag_modes, "<LeftRelease>", function()
    if not dragging then
      return "<LeftRelease>"
    end
    dragging = false
    return ""
  end, { expr = true, desc = "End dragging a buffer tab" })
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
        -- Switch to it (the default) and start a drag (drag_keymaps)
        left_mouse_command = function(buf)
          dragging = true
          vim.api.nvim_set_current_buf(buf)
        end,
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
      -- Bufferline's defaults for the colorscheme, then these
      highlights = function(defaults)
        local fill = defaults.highlights.fill.bg
        return {
          -- Disable italic for active tab
          buffer_selected = { italic = false },
          -- No │ between nvim-tree's offset and the first tab: a gap like
          -- between tabs
          offset_separator = { fg = fill, bg = fill },
        }
      end,
    },
    config = function(_, opts)
      require("bufferline").setup(opts)
      plain_inactive_icons()
      drag_keymaps()
    end,
    keys = {
      { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev buffer" },
      { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
      -- Insert mode too, as plugin/keymaps.lua's :bprevious/:bnext fallbacks
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
