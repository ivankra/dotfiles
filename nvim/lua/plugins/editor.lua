return {
  -- Autodetect indent
  {
    "NMAC427/guess-indent.nvim",
    dev = true,
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      on_space_options = { tabstop = 8 }
    }
  },

  -- Comment.nvim: toggle line/block comments
  -- Normal: `gcc` / `gbc` to toggle line/block comment, can prefix with number of lines
  -- Visual: `gc` / `gb` to toggle line/block comment
  -- Ctrl+/: toggle line comments (VS Code style binding)
  -- Note: Shift+Alt+A for block comments can't be reliable captured.
  {
    "numToStr/Comment.nvim",
    dev = true,
    event = "VeryLazy",
    config = function()
      require("Comment").setup()

      local function toggle_current_line()
        require("Comment.api").toggle.linewise.current()
      end

      local function toggle_linewise_visual()
        local esc = vim.api.nvim_replace_termcodes("<ESC>", true, false, true)
        vim.api.nvim_feedkeys(esc, "nx", false)
        require("Comment.api").toggle.linewise(vim.fn.visualmode())
      end

      vim.keymap.set("n", "<C-/>", toggle_current_line)
      vim.keymap.set("i", "<C-/>", toggle_current_line)
      vim.keymap.set("v", "<C-/>", toggle_linewise_visual)

      -- CLI terminals usually send <C-_> on Ctrl+/
      if not vim.g.GuiLoaded then
        vim.keymap.set("n", "<C-_>", toggle_current_line)
        vim.keymap.set("i", "<C-_>", toggle_current_line)
        vim.keymap.set("v", "<C-_>", toggle_linewise_visual)
      end
    end
  },

  -- Highlight TODO/FIXME/etc keywords in comments
  {
    "folke/todo-comments.nvim",
    dev = true,
    event = "VimEnter",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {
      signs = false,
      -- Accept TODO(text) pattern
      search = { pattern = [[\b(KEYWORDS)(\([^\)]*\))?:]] },
      highlight = { pattern = [[.*<((KEYWORDS)%(\(.{-1,}\))?):]], keyword = "bg" }
    }
  },

  -- Colorize CSS color codes (#RRGGBB)
  {
    "catgoose/nvim-colorizer.lua",
    dev = true,
    event = "BufReadPre",
    config = function()
      require("colorizer").setup()
    end
  },
}
