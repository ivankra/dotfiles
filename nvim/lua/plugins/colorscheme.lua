-- At startup: the last :colorscheme picked, else the dotfiles theme
-- (~/.dotfiles/themes/), else a default. Scheme plugins load at VeryLazy,
-- or on demand when :colorscheme names one; before that, <Tab> misses them.

-- Per-scheme options. Set at import: spec inits run in no fixed order.
vim.g.dracula_italic = 0
vim.g.sonokai_disable_italic_comment = 1

-- Last picked scheme and 'background'. `setup.sh --theme` deletes it.
-- ShaDa could store it as a global (g:COLORSCHEME) instead, but nvim reads
-- ShaDa only after the config has run, too late to apply it at startup.
local save_file = vim.fn.stdpath("state") .. "/colorscheme"

-- Default theme to use if setup.sh hasn't been run
local default_theme = "tokyonight-moon"

-- Returns false if the scheme is missing or broken.
local function apply_colorscheme(name, background)
  return (name or "") ~= ""
    and pcall(function()
      vim.g.colors_name = nil -- else setting 'background' reloads it
      vim.o.background = background
      vim.cmd.colorscheme(name)
    end)
end

-- Saves picks, 'background' changes too (they reload the scheme).
local function save_colorscheme(ev)
  if vim.v.vim_did_enter == 0 then -- not schemes applied during startup
    return
  end
  -- colors_name is the variant shown (tokyonight-moon + bg=light: tokyonight-day),
  -- but may be just the family (kanagawa-dragon: kanagawa) or not a scheme.
  local name = vim.g.colors_name
  local is_scheme = name and vim.tbl_contains(vim.fn.getcompletion(name, "color"), name)
  if not is_scheme or vim.startswith(ev.match, name .. "-") then
    name = ev.match
  end
  if name ~= "" then -- empty after a bare :doautocmd ColorScheme
    vim.fn.mkdir(vim.fn.fnamemodify(save_file, ":h"), "p")
    vim.fn.writefile({ name, vim.o.background }, save_file)
  end
end

local function init()
  -- Save picks, whichever step below applies the startup scheme
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("StickyColorscheme", { clear = true }),
    callback = save_colorscheme,
  })

  -- 1. The last pick (scheme and 'background')
  local saved = vim.fn.filereadable(save_file) == 1 and vim.fn.readfile(save_file) or {}
  if apply_colorscheme(saved[1], saved[2]) then
    return
  end

  -- 2. The dotfiles theme
  -- setup.sh links ~/.config/theme to ~/.dotfiles/themes/<colorscheme>
  local theme = vim.fn.resolve(vim.fn.expand("~/.config/theme"))
  if vim.fn.isdirectory(theme) == 1 then
    local name = vim.fn.fnamemodify(theme, ":t")
    if apply_colorscheme(name, "dark") then -- all are dark themes
      return
    end
    vim.notify("No colorscheme for theme " .. name, vim.log.levels.WARN)
  end

  -- 3. The default theme, else nvim's own
  if not apply_colorscheme(default_theme, "dark") then
    apply_colorscheme("default", "dark")
  end
end

return {
  -- Not a plugin, only an init: lazy runs all inits before loading any plugin,
  -- so plugins start with the right colors (e.g. lualine's theme).
  { "theme", virtual = true, init = init },

  { "dracula/vim", name = "dracula.vim", dev = true, event = "VeryLazy" },

  {
    "folke/tokyonight.nvim",
    dev = true,
    event = "VeryLazy",
    opts = {
      style = "moon",
      on_colors = function(colors)
        colors.fg_dark = "#e6e7f1" -- brighten vim command line's color (MsgArea)
        colors.comment = "#8095D6" -- moon: #636da6
      end,
    },
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
      italic = { strings = false, comments = false },
    },
  },

  { "joshdick/onedark.vim", dev = true, event = "VeryLazy" },
  { "projekt0n/github-nvim-theme", dev = true, event = "VeryLazy" },
  { "rebelot/kanagawa.nvim", dev = true, event = "VeryLazy" },
  { "sainnhe/sonokai", dev = true, event = "VeryLazy" },
}
