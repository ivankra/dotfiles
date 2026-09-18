-- lazy.nvim loads colorscheme plugins on demand when :colorscheme is run
local theme_file = vim.fn.expand("~/.config/theme/nvim.lua")

return {
  -- Current theme, see ~/.dotfiles/themes/. Applied from init, which runs
  -- before any plugin loads, so that e.g. lualine picks up its colors.
  {
    name = "theme",
    dir = vim.fn.fnamemodify(theme_file, ":h"),
    lazy = true,
    cond = vim.fn.filereadable(theme_file) == 1,
    init = function()
      dofile(theme_file)
    end,
  },

  { "dracula/vim", name = "dracula.vim", dev = true, lazy = true },

  {
    "folke/tokyonight.nvim",
    dev = true,
    -- priority = 1000,
    config = function()
      require("tokyonight").setup {
        style = "moon",
        -- styles = { comments = { italic = false } },
        on_colors = function(colors)
          colors.fg_dark = "#e6e7f1"  -- brighten vim command line's color (MsgArea)
          colors.comment = "#8095D6"  -- moon: #636da6
        end
      }
      -- vim.cmd("colorscheme tokyonight")
      -- vim.api.nvim_set_hl(0, 'MsgArea', { fg = '#e6e7f1' })
    end,
  },

  {
    "catppuccin/nvim",
    name = "catppuccin.nvim",
    dev = true,
    event = "VeryLazy",
    opts = { flavour = "mocha" },
  },

  {
    "ellisonleao/gruvbox.nvim",
    dev = true,
    event = "VeryLazy",
    opts = {
      contrast = "hard",
      italic = {
        strings = false,
        comments = false
      }
    }
  },

  { "joshdick/onedark.vim", dev = true, event = "VeryLazy" },
  { "projekt0n/github-nvim-theme", dev = true, event = "VeryLazy" },
  { "sainnhe/sonokai", dev = true, event = "VeryLazy" },
}
