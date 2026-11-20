-- Dockerized nvim configurations (for lazy.nvim) with extra plugins to experiment with.
-- Automatically sourced via ~/.dotfiles/nvim/lua/plugins/dvim.lua symlink.

if vim.g.in_container == nil or not vim.g.in_container then
  return {}
end

local host = vim.uv.os_gethostname()  -- from podman --hostname

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

-- https://github.com/obsidian-nvim/obsidian.nvim (1.4k★)
elseif host == "dvim-obsidian" then
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
            vim.wo[win][0].foldlevel = 99  -- start with all folds open
          end
        end

        vim.api.nvim_create_autocmd("FileType", {
          group = vim.api.nvim_create_augroup("DvimTreesitter", { clear = true }),
          callback = function(ev) setup(ev.buf) end,
        })

        -- Async, and skips parsers that are already installed. On a fresh
        -- volume, files opened meanwhile got FileType before their parser or
        -- queries existed: no highlighting, or (with a parser bundled with
        -- nvim, e.g. lua) no indents query yet. Set them all up again once
        -- the install has finished; restarting highlighting is harmless.
        require("nvim-treesitter").install({
          "lua", "vim", "vimdoc", "bash", "python", "javascript", "typescript", "json", "yaml", "markdown",
        }):await(function()
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

    -- LSP configuration
    {
      "neovim/nvim-lspconfig",
      event = { "BufReadPost", "BufNewFile" },
      dependencies = { "mason-org/mason-lspconfig.nvim" },
      config = function()
        -- LSP keymaps on attach. Built in (0.11+), so not mapped here:
        --   K hover, grr references, gri implementation, grn rename,
        --   gra code action, grt type definition (0.12), gO document symbols,
        --   <C-s> signature help (insert mode).
        -- A `gr` mapping would make grr/grn/... wait for 'timeoutlen',
        -- and `gi` would replace "insert where insert mode was last exited".
        vim.api.nvim_create_autocmd("LspAttach", {
          callback = function(ev)
            local opts = { buffer = ev.buf, silent = true }
            vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
            vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
            vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
            vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
          end,
        })

        -- [d / ]d are built in since 0.11. Show the diagnostic after jumping,
        -- like the old vim.diagnostic.goto_prev/next did. 0.11 only knows
        -- jump.float; 0.12 deprecates it in favor of jump.on_jump.
        if vim.fn.has("nvim-0.12") == 1 then
          vim.diagnostic.config({
            jump = {
              on_jump = function(diagnostic, bufnr)
                if diagnostic then
                  vim.diagnostic.open_float({ bufnr = bufnr, scope = "cursor", focus = false })
                end
              end,
            },
          })
        else
          vim.diagnostic.config({ jump = { float = true } })
        end

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
  }

  --Unattended install (:MasonInstall blocks when headless; nvim-treesitter's install() is async, so wait):
  --RUN nvim --headless "+Lazy! sync" "+qa"
  --RUN nvim --headless "+MasonInstall lua-language-server pyright typescript-language-server stylua black prettier shfmt" "+qa"
  --RUN nvim --headless "+lua require('nvim-treesitter').install('all'):wait(1800000)" "+qa"
elseif host:sub(1, 5) == "dvim-" then
  error("Unknown HOST=" .. host)
end

-- Some other container (toolbox, distrobox, ...): no extra plugins
return {}
