local markdown_fts = { "markdown", "norg", "rmd", "org", "codecompanion" }

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
        always_show_bufferline = false, -- hide if only one buffer
        -- Default is "bdelete! %d", which silently discards unsaved changes.
        -- :Bd (mini.bufremove spec below) asks Save/No/Cancel like :q and keeps
        -- the window layout.
        close_command = "Bd %d",
        right_mouse_command = "Bd %d",
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
      -- Insert mode too, as init.lua's :bprevious/:bnext fallbacks
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
      preset = "helix", -- show floating window at the right
      spec = {
        { "<leader>b", group = "buffer" },
        { "<leader>c", group = "code" },
        { "<leader>f", group = "file/find" },
        { "<leader>u", group = "ui" },
        { "<leader>g", group = "git" },
        { "<leader>gh", group = "hunks" },
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
    cmd = { "ToggleTerm", "TermExec" },
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
    dependencies = { vim.g.icons_provider },
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
        language_left = "",
        language_right = "",
      },
      pipe_table = { style = "normal" },
    },
  },

  -- Dependencies
  { "nvim-lua/plenary.nvim", dev = true, lazy = true },
}
