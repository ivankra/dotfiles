return {
  {
    "dracula/vim",
    dev = true,
    name = "dracula.vim",
    priority = 1000,
    init = function()
      vim.cmd('colorscheme dracula')
    end
  },

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
