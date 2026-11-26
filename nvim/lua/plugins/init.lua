local markdown_fts = { "markdown", "norg", "rmd", "org", "codecompanion" }

return {
  -- Icons. Requires Nerd patched font, else letters (vim.g.nerd_font).
  {
    "nvim-mini/mini.icons",
    dev = true,
    opts = { style = vim.g.nerd_font and "glyph" or "ascii" },
    config = function(_, opts)
      local icons = require("mini.icons")
      icons.setup(opts)
      -- README.md, CHANGELOG.md etc.: the plain .md icon, not their own
      local glyph, hl = icons.get("extension", "md")
      local md_files = {}
      for _, name in ipairs(icons.list("file")) do
        if name:match("%.md$") then
          md_files[name] = { glyph = glyph, hl = hl }
        end
      end
      icons.setup(vim.tbl_deep_extend("force", opts, { file = md_files }))
    end,
    init = function()
      package.preload["nvim-web-devicons"] = function()
        require("mini.icons").mock_nvim_web_devicons()
        return package.loaded["nvim-web-devicons"]
      end
    end,
  },

  -- Delete buffers while preserving window layout
  {
    "nvim-mini/mini.bufremove",
    dev = true,
    cmd = { "Bd" },
    keys = {
      { "<leader>bd", "<cmd>Bd<cr>", desc = "Delete buffer" },
      { "<C-Q>", "<cmd>Bd<cr>", desc = "Delete buffer" },
    },
    opts = {},
    config = function(_, opts)
      local bufremove = require("mini.bufremove")
      bufremove.setup(opts)

      -- Like :bd: no args = current buffer, else buffer numbers and/or names
      -- (escape spaces in names with a backslash, as for :bd)
      vim.api.nvim_create_user_command("Bd", function(cmd_opts)
        local bufs = {}
        for _, arg in ipairs(#cmd_opts.fargs > 0 and cmd_opts.fargs or { "%" }) do
          local buf = arg:match("^%d+$") and tonumber(arg) or vim.fn.bufnr(arg)
          if buf > 0 and vim.api.nvim_buf_is_valid(buf) then
            table.insert(bufs, buf)
          else
            vim.notify("E94: No matching buffer for " .. arg, vim.log.levels.ERROR)
          end
        end
        bufremove.delete(bufs, cmd_opts.bang)
      end, { bang = true, nargs = "*", complete = "buffer", desc = "Delete buffer via mini.bufremove" })
    end,
    init = function()
      -- Also covers `bd!`: typing `!` already expands `bd` to `Bd`
      vim.cmd([[cabbr <expr> bd (getcmdtype() == ':' && getcmdline() ==# 'bd') ? 'Bd' : 'bd']])
    end,
  },

  -- Auto-close oldest unedited buffers past `threshold`. Editing pins a buffer.
  {
    "axkirillov/hbac.nvim",
    dev = true,
    lazy = false,
    keys = {
      { "<leader>bp", "<cmd>Hbac toggle_pin<cr>", desc = "Pin buffer (don't auto-close)" },
    },
    opts = {
      threshold = 5,
      -- :bdelete, not the default wipeout: keeps marks/jumplist for <C-o>
      close_command = function(bufnr)
        pcall(vim.cmd, "bdelete " .. bufnr)
      end,
    },
  },

  -- Reload unmodified buffers as soon as their files change on disk (fs
  -- watchers on the files' dirs). Built into nvim 0.13 (neovim#37971).
  -- TODO: once on nvim 0.13+, drop this and modules/hotreload.nvim; check the
  -- built-in watcher works and plugin/autocmds.lua's checktime still fits.
  {
    "diogo464/hotreload.nvim",
    dev = true,
    lazy = false,
    cond = vim.fn.has("nvim-0.10") == 1 and vim.fn.has("nvim-0.13") == 0,
    opts = {},
  },

  -- Modern take on vidir, editable file explorer buffers
  {
    "stevearc/oil.nvim",
    dev = true,
    -- Not lazy: oil replaces netrw for `nvim <dir>`, so it must load at startup
    lazy = false,
    keys = {
      { "-", "<cmd>Oil<cr>", desc = "Open parent directory (oil)" },
    },
    opts = {
      columns = { "icon", "permissions", "size", "mtime" },
    },
  },

  -- Fuzzy search
  {
    "nvim-telescope/telescope.nvim",
    dev = true,
    cmd = "Telescope",
    dependencies = { "nvim-lua/plenary.nvim" },
    -- Use telescope's dropdown for vim.ui.select() (numbered list picker, :LspInstall, ...)
    init = function()
      vim.ui.select = function(items, opts, on_choice)
        opts = opts or {}
        local format = opts.format_item or tostring
        local actions = require("telescope.actions")
        local results = {}
        for i, item in ipairs(items) do
          results[i] = { i, item }
        end
        local chosen = false -- else on_choice(nil) on close, as the spec says
        require("telescope.pickers")
          .new(require("telescope.themes").get_dropdown(), {
            prompt_title = (opts.prompt or "Select"):gsub(":%s*$", ""),
            finder = require("telescope.finders").new_table({
              results = results,
              entry_maker = function(result)
                local text = format(result[2])
                return { value = result, display = result[1] .. ". " .. text, ordinal = text }
              end,
            }),
            sorter = require("telescope.config").values.generic_sorter({}),
            attach_mappings = function(prompt_bufnr)
              actions.select_default:replace(function()
                local entry = require("telescope.actions.state").get_selected_entry()
                chosen = entry ~= nil
                actions.close(prompt_bufnr)
                if entry then
                  on_choice(entry.value[2], entry.value[1])
                end
              end)
              actions.close:enhance({
                post = function()
                  if not chosen then
                    chosen = true
                    on_choice(nil, nil)
                  end
                end,
              })
              return true
            end,
          })
          :find()
      end
    end,
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
    dependencies = { vim.g.icons_plugin },
    opts = {
      preset = "helix", -- show floating window at the right
      icons = { mappings = vim.g.nerd_font }, -- keymaps' icons
      spec = {
        { "<leader>b", group = "buffer" },
        { "<leader>c", group = "code" },
        { "<leader>f", group = "file/find" },
        { "<leader>u", group = "ui" },
        { "<leader>g", group = "git" },
        { "<leader>gh", group = "hunks" },
        { "<leader>x", group = "quickfix" },
      },
    },
    keys = {
      { "<leader>?", "<cmd>WhichKey<cr>", desc = "Show all keymaps" },
    },
  },

  -- Completion with blink.cmp (0.10+), instead of nvim's built-in LSP
  -- completion (lsp.lua): a menu as you type with the server's items, file
  -- paths, snippets and words from open buffers, docs next to it. Also on the
  -- : line (Tab).
  -- Keys: Ctrl+Space opens the menu, Ctrl+N/P or Up/Down select, Ctrl+Y
  -- accepts, Ctrl+E closes, PageUp/PageDown move a page, Ctrl+B/F scroll the
  -- docs.
  {
    "saghen/blink.cmp",
    dev = true,
    cond = vim.fn.has("nvim-0.10") == 1,
    -- Not lazy-loaded: when loaded, it adds what it supports (snippets etc.)
    -- to every server's capabilities (0.11+), which has to happen before the
    -- first server starts. It loads its own parts on demand.
    lazy = false,
    init = function()
      vim.g.lsp_builtin_completion = false -- see lsp.lua
    end,
    opts = {
      -- The Lua fuzzy matcher, no binary: the prebuilt one comes from
      -- GitHub releases, with a checksum from the same release (nothing
      -- pins it). Without typo tolerance or frecency. "lua" skips the
      -- download code entirely (fuzzy/download/init.lua, ensure_downloaded),
      -- and unlike "prefer_rust" warns about nothing. download = false: in
      -- case the implementation is changed.
      fuzzy = {
        implementation = "lua",
        prebuilt_binaries = { download = false },
      },
      keymap = {
        preset = "default",
        -- A page in the menu, like nvim's own popup menu (its own window,
        -- so not built in). 10: the menu's height (completion.menu.max_height).
        ["<PageUp>"] = {
          function(cmp)
            return cmp.select_prev({ count = 10 })
          end,
          "fallback",
        },
        ["<PageDown>"] = {
          function(cmp)
            return cmp.select_next({ count = 10 })
          end,
          "fallback",
        },
      },
      appearance = {
        nerd_font_variant = "mono",
      },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
      completion = {
        documentation = { auto_show = true },
        -- Without a Nerd Font: the kind as text (Function, ...), not its icon
        menu = not vim.g.nerd_font and {
          draw = { columns = { { "label", "label_description", gap = 1 }, { "kind" } } },
        } or nil,
      },
    },
  },

  -- Toggleable terminal on Ctrl+`/Ctrl+Space
  {
    "akinsho/toggleterm.nvim",
    dev = true,
    -- <C-Space> not in insert mode or on the : line: blink.cmp's (above).
    -- Terminals that send <C-`> as <C-Space> (NUL), like gnome-terminal and
    -- ptyxis, toggle with Ctrl+` there too.
    cmd = { "ToggleTerm", "TermExec", "TermNew" },
    -- No rhs: the first press loads the plugin, then hits its open_mapping
    keys = {
      { "<C-`>", mode = { "n", "i" }, desc = "Toggle terminal" },
      { "<C-Space>", "<cmd>ToggleTerm<cr>", desc = "Toggle terminal" },
    },
    opts = {
      open_mapping = [[<C-`>]],
      -- Closing from inside one: its own terminal mode only, so programs in
      -- other terminals (:terminal) keep Ctrl+Space
      on_create = function(term)
        vim.keymap.set("t", "<C-Space>", "<cmd>ToggleTerm<cr>", { buffer = term.bufnr, desc = "Toggle terminal" })
      end,
    },
  },

  -- Visual git integration: highlight changed lines, blame, stage hunks
  {
    "lewis6991/gitsigns.nvim",
    dev = true,
    event = "VimEnter",
    opts = {
      signcolumn = true, -- the default; see plugin/statuscolumn.lua
      -- Without a Nerd Font: gitsigns' default delete signs (▁ ▔)
      signs = {
        -- add = { text = "▎" },
        -- change = { text = "▎" },
        -- changedelete = { text = "▎" },
        -- untracked = { text = "▎" },
        delete = vim.g.nerd_font and { text = "" } or nil,
        topdelete = vim.g.nerd_font and { text = "" } or nil,
      },
      signs_staged = {
        -- add = { text = "▎" },
        -- change = { text = "▎" },
        -- changedelete = { text = "▎" },
        delete = vim.g.nerd_font and { text = "" } or nil,
        topdelete = vim.g.nerd_font and { text = "" } or nil,
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
        map("n", "]H", function()
          gs.nav_hunk("last")
        end, "Last Hunk")
        map("n", "[H", function()
          gs.nav_hunk("first")
        end, "First Hunk")
        map({ "n", "x" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage/Unstage Hunk")
        map({ "n", "x" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
        map("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
        map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
        map("n", "<leader>ghp", gs.preview_hunk_inline, "Preview Hunk Inline")
        map("n", "<leader>ghb", function()
          gs.blame_line({ full = true })
        end, "Blame Line")
        map("n", "<leader>ghB", function()
          gs.blame()
        end, "Blame Buffer")
        map("n", "<leader>ghd", gs.diffthis, "Diff This")
        map("n", "<leader>ghD", function()
          gs.diffthis("~")
        end, "Diff This ~")
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

  -- Align CSV/TSV columns as a table (virtual text, file is unchanged)
  -- Enable with automatic delimiter detection:
  --   :CsvViewToggle
  -- Enable with specific settings:
  --   :CsvViewToggle delimiter=, display_mode=border header_lnum=1
  {
    "hat0uma/csvview.nvim",
    dev = true,
    --cmd = { "CsvViewEnable", "CsvViewDisable", "CsvViewToggle" },
    cmd = { "CsvViewToggle" },
    keys = {
      { "<leader>uc", "<cmd>CsvViewToggle<cr>", desc = "Toggle CSV View" },
    },
    opts = {
      parser = { comments = { "#" } },
      view = { display_mode = "border" },
      keymaps = {
        textobject_field_inner = { "if", mode = { "o", "x" } },
        textobject_field_outer = { "af", mode = { "o", "x" } },
      },
    },
  },

  -- Render markdown in-buffer (headings, lists, code blocks, tables, etc.)
  -- Uses the markdown/markdown_inline treesitter parsers bundled with nvim 0.10+.
  -- Rendering is enabled by default and hidden on the cursor line.
  --   :RenderMarkdown toggle
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dev = true,
    ft = markdown_fts,
    dependencies = { vim.g.icons_plugin },
    keys = {
      { "<leader>um", "<cmd>RenderMarkdown toggle<cr>", desc = "Toggle Markdown Render" },
    },
    opts = {
      file_types = markdown_fts,
      -- No heading icons, no sign column icons
      heading = {
        sign = false,
        icons = {},
      },
      -- Checkboxes left as plain text
      checkbox = { enabled = false },
      -- Block-width code blocks with language tab
      code = {
        sign = false,
        width = "block",
        right_pad = 1,
        min_width = 80,
        disable_background = false,
        language_border = " ",
        language_left = vim.g.nerd_font and "" or "",
        language_right = vim.g.nerd_font and "" or "",
      },
      pipe_table = { style = "normal" },
    },
  },

  -- Dependencies
  { "nvim-lua/plenary.nvim", dev = true, lazy = true },
}
