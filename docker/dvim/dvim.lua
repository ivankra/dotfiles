-- Dockerized nvim configurations (for lazy.nvim) with extra plugins to experiment with.
-- Automatically sourced via ~/.dotfiles/nvim/lua/plugins/dvia.lua symlink.

if vim.g.in_container == nil or not vim.g.in_container then
  return {}
end

local host = vim.loop.os_gethostname()  -- from podman --hostname

-- Org-inspired outliner PKM, however uses own markup flavor (.norg)
-- https://github.com/nvim-neorg/neorg (7.2k★)
if host == "dvim-neorg" then
  return {
    {
      "nvim-neorg/neorg",
      lazy = false,
      version = "*",
      config = true,
      dependencies = {
        "MunifTanjim/nui.nvim",
        "nvim-lua/plenary.nvim",
        "nvim-neorg/lua-utils.nvim",
        "nvim-neotest/nvim-nio",
        "nvim-treesitter/nvim-treesitter",
        "pysan3/pathlib.nvim",
        "vhyrro/luarocks.nvim",
      }
    }
  }

-- org + org-roam for nvim
-- https://github.com/nvim-orgmode/orgmode (3.6k★)
-- https://github.com/chipsenkbeil/org-roam.nvim (0.25k★)
elseif host == "dvim-org" then
  return {
    {
      'nvim-orgmode/orgmode',
      lazy = false,
      ft = { 'org' },
      config = function()
        -- Setup orgmode
        require('orgmode').setup({
          org_agenda_files = '~/notes/org/**/*',
          --org_default_notes_file = '~/notes/org/refile.org',
        })
      end
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
      end
    }
  }

