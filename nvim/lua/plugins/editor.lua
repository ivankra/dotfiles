-- nvim-colorizer.lua options for CSS-like filetypes. They're merged over the
-- global `options` (which disable names and #RGB/#RGBA), and per-filetype
-- presets don't expand hex sub-options, so list every hex form wanted here.
-- (colorizer deep-copies each entry, so sharing one table is fine.)
local css_colors = {
  parsers = {
    css = true,
    hex = { rgb = true, rgba = true, rrggbb = true, rrggbbaa = true },
  },
}

return {
  -- Autodetect indent
  {
    "NMAC427/guess-indent.nvim",
    dev = true,
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      -- Tabs: shiftwidth 0 follows 'tabstop', a tab per level. The default sets
      -- only noexpandtab, leaving the global sw=2 (>> would indent 2 spaces).
      on_tab_options = {
        expandtab = false,
        shiftwidth = 0,
      },
      -- Must restate the defaults: setup() merges shallowly, so this table replaces them.
      on_space_options = {
        expandtab = true,
        tabstop = 8,
        softtabstop = "detected",
        shiftwidth = "detected",
      },
    },
  },

  -- Highlight TODO/FIXME/etc keywords in comments
  {
    "folke/todo-comments.nvim",
    dev = true,
    event = "VimEnter",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      -- Telescope is 0.11+
      vim.fn.has("nvim-0.11") == 1 and { "<leader>ft", "<cmd>TodoTelescope<cr>", desc = "Todo comments" } or nil,
    },
    opts = {
      signs = false,
      -- Accept TODO(text) pattern
      search = { pattern = [[\b(KEYWORDS)(\([^\)]*\))?:]] },
      highlight = { pattern = [[.*<((KEYWORDS)%(\(.{-1,}\))?):]], keyword = "bg" },
    },
  },

  -- Colorize CSS color codes (#RRGGBB)
  {
    "catgoose/nvim-colorizer.lua",
    dev = true,
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      filetypes = {
        "*",
        -- Full CSS color syntax (names, all hex forms, rgb()/hsl()/oklch(),
        -- var()) only where it's really CSS.
        css = css_colors,
        scss = css_colors,
        sass = css_colors,
        less = css_colors,
        html = css_colors,
      },
      -- Everywhere else: only #RRGGBB. Defaults also color plain words
      -- ("red", "white", "tan") and #RGB/#RGBA (#123 issue refs, #fed, #bad).
      options = {
        parsers = {
          names = { enable = false },
          hex = { rgb = false, rgba = false },
        },
      },
    },
    -- setup() needs 'termguicolors' at that moment, else it errors and does
    -- nothing. nvim turns it on by itself, but where it has to ask the
    -- terminal (no $COLORTERM, e.g. over ssh) only a moment after startup,
    -- after the first file is read. Never in e.g. the Linux console.
    config = function(_, opts)
      if vim.o.termguicolors then
        require("colorizer").setup(opts)
        return
      end
      vim.api.nvim_create_autocmd("OptionSet", {
        pattern = "termguicolors",
        callback = function()
          if not vim.o.termguicolors then
            return
          end
          require("colorizer").setup(opts)
          -- Buffers read before: run setup()'s FileType autocmd for them
          vim.cmd("silent! doautoall ColorizerSetup FileType")
          return true -- delete this autocmd
        end,
      })
    end,
  },
}
