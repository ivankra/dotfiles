-- Dockerized nvim configurations (for lazy.nvim) with extra plugins to experiment with.
-- Automatically sourced via ~/.dotfiles/nvim/lua/plugins/dvim.lua symlink.

if not vim.g.in_container then
  return {}
end

local host = vim.uv.os_gethostname() -- set by `podman --hostname`

local function treesitter_mason() -- {{{
  --Unattended install (:MasonInstall blocks when headless; nvim-treesitter's install() is async, so wait):
  --RUN nvim --headless "+Lazy! sync" "+qa"
  --RUN nvim --headless "+MasonInstall lua-language-server pyright typescript-language-server stylua ruff prettier shfmt" "+qa"
  --RUN nvim --headless "+lua require('nvim-treesitter').install('all'):wait(1800000)" "+qa"

  return {
    -- Treesitter: syntax highlighting, indentation, folding
    -- The main branch is a rewrite: needs nvim 0.11+ and the tree-sitter CLI,
    -- doesn't support lazy-loading and doesn't enable any feature by itself.
    {
      "nvim-treesitter/nvim-treesitter",
      branch = "main",
      lazy = false,
      build = ":TSUpdate",
      config = function()
        local function setup(buf)
          -- Errors if there's no parser for this filetype
          if not pcall(vim.treesitter.start, buf) then
            return
          end
          -- Only with an indents query: without one, nvim-treesitter's
          -- indentexpr has no rules and flattens indentation. E.g. nvim
          -- bundles the C parser, but the queries come with install() below.
          local lang = vim.treesitter.language.get_lang(vim.bo[buf].filetype)
          local ok, query = pcall(vim.treesitter.query.get, lang, "indents")
          if ok and query then
            vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
          local win = vim.fn.bufwinid(buf)
          if win ~= -1 then
            vim.wo[win][0].foldmethod = "expr"
            vim.wo[win][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
            vim.wo[win][0].foldlevel = 99 -- start with all folds open
          end
        end

        vim.api.nvim_create_autocmd("FileType", {
          group = vim.api.nvim_create_augroup("DvimTreesitter", { clear = true }),
          callback = function(ev)
            setup(ev.buf)
          end,
        })

        -- Async, and skips parsers that are already installed. On a fresh
        -- volume, files opened meanwhile got FileType before their parser or
        -- queries existed: no highlighting, or (with a parser bundled with
        -- nvim, e.g. lua) no indents query yet. Set them all up again once
        -- the install has finished; restarting highlighting is harmless.
        require("nvim-treesitter")
          .install({
            "lua",
            "vim",
            "vimdoc",
            "bash",
            "python",
            "javascript",
            "typescript",
            "json",
            "yaml",
            "markdown",
          })
          :await(function()
            vim.schedule(function()
              for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                if vim.api.nvim_buf_is_loaded(buf) and vim.bo[buf].filetype ~= "" then
                  setup(buf)
                end
              end
            end)
          end)
      end,
    },

    -- Mason: portable package manager for LSP servers, DAP, linters, formatters
    {
      "mason-org/mason.nvim",
      cmd = "Mason",
      build = ":MasonUpdate",
      opts = {},
    },

    -- Mason-lspconfig: bridge between mason and lspconfig
    {
      "mason-org/mason-lspconfig.nvim",
      dependencies = { "mason-org/mason.nvim" },
      opts = {
        ensure_installed = { "lua_ls", "pyright", "ts_ls" },
      },
    },

    -- LSP: the host setup (nvim/lua/plugins/lsp.lua) enables servers found
    -- on $PATH. Loading mason first puts the servers it installed there.
    {
      "neovim/nvim-lspconfig",
      dependencies = { "mason-org/mason-lspconfig.nvim" },
    },
  }
end
-- }}}

if host == "dvim" then -- (treesitter + mason) {{{
  return treesitter_mason()
  --- }}}
elseif host == "dvim-claudecode" then -- (+claudecode.nvim) {{{
  return vim.list_extend(treesitter_mason(), {
    {
      "coder/claudecode.nvim",
      dependencies = { "folke/snacks.nvim" }, -- its terminal, else nvim's
      config = true,
      -- stylua: ignore
      cmd = {
        "ClaudeCode", "ClaudeCodeFocus", "ClaudeCodeSelectModel", "ClaudeCodeAdd",
        "ClaudeCodeSend", "ClaudeCodeTreeAdd", "ClaudeCodeStatus", "ClaudeCodeStart",
        "ClaudeCodeStop", "ClaudeCodeOpen", "ClaudeCodeClose", "ClaudeCodeDiffAccept",
        "ClaudeCodeDiffDeny", "ClaudeCodeCloseAllDiffs",
      },
      keys = {
        { "<leader>a", nil, desc = "AI/Claude Code" },
        { "<leader>ac", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
        { "<leader>af", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
        { "<leader>ar", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
        { "<leader>aC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
        { "<leader>am", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
        { "<leader>ab", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
        { "<leader>as", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
        {
          "<leader>as",
          "<cmd>ClaudeCodeTreeAdd<cr>",
          desc = "Add file",
          ft = { "NvimTree", "neo-tree", "oil", "snacks_picker_list" },
        },
        { "<leader>aa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
        { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
      },
    },
  })
  -- }}}
elseif host == "dvim-org" then -- (nvim-orgmode + org-roam.nvim) {{{
  return {
    {
      "nvim-orgmode/orgmode",
      lazy = false,
      config = function()
        -- Setup orgmode
        require("orgmode").setup({
          org_agenda_files = "~/notes/org/**/*",
          --org_default_notes_file = '~/notes/org/refile.org',
        })
      end,
    },
    {
      "chipsenkbeil/org-roam.nvim",
      lazy = false,
      config = function()
        require("org-roam").setup({
          directory = "~/orgroamfiles",
          -- optional
          -- org_files = {
          --   "~/another_org_dir",
          --   "~/some/folder/*.org",
          --   "~/a/single/org_file.org",
          -- }
        })
      end,
    },
  }
  -- }}}
elseif host == "dvim-obsidian" then -- (obsidian.nvim, $PWD=vault) {{{
  vim.opt.conceallevel = 2

  return {
    {
      "obsidian-nvim/obsidian.nvim",
      version = "*", -- use latest release, remove to use latest commit
      lazy = false,
      ---@module 'obsidian'
      ---@type obsidian.config
      opts = {
        legacy_commands = false, -- this will be removed in the next major release
        -- At least one workspace is required
        workspaces = {
          { name = "notes", path = "/notes" }, -- bind-mounted in run.sh
        },
        daily_notes = {
          folder = "journals",
          date_format = "%Y-%m-%d",
        },
        new_notes_location = "pages",
      },
      dependencies = {
        "nvim-lua/plenary.nvim",
        -- optional
        "nvim-treesitter/nvim-treesitter", -- markdown syntax highlighting
        -- "hrsh7th/nvim-cmp", -- for completion of note references
      },
    },
  }
  -- }}}
elseif host == "dvim-devicons" then -- (nvim-web-devicons) {{{
  vim.g.icons_plugin = "nvim-tree/nvim-web-devicons"
  return {
    { "nvim-tree/nvim-web-devicons", lazy = true, opts = {} },
  }
  -- }}}
elseif host == "dvim-snacks" then -- (snacks.nvim's explorer) {{{
  return {
    { "nvim-tree/nvim-tree.lua", enabled = false },
    {
      "folke/snacks.nvim",
      lazy = false,
      opts = { explorer = { replace_netrw = false } },
      keys = {
        -- stylua: ignore start
        { "<C-B>", function() Snacks.explorer() end, desc = "Toggle Explorer" },
        { "<leader>e", function() Snacks.explorer() end, desc = "Toggle Explorer" },
        -- stylua: ignore end
      },
    },
  }
  -- }}}
elseif host == "dvim-neotree" then -- (neo-tree.nvim) {{{
  return {
    { "nvim-tree/nvim-tree.lua", enabled = false },
    {
      "nvim-neo-tree/neo-tree.nvim",
      cmd = "Neotree",
      dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim", vim.g.icons_plugin },
      keys = {
        { "<C-B>", "<Cmd>Neotree toggle reveal<CR>", desc = "Toggle Explorer" },
        { "<leader>e", "<Cmd>Neotree toggle reveal<CR>", desc = "Toggle Explorer" },
        { "<leader>ge", "<Cmd>Neotree git_status toggle<CR>", desc = "Git Explorer" },
        { "<leader>be", "<Cmd>Neotree buffers toggle<CR>", desc = "Buffer Explorer" },
      },
      opts = {
        sources = { "filesystem", "buffers", "git_status" },
        filesystem = {
          follow_current_file = { enabled = true },
          use_libuv_file_watcher = true,
          hijack_netrw_behavior = "disabled",
        },
        window = {
          mappings = { ["l"] = "open", ["h"] = "close_node", ["<space>"] = "none" },
        },
      },
    },
  }
  -- }}}
else
  return {}
end
