return {
  -- Icons. Requires Nerd patched font.
  {
    "nvim-mini/mini.icons",
    dev = true,
    opts = {},
    init = function()
      package.preload["nvim-web-devicons"] = function()
        require("mini.icons").mock_nvim_web_devicons()
        return package.loaded["nvim-web-devicons"]
      end
    end,
  },

  -- Bufferline
  {
    "akinsho/bufferline.nvim",
    dev = true,
    event = "VimEnter",
    dependencies = { vim.g.icons_provider },
    opts = {
      options = {
        always_show_bufferline = false,  -- hide if only one buffer
        separator_style = "slant",
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
      { "<S-PageUp>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev buffer" },
      { "<S-PageDown>", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
      { "<leader>bl", "<cmd>BufferLineCloseLeft<cr>", desc = "Delete buffers to the Left" },
      { "<leader>bo", "<cmd>BufferLineCloseOthers<cr>", desc = "Delete Other buffers" },
      { "<leader>br", "<cmd>BufferLineCloseRight<cr>", desc = "Delete buffers to the Right" },
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

  -- Modern take on vidir, editable file explorer buffers
  {
    "stevearc/oil.nvim",
    dev = true,
    opts = {
      columns = { "icon", "permissions", "size", "mtime" },
    }
  },

  -- Fuzzy search
  {
    "nvim-telescope/telescope.nvim",
    dev = true,
    cmd = "Telescope",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
      { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent Files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help Tags" },
      { "<leader>fk", "<cmd>Telescope keymaps<cr>", desc = "Keymaps" },
      { "<leader>fc", "<cmd>Telescope commands<cr>", desc = "Commands" },
      { "<leader>fd", "<cmd>Telescope diagnostics<cr>", desc = "Diagnostics" },
      { "<leader>fs", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Document Symbols" },
    },
  },

  -- Key bindings popup
  {
    "folke/which-key.nvim",
    dev = true,
    event = "VeryLazy",
    dependencies = { vim.g.icons_provider },
    opts = {
      preset = "helix",  -- show floating window at the right
      spec = {
        { "<leader>b", group = "buffer" },
        { "<leader>f", group = "file/find" },
        { "<leader>u", group = "ui" },
        { "<leader>g", group = "git" },
        { "<leader>gh", group = "hunks" },
      }
    },
    keys = {
      { "<leader>?", ":WhichKey<CR>" },
    }
  },

  -- Toggleable terminal on Ctrl+`
  {
    "akinsho/toggleterm.nvim",
    dev = true,
    -- <C-`> is sent as <C-Space> (NUL) by gnome-terminal
    opts = {
      open_mapping = { [[<C-`>]], [[<C-Space>]] }
    }
  },

  -- Visual git integration: highlight changed lines, blame, stage hunks
  {
    "lewis6991/gitsigns.nvim",
    dev = true,
    event = "VimEnter",
    opts = {
      signcolumn = vim.g.gitsigns_signcolumn,
      signs = {
        -- add = { text = "▎" },
        -- change = { text = "▎" },
        -- changedelete = { text = "▎" },
        -- untracked = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
      },
      signs_staged = {
        -- add = { text = "▎" },
        -- change = { text = "▎" },
        -- changedelete = { text = "▎" },
        delete = { text = "" },
        topdelete = { text = "" },
      },
      -- lazy.nvim passes this table to gitsigns.setup(); keep callback here
      -- so gitsigns actually receives and runs it for attached buffers.
      on_attach = function(buffer)
        local gs = package.loaded.gitsigns

        local function map(mode, l, r, desc)
          vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc, silent = true })
        end

        map("n", "]h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "]c", bang = true })
          else
            gs.nav_hunk("next")
          end
        end, "Next Hunk")
        map("n", "[h", function()
          if vim.wo.diff then
            vim.cmd.normal({ "[c", bang = true })
          else
            gs.nav_hunk("prev")
          end
        end, "Prev Hunk")
        map("n", "]H", function() gs.nav_hunk("last") end, "Last Hunk")
        map("n", "[H", function() gs.nav_hunk("first") end, "First Hunk")
        map({ "n", "x" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
        map({ "n", "x" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
        map("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
        map("n", "<leader>ghu", gs.undo_stage_hunk, "Undo Stage Hunk")
        map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
        map("n", "<leader>ghp", gs.preview_hunk_inline, "Preview Hunk Inline")
        map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, "Blame Line")
        map("n", "<leader>ghB", function() gs.blame() end, "Blame Buffer")
        map("n", "<leader>ghd", gs.diffthis, "Diff This")
        map("n", "<leader>ghD", function() gs.diffthis("~") end, "Diff This ~")
        map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
      end,
    },
  },

  -- vim-fugitive: classic vim git plugin
  -- :G/:Git command with the same interface as CLI git
  { "tpope/vim-fugitive", dev = true },

  -- vim-projectionist: switch between alternate files (.c/.h)
  -- Config in plugin/projectionist.vim
  { "tpope/vim-projectionist", dev = true },

  -- Filetype plugins
  { "google/vim-jsonnet", dev = true, ft = { "jsonnet", "libsonnet" } },
  { "nathangrigg/vim-beancount", dev = true, ft = "beancount" },

  -- Dependencies
  { "nvim-lua/plenary.nvim", dev = true, lazy = true },
  { "MunifTanjim/nui.nvim", dev = true, lazy = true },
}
