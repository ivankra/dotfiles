-- lazy.nvim loads a not-yet-loaded colorscheme plugin when :colorscheme is run,
-- so the current theme (below) works at startup. The others still load at
-- VeryLazy, right after startup: until then they're missing from
-- :colorscheme <Tab> completion.

-- Current theme, see ~/.dotfiles/themes/: its dir name is the nvim colorscheme
local theme_dir = vim.fn.expand("~/.config/theme")
-- Last :colorscheme (name, 'background'): sticks across restarts until
-- `setup.sh --theme` switches the global theme and deletes this file.
local saved_file = vim.fn.stdpath("state") .. "/colorscheme"

-- Per-scheme preferences for whichever way a scheme gets applied. Set here
-- at import, not in a spec's init: lazy runs inits in no fixed order.
vim.g.dracula_italic = 0
vim.g.sonokai_style = "default"
vim.g.sonokai_disable_italic_comment = 1

-- dracula-dark (nvim/colors/) is an overlay on dracula.vim, which lazy only
-- loads on demand for dracula.vim's own colors/
-- (augroup: lazy re-imports specs on :Lazy sync etc.)
vim.api.nvim_create_autocmd("ColorSchemePre", {
  group = vim.api.nvim_create_augroup("DraculaDark", { clear = true }),
  pattern = "dracula-dark",
  callback = function()
    require("lazy").load({ plugins = { "dracula.vim" } })
  end,
})

local function apply_saved()
  local ok, lines = pcall(vim.fn.readfile, saved_file)
  if not ok or #lines < 2 or lines[1] == "" then
    return false
  end
  local background = vim.o.background
  if pcall(function()
    vim.o.background = lines[2]
    vim.cmd.colorscheme(lines[1])
  end) then
    return true
  end
  -- Scheme gone or broken: fall back to the theme. Unset colors_name first,
  -- or restoring 'background' would reload the broken scheme.
  pcall(function()
    vim.g.colors_name = nil
    vim.o.background = background
  end)
  return false
end

return {
  -- Saved colorscheme, else the current theme (see ~/.dotfiles/themes/).
  -- Applied from init, which runs before any plugin loads, so that e.g.
  -- lualine picks up its colors. Not a plugin, only this init.
  {
    "theme",  -- lazy needs [1], dir or url; a bare name without "/" is just the name
    virtual = true,
    lazy = true,
    init = function()
      if not apply_saved() and vim.uv.fs_stat(theme_dir) then
        -- All themes are dark. Set explicitly, so nvim doesn't switch it
        -- after startup from the terminal's background color.
        vim.o.background = "dark"
        local name = vim.fn.fnamemodify(vim.fn.resolve(theme_dir), ":t")
        if not pcall(vim.cmd.colorscheme, name) then
          vim.notify("No colorscheme for theme " .. name, vim.log.levels.WARN)
        end
      end
      -- Only save after startup, so applying the theme above doesn't count.
      -- Changing 'background' reloads the scheme, so that's saved too.
      vim.api.nvim_create_autocmd("VimEnter", {
        once = true,
        callback = function()
          vim.api.nvim_create_autocmd("ColorScheme", {
            group = vim.api.nvim_create_augroup("StickyColorscheme", { clear = true }),
            callback = function(ev)
              -- The variant actually shown: after :set bg=light, tokyonight-moon
              -- becomes tokyonight-day (ev.match stays tokyonight-moon)
              local name = vim.g.colors_name
              if not (name and vim.tbl_contains(vim.fn.getcompletion(name, "color"), name)) then
                name = ev.match
              end
              if name == "" then  -- :doautocmd ColorScheme without a name
                return
              end
              vim.fn.mkdir(vim.fn.fnamemodify(saved_file, ":h"), "p")
              vim.fn.writefile({ name, vim.o.background }, saved_file)
            end,
          })
        end,
      })
    end,
  },

  { "dracula/vim", name = "dracula.vim", dev = true, lazy = true },

  {
    "folke/tokyonight.nvim",
    dev = true,
    event = "VeryLazy",
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
