-- Git status as letters, nvim-tree's default glyphs in the comments
-- stylua: ignore
local git_glyphs = {
  unstaged =  "M",  -- ✗ 
  staged =    "A",  -- ✓ 
  unmerged =  "C",  -- 
  renamed =   "R",  -- ➜
  untracked = "U",  -- ★ 
  deleted =   "D",
  ignored =   "I",  -- ◌ 
}

return {
  {
    "nvim-tree/nvim-tree.lua",
    dev = true,
    -- Lazy: oil.nvim handles directory buffers, so nothing needs the tree at startup
    cmd = { "NvimTreeToggle", "NvimTreeOpen", "NvimTreeFocus", "NvimTreeFindFile", "NvimTreeFindFileToggle" },
    dependencies = { vim.g.icons_plugin },
    keys = {
      { "<C-B>", ":NvimTreeFindFileToggle<CR>", desc = "Toggle Explorer", silent = true },
      { "<leader>e", ":NvimTreeFindFileToggle<CR>", desc = "Toggle Explorer", silent = true },
    },

    opts = function()
      local api = require("nvim-tree.api")
      local function on_attach(bufnr)
        api.config.mappings.default_on_attach(bufnr)
        -- Delete file with <Del> (in addition to "d")
        vim.keymap.set("n", "<Del>", api.fs.remove, { buffer = bufnr, desc = "Delete" })
        -- Single click to open file/folder
        vim.keymap.set("n", "<LeftRelease>", api.node.open.edit, { buffer = bufnr, desc = "Open" })
      end
      return {
        on_attach = on_attach,
        sync_root_with_cwd = true,
        -- oil.nvim handles directory buffers (`nvim <dir>`, `:e dir/`)
        hijack_directories = { enable = false },
        filters = {
          -- Do not filter out hidden/ignored files by default (toggle with H/I)
          dotfiles = false,
          git_ignored = false,
        },
        filesystem_watchers = {
          enable = true,
        },
        update_focused_file = {
          enable = true, -- automatically focus on current buffer's file
        },
        renderer = {
          -- Don't append /.. to the path of root folder
          root_folder_label = ":~",
          -- Don't add weird highlights to README/Makefile/etc
          special_files = {},
          highlight_git = "all",
          icons = {
            modified_placement = "signcolumn",
            git_placement = "right_align",
            -- Without a Nerd Font: no folder icons, > / v arrows
            show = { folder = vim.g.nerd_font },
            glyphs = {
              git = git_glyphs,
              folder = not vim.g.nerd_font and { arrow_closed = ">", arrow_open = "v" } or nil,
            },
          },
        },
      }
    end,

    init = function()
      -- https://github.com/nvim-tree/nvim-tree.lua/wiki/Auto-Close
      vim.api.nvim_create_autocmd("QuitPre", {
        group = vim.api.nvim_create_augroup("NvimTreeAutoClose", { clear = true }),
        callback = function()
          -- Quitting a float (e.g. a focused LSP hover) leaves the editor
          -- windows open, so the tree stays too
          if vim.api.nvim_win_get_config(0).relative ~= "" then
            return
          end
          local tree_wins = {}
          local floating_wins = {}
          -- Current tab only: with other tabs open, :q here would leave the tree alone in this tab
          local wins = vim.api.nvim_tabpage_list_wins(0)
          for _, w in ipairs(wins) do
            local bufname = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(w))
            if bufname:match("NvimTree_") ~= nil then
              table.insert(tree_wins, w)
            end
            if vim.api.nvim_win_get_config(w).relative ~= "" then
              table.insert(floating_wins, w)
            end
          end
          if 1 == #wins - #floating_wins - #tree_wins then
            -- Should quit, so we close all invalid windows.
            for _, w in ipairs(tree_wins) do
              vim.api.nvim_win_close(w, true)
            end
          end
        end,
      })
    end,
  },
}

-- return {
--   {
--     "nvim-neo-tree/neo-tree.nvim",
--     dev = true,
--     dependencies = {
--       vim.g.icons_plugin,
--       "nvim-lua/plenary.nvim",
--       "MunifTanjim/nui.nvim",
--     },
--     keys = {
--       { "<C-b>", ":Neotree toggle<CR>", desc = "Toggle Explorer" },
--       { "<leader>e", ":Neotree toggle<CR>", desc = "Toggle Explorer" },
--     },
--   },
-- }