-- Cross-editor PKM implemented as a markdown language server
-- https://github.com/Feel-ix-343/markdown-oxide (1.8k★)
elseif host == "dvim-oxide" then
  return {
    {
      "neovim/nvim-lspconfig",
      lazy = false,
      dependencies = {
        "hrsh7th/nvim-cmp",
        "hrsh7th/cmp-nvim-lsp",
      },
      config = function()
        local capabilities = require("cmp_nvim_lsp").default_capabilities(vim.lsp.protocol.make_client_capabilities())

        -- Ensure that dynamicRegistration is enabled! This allows the LS to take into account actions like the
        -- Create Unresolved File code action, resolving completions for unindexed code blocks, ...
        capabilities.workspace = {
          didChangeWatchedFiles = {
            dynamicRegistration = true,
          },
        }

        -- LSP keymaps on attach
        vim.api.nvim_create_autocmd("LspAttach", {
          callback = function(ev)
            local opts = { buffer = ev.buf, silent = true }
            vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
            vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
            vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
            vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
            vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
            vim.keymap.set("n", "[[", vim.lsp.buf.document_symbol, opts)

            -- Refresh codelens on buffer events
            local client = vim.lsp.get_client_by_id(ev.data.client_id)
            if client and client.server_capabilities.codeLensProvider then
              vim.lsp.codelens.refresh()
              vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave" }, {
                buffer = ev.buf,
                callback = vim.lsp.codelens.refresh,
              })
            end
          end,
        })

        vim.lsp.config("markdown_oxide", {
          capabilities = capabilities,
        })

        vim.lsp.enable("markdown_oxide")
      end,
    },
    {
      "hrsh7th/nvim-cmp",
      event = "InsertEnter",
      dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
      },
      config = function()
        local cmp = require("cmp")
        cmp.setup({
          sources = cmp.config.sources({
            {
              name = "nvim_lsp",
              option = {
                markdown_oxide = {
                  keyword_pattern = [[\(\k\| \|\/\|#\)\+]]
                }
              }
            },
            { name = "buffer" },
            { name = "path" },
          }),
          mapping = cmp.mapping.preset.insert({
            ["<C-Space>"] = cmp.mapping.complete(),
            ["<C-e>"] = cmp.mapping.abort(),
            ["<CR>"] = cmp.mapping.confirm({ select = true }),
            ["<C-n>"] = cmp.mapping.select_next_item(),
            ["<C-p>"] = cmp.mapping.select_prev_item(),
          }),
        })
      end,
    },
  }

-- https://github.com/obsidian-nvim/obsidian.nvim (1.4k★)
elseif host == "dvim-obsidian" then
  vim.opt.conceallevel = 2

  return {
    {
      "obsidian-nvim/obsidian.nvim",
      version = "*", -- use latest release, remove to use latest commit
      lazy = false,
      ft = "markdown",
      ---@module 'obsidian'
      ---@type obsidian.config
      opts = {
        legacy_commands = false, -- this will be removed in the next major release
        -- At least one workspace is required
        workspaces = {
          { name = "notes", path = "/notes" },  -- bind-mounted in run.sh
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
        "nvim-treesitter/nvim-treesitter",  -- markdown syntax highlighting
        "hrsh7th/nvim-cmp",                 -- for completion of note references
      },
    }
  }

-- maybe try
-- https://github.com/jakewvincent/mkdnflow.nvim + obsidian
-- https://github.com/zk-org/zk-nvim

-- IDE-like config
elseif host == "dvim" then
  vim.opt.number = true
  vim.opt.signcolumn = "yes"
  -- vim.opt.statuscolumn = "%4l %s"
  vim.opt.statuscolumn = "%s %4l "

  return {
    -- Treesitter: syntax highlighting, indentation, folding
    {
      "nvim-treesitter/nvim-treesitter",
      branch = "main",
      build = ":TSUpdate",
      event = { "BufReadPost", "BufNewFile" },
      config = function()
        require("nvim-treesitter").setup({
          ensure_installed = { "lua", "vim", "vimdoc", "bash", "python", "javascript", "typescript", "json", "yaml", "markdown" },
        })
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

    -- LSP configuration
    {
      "neovim/nvim-lspconfig",
      event = { "BufReadPost", "BufNewFile" },
      dependencies = { "mason-org/mason-lspconfig.nvim" },
      config = function()
        -- LSP keymaps on attach
        vim.api.nvim_create_autocmd("LspAttach", {
          callback = function(ev)
            local opts = { buffer = ev.buf, silent = true }
            vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
            vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
            vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
            vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)
            vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
            vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
            vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
            vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)
            vim.keymap.set("n", "]d", vim.diagnostic.goto_next, opts)
          end,
        })

        vim.lsp.config("lua_ls", {
          settings = {
            Lua = {
              workspace = { checkThirdParty = false },
              telemetry = { enable = false },
            },
          },
        })

        -- Enable servers
        vim.lsp.enable({ "lua_ls", "pyright", "ts_ls" })
      end,
    },

    -- Conform: lightweight formatter
    {
      "stevearc/conform.nvim",
      event = "BufWritePre",
      cmd = "ConformInfo",
      keys = {
        { "<leader>cf", function() require("conform").format({ async = true }) end, desc = "Format buffer" },
      },
      opts = {
        formatters_by_ft = {
          lua = { "stylua" },
          python = { "black" },
          javascript = { "prettier" },
          typescript = { "prettier" },
          json = { "prettier" },
          yaml = { "prettier" },
          markdown = { "prettier" },
          sh = { "shfmt" },
        },
      },
    },

    -- Blink.cmp: fast completion
    {
      "saghen/blink.cmp",
      event = "InsertEnter",
      dependencies = { "rafamadriz/friendly-snippets" },
      version = "*",  -- use releases for prebuilt binaries
      opts = {
        keymap = { preset = "default" },  -- <C-space> trigger, <C-y> accept, <C-e> cancel, <C-n/p> navigate
        appearance = {
          use_nvim_cmp_as_default = true,
          nerd_font_variant = "mono",
        },
        sources = {
          default = { "lsp", "path", "snippets", "buffer" },
        },
        completion = {
          documentation = { auto_show = true },
        },
      },
    },

    {
      "lewis6991/gitsigns.nvim",
      opts = { signcolumn = true },
    },
  }

  --Unattended install:
  --RUN nvim --headless "+Lazy! sync" "+qa"
  --RUN nvim --headless "+MasonInstallAll" "+qa"
  --RUN nvim --headless "+TSInstallSync all" "+qa"
elseif host:sub(1, 5) == "dvim-" then
  error("Unknown HOST=" .. host)
end
