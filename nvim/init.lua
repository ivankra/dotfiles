-- stylua: ignore start
vim.opt.confirm = true                  -- Confirm to save when closing a modified buffer instead of error
vim.opt.cursorline = true               -- Highlight current line
vim.opt.diffopt:append("algorithm:histogram")  -- Diffs that follow moved/repeated lines better than the default myers
vim.opt.fileencodings = "ucs-bom,utf-8,cp1251"  -- Encodings to try when opening a file, as vimrc (default ends in latin1)
vim.opt.fillchars = { eob = " " }       -- Don't show ~ for non-existing lines in a buffer
vim.opt.foldmethod = "marker"           -- Default folding method: {{{ and }}} markers
-- Note: deprecated (flips plugins' :s///g), but no plugin used here runs :s
vim.opt.gdefault = true                 -- Enable /g flag by default for search & replace (flip its on/off status)
vim.opt.ignorecase = true               -- Case-insensitive search by default (add \C to pattern to override)
vim.opt.laststatus = 3                  -- Global statusline (nvim)
vim.opt.list = true                     -- Show substitutes for some special chars
vim.opt.listchars = "tab:→ ,trail:▞,nbsp:␣"  -- e.g. →⊢⇤⇠⇢•◌◼⯁▮▯∵∴␠×✘╳␣⎵▞░▒▓◘
vim.opt.pumheight = 15                  -- Limit popup menu's height
vim.opt.scrolloff = 5                   -- Keep 5 lines above/below the cursor, as vim's defaults.vim (nvim: 0)
vim.opt.showmode = false                -- Don't show mode since it's already in the statusline
vim.opt.sidescrolloff = 8               -- Keep 8 columns left/right of the cursor (with nowrap)
vim.opt.smartcase = true                -- Case-sensitive search if pattern contains uppercase characters
vim.opt.splitbelow = true               -- Put new split window below
vim.opt.splitright = true               -- Put new vertically split window to the right
vim.opt.timeoutlen = 300                -- Wait for mapped sequences (default 1000), shorter in terminal mode below
vim.opt.undofile = true                 -- Persistent undo history
vim.opt.undolevels = 10000              -- Undo steps kept (default 1000), also in the undo file
vim.opt.updatetime = 250                -- CursorHold after 250ms idle (default 4000), swap file written then too
vim.opt.virtualedit = "block"           -- Allow cursor to move past end-of-line in block selection mode
vim.opt.wildmode = "longest:full,full"  -- completion mode like readline's show-all-if-ambiguous
-- No splitkeep=screen: breaks nvim +N file / fileline.vim

-- Default indent options. Will get adjusted by guess-indent.nvim.
vim.opt.expandtab = true                -- Expand tabs
vim.opt.shiftwidth = 2                  -- 2 space indent
vim.opt.shiftround = true               -- >> << > < snap the indent to a multiple of shiftwidth
vim.opt.softtabstop = -1                -- Use shiftwidth value

-- Wrapping
vim.opt.wrap = false                    --  No line wrapping by default
vim.opt.linebreak = true                --  Wrap line at whitespace
vim.opt.breakindent = true              --  Continue original indentation on wrapped lines
vim.opt.breakindentopt = "list:-1"      --  ...and indent past list bullets (per 'formatlistpat')
-- With line numbers on, don't want showbreak
-- vim.opt.breakindentopt = "shift:2,sbr"  --  At least 2 column indent and enable showbreak
-- vim.opt.showbreak = "↪"                 --  Wrapping indicator e.g. ↪ ⤷ ↳ └─▶
if vim.fn.has("nvim-0.10") == 1 then
  vim.opt.smoothscroll = true           --  Ctrl-E/Ctrl-Y (scroll the view a line) go by screen line in wrapped lines
end
-- stylua: ignore end

-- 24-bit color: 0.10+ turns it on by itself when the terminal supports it
-- ($COLORTERM, terminfo, or asking the terminal, which also works over ssh),
-- and leaves it off in e.g. the Linux console. Older nvim needs it set.
if vim.fn.has("nvim-0.10") == 0 then
  vim.opt.termguicolors = true
end

-- Ctrl-O/Ctrl-I (back/forward to where you jumped from: gd, G, /search, ...)
-- restore the scroll position too. Appended: keeps the default "clean" (0.11+),
-- which drops jumps into deleted buffers. 0.10+.
if vim.fn.has("nvim-0.10") == 1 then
  vim.opt.jumpoptions:append("view")
end

-- Closing a tab goes to the last used one, not the next. 0.11+ ('tabclose')
if vim.fn.exists("+tabclose") == 1 then
  vim.opt.tabclose = "uselast"
end

-- Border for floating windows that don't set their own
if vim.fn.has("nvim-0.11") == 1 then
  vim.opt.winborder = "rounded"
end

-- vim.uv is 0.10+, older nvim only has vim.loop (same libuv module). Lua code
-- loaded later can use vim.uv everywhere. lazy.nvim sets this too, but only
-- once required, and code below runs before that.
vim.uv = vim.uv or vim.loop

-- Initial GUI font. Set here rather than in ginit.vim to reduce flicker at startup.
-- Must be a single existing font: nvim-qt pre-0.2.20 doesn't support fallback
-- fonts and would report unknown fonts as an error with 1s freeze.
-- Also hides a race in stock nvim-qt that loses ginit.vim's 'guifont' at startup.
if vim.uv.fs_stat("/usr/share/fonts/truetype/iosevka/IosevkaNerdFont-Medium.ttf") then
  vim.o.guifont = "Iosevka NFM:h12:w500"
else
  vim.o.guifont = "Monospace:h12"
end

-- Markdown: no ftplugin indent of its own (shiftwidth/tabstop 4 even in new
-- files): the defaults above, guess-indent's or .editorconfig's apply
vim.g.markdown_recommended_style = 0

vim.g.mapleader = " " -- <leader> key
vim.g.maplocalleader = "\\"

vim.g.in_container = vim.env.container ~= nil
  or vim.uv.fs_stat("/run/.containerenv") ~= nil
  or vim.uv.fs_stat("/.dockerenv") ~= nil

vim.g.icons_plugin = "nvim-mini/mini.icons"
vim.g.statusline_plugin = "lualine"

-- Nerd Font glyphs (icons, statusline arrows, ...), except on the Linux
-- console, whose fonts have none: plain characters there
vim.g.nerd_font = vim.env.TERM ~= "linux"

-- Find dotfiles checkout's root from whatever ~/.config/nvim[-appname] point to
vim.g.dotfiles = vim.fn.fnamemodify(vim.fn.resolve(vim.fn.stdpath("config")), ":h")

-- setup.sh used to symlink ~/.local/share/nvim/site to dotfiles
local site = vim.fn.stdpath("data") .. "/site"
local site_stat = vim.uv.fs_lstat(site)
if site_stat and site_stat.type == "link" and not vim.uv.fs_stat(site) then
  os.remove(site)
end

-- lazy.nvim requires 0.8+ (skip quietly instead of its error notification)
if vim.fn.has("nvim-0.8") == 0 then
  return
end

-- lazy.nvim itself, from the submodule. Not cloned yet: no plugins.
local lazy_dir = vim.g.dotfiles .. "/third_party/lazy.nvim"
if not vim.uv.fs_stat(lazy_dir .. "/lua/lazy/init.lua") then
  vim.notify("No plugins: run `git submodule update --init` in " .. vim.g.dotfiles, vim.log.levels.WARN)
  return
end
vim.opt.rtp:prepend(lazy_dir)

require("lazy").setup({
  -- Unless in container, load plugins from submodules only,
  -- don't install from git or check for updates.
  dev = {
    path = vim.g.dotfiles .. "/third_party",
    fallback = vim.g.in_container,
  },
  install = { missing = vim.g.in_container },
  checker = { enabled = false },
  change_detection = { enabled = false },
  pkg = { enabled = false },
  rocks = { enabled = false },
  -- Not in the config dir, i.e. the dotfiles repo. Only containers install
  -- plugins (the host uses submodules), so it's only theirs anyway.
  lockfile = vim.fn.stdpath("data") .. "/lazy-lock.json",

  performance = {
    rtp = {
      disabled_plugins = {
        -- Disable netrw in favor of nvim-tree/oil
        "netrwPlugin",
      },
    },
  },

  spec = {
    -- Imports all ~/.config/nvim/lua/plugins/*.lua
    { import = "plugins" },
  },
})

-- Autoloaded vim plugins in ~/.config/nvim/plugin/ (shared with vim):
-- * chmod.vim: chmod a+rx files that become scripts (new, or shebang added)
-- * comment.vim: Ctrl+/ toggles comments (gcc/gc)
-- * fileline.vim: interpret 'filename[:line[:col]]' filenames
-- * projectionist.vim: vim-projectionist config
-- * typos.vim: :W/:Wq for :w/:wq, 'langmap' for the Russian layout
-- * vscode.vim: vscode-like key bindings
-- * ui.vim: UI toggles (<leader>u*)
--
-- Autoloaded lua plugins in ~/.config/nvim/plugin/:
-- * autocmds.lua: autocommands (reload changed files, restore cursor, ...)
-- * keymaps.lua: key mappings (window navigation, buffers, ...)
