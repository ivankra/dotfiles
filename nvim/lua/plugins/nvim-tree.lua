return {
  {
    "nvim-tree/nvim-tree.lua",
    dev = true,
    lazy = false,
    event = "VimEnter",
    dependencies = { vim.g.icons_provider },
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
        filters = {
          -- Do not filter out hidden/ignored files by default (toggle with H/I)
          dotfiles = false,
          git_ignored = false,
        },
        renderer = {
          -- Don't append /.. to the path of root folder
          root_folder_label = ":~",
          -- Don't add weird highlights to README/Makefile/etc
          special_files = {},
          icons = {
            modified_placement = "signcolumn",
            git_placement = "right_align",
            glyphs = {
              git = {
                unstaged =  "M",  -- ✗ 
                staged =    "A",  -- ✓ 
                unmerged =  "C",  -- 
                renamed =   "R",  -- ➜
                untracked = "U",  -- ★ 
                deleted =   "D",
                ignored =   "I",  -- ◌ 
              }
            }
          }
        }
      }
    end,
  }
}

-- return {
--   {
--     "nvim-neo-tree/neo-tree.nvim",
--     dev = true,
--     dependencies = {
--       vim.g.icons_provider,
--       "nvim-lua/plenary.nvim",
--       "MunifTanjim/nui.nvim",
--     },
--     keys = {
--       { "<C-b>", ":Neotree toggle<CR>", desc = "Toggle Explorer" },
--       { "<leader>e", ":Neotree toggle<CR>", desc = "Toggle Explorer" },
--     },
--   },
-- }
