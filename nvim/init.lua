-- stylua: ignore start
vim.opt.confirm = true                  -- Confirm to save when closing a modified buffer instead of error
vim.opt.cursorline = true               -- Highlight current line
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
vim.opt.smartcase = true                -- Case-sensitive search if pattern contains uppercase characters
vim.opt.splitbelow = true               -- Put new split window below
vim.opt.splitright = true               -- Put new vertically split window to the right
vim.opt.timeoutlen = 300                -- Wait for mapped sequences (default 1000), shorter in terminal mode below
vim.opt.undofile = true                 -- Persistent undo history
vim.opt.virtualedit = "block"           -- Allow cursor to move past end-of-line in block selection mode
vim.opt.wildmode = "longest:full,full"  -- completion mode like readline's show-all-if-ambiguous

-- 24-bit color: 0.10+ turns it on by itself when the terminal supports it
-- ($COLORTERM, terminfo, or asking the terminal, which also works over ssh),
-- and leaves it off in e.g. the Linux console. Older nvim needs it set.
if vim.fn.has("nvim-0.10") == 0 then
  vim.opt.termguicolors = true
end

-- Default indent options. Will get adjusted by guess-indent.nvim.
vim.opt.expandtab = true                -- Expand tabs
vim.opt.shiftwidth = 2                  -- 2 space indent
vim.opt.softtabstop = -1                -- Use shiftwidth value

-- Status column
vim.opt.number = true                   -- Show line numbers
vim.opt.numberwidth = 3
vim.opt.signcolumn = "yes"              -- Always show sign column
vim.g.gitsigns_signcolumn = true        -- gitsigns's signcolumn via lua/plugins/init.lua
-- 'statuscolumn' is 0.9+, and %l only follows 'number'/'relativenumber' since 0.10
if vim.fn.has("nvim-0.10") == 1 then
  vim.opt.statuscolumn = "%3l%s"
end

-- Wrapping
vim.opt.wrap = false                    --  No line wrapping by default
vim.opt.linebreak = true                --  Wrap line at whitespace
vim.opt.breakindent = true              --  Continue original indentation on wrapped lines
vim.opt.breakindentopt = "list:-1"      --  ...and indent past list bullets (per 'formatlistpat')
-- With line numbers on, don't want showbreak
-- vim.opt.breakindentopt = "shift:2,sbr"  --  At least 2 column indent and enable showbreak
-- vim.opt.showbreak = "↪"                 --  Wrapping indicator e.g. ↪ ⤷ ↳ └─▶
-- Alternatively, show in place of a line number (busier screen):
-- if vim.fn.has("nvim-0.10") == 1 then
--  vim.opt.statuscolumn = "%{%v:virtnum > 0 && (&nu || &rnu) ? '%=↪' : '%3l'%}%s"
-- end
-- stylua: ignore end

-- Add a LineNr-colored bar in signcolumn when there are no signs, in order to blend in with gitsigns
-- _G.get_statuscol = function()
--   local signs = vim.fn.sign_getplaced(vim.api.nvim_get_current_buf(), {group = "*", lnum = vim.v.lnum})[1].signs
--   if #signs > 0 then return "%3l%s" else return "%3l%#LineNr#│%" end
-- end
-- vim.o.statuscolumn = "%!v:lua.get_statuscol()"

-- vim.uv is 0.10+, older nvim only has vim.loop (same libuv module). Lua code
-- loaded later can use vim.uv everywhere. lazy.nvim sets this too, but only
-- once required, and code below runs before that.
vim.uv = vim.uv or vim.loop

-- Initial GUI font. Set here rather than in ginit.vim to reduce flicker at startup.
-- Must be a single existing font: nvim-qt pre-0.2.20 doesn't support fallback
-- fonts and would report unknown fonts as an error with 1s freeze.
if vim.uv.fs_stat("/usr/share/fonts/truetype/iosevka/IosevkaNerdFont-Medium.ttf") then
  vim.o.guifont = "Iosevka NFM:h12"
else
  vim.o.guifont = "Monospace:h12"
end

vim.g.mapleader = " " -- <leader> key
vim.g.maplocalleader = "\\"

-- Window navigation: Ctrl+hjkl/arrows to switch windows
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Go to left window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Go to lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Go to upper window" })
-- Also what the default <C-l> does: clear search highlight, update diffs
vim.keymap.set("n", "<C-l>", "<Cmd>nohlsearch|diffupdate|redraw!<CR><C-w>l", { desc = "Go to right window + redraw" })
vim.keymap.set("n", "<S-Left>", "<C-w><C-h>", { desc = "Go to left window" })
vim.keymap.set("n", "<S-Down>", "<C-w><C-j>", { desc = "Go to lower window" })
vim.keymap.set("n", "<S-Up>", "<C-w><C-k>", { desc = "Go to upper window" })
vim.keymap.set("n", "<S-Right>", "<C-w>l", { desc = "Go to right window", silent = true })

-- Buffers (bufferline will override some of these if loaded)
-- Shift+PgUp/Down to switch buffers (rationale: next to Ctrl - switch tabs)
vim.keymap.set({ "n", "i" }, "<S-PageUp>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
vim.keymap.set({ "n", "i" }, "<S-PageDown>", "<cmd>bnext<cr>", { desc = "Next buffer" })
vim.keymap.set("n", "[b", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
vim.keymap.set("n", "]b", "<cmd>bnext<cr>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to other buffer" })

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
vim.keymap.set("n", "<leader>cd", ":cd %:p:h<CR>", { desc = "Change to current file's directory" })

-- Typing %%/ in command mode expands to current file's directory
-- fnameescape(): a dir like notes#1 would otherwise expand # to the alternate file
vim.cmd([[cabbr <expr> %% getcmdtype() == ':' ? fnameescape(expand('%:p:h')) : '%%']])

vim.g.in_container = vim.env.container ~= nil
  or vim.uv.fs_stat("/run/.containerenv") ~= nil
  or vim.uv.fs_stat("/.dockerenv") ~= nil
vim.g.icons_plugin = "nvim-mini/mini.icons"
vim.g.statusline_plugin = "lualine"
-- Nerd Font glyphs (icons, statusline arrows, ...), except on the Linux
-- console, whose fonts have none: plain characters there
vim.g.nerd_font = vim.env.TERM ~= "linux"

-- lazy.nvim requires 0.8+ (skip quietly instead of its error notification)
if vim.fn.has("nvim-0.8") == 0 then
  return
end

require("lazy").setup({
  -- Unless in container, load plugins from submodules only,
  -- don't install from git or check for updates.
  dev = {
    path = vim.fn.expand("~/.dotfiles/third_party"),
    fallback = vim.g.in_container,
  },
  install = { missing = vim.g.in_container },
  checker = { enabled = false },
  change_detection = { enabled = false },
  pkg = { enabled = false },
  rocks = { enabled = false },
  -- lockfile = vim.fn.stdpath("data") .. "/path/to/your/custom-lazy-lock.json",

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
