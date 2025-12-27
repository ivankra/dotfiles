vim.opt.clipboard = "unnamedplus"       -- Yank/paste using X11 clipboard
vim.opt.confirm = true                  -- Confirm to save when closing a modified buffer instead of error
vim.opt.cursorline = true               -- Highlight current line
vim.opt.fillchars = { eob = " " }       -- Don't show ~ for non-existing lines in a buffer
vim.opt.foldmethod = "marker"           -- Default folding method: {{{ and }}} markers
vim.opt.gdefault = true                 -- Enable /g flag by default for search & replace (flip its on/off status)
vim.opt.ignorecase = true               -- Case-insensitive search by default (add \C to pattern to override)
vim.opt.laststatus = 3                  -- Global statusline (nvim)
vim.opt.list = true                     -- Show substitutes for some special chars
vim.opt.listchars = "tab:→ ,trail:▞,nbsp:␣"  -- e.g. →⊢⇤⇠⇢•◌◼⯁▮▯∵∴␠×✘╳␣⎵▞░▒▓◘
vim.opt.pumheight = 15                  -- Limit popup menu's height
vim.opt.showmode = false                -- Don't show mode since it's already in the statusline
vim.opt.smartcase = true                -- Case-sensitive search if pattern contains uppercase characters
vim.opt.splitbelow = true               -- Put new split window below
vim.opt.splitright = true               -- Put new vertically split window to the right
vim.opt.termguicolors = true            -- Enable 24-bit color in terminal
vim.opt.undofile = true                 -- Persistent undo history
vim.opt.virtualedit = "block"           -- Allow cursor to move nd end-of-line in block selection mode
vim.opt.wildmode = "longest:full,full"  -- Completion mode like readline's show-all-if-ambiguous

-- Wrapping
vim.opt.wrap = false                    --  No line wrapping by default
vim.opt.linebreak = true                --  Wrap line at whitespace
vim.opt.breakindent = true              --  Continue original indentation on wrapped lines
vim.opt.breakindentopt = "shift:2,sbr"  --  At least 2 column indent and enable showbreak
vim.opt.showbreak = "↪"                 --  Wrapping indicator e.g. ↪ ⤷ ↳ └─▶

-- Default indent options. Will get adjusted by guess-indent.nvim.
vim.opt.expandtab = true                -- Expand tabs
vim.opt.shiftwidth = 2                  -- 2 space indent
vim.opt.smartindent = true              -- C-like indent (between autoindent and cindent)
vim.opt.softtabstop = -1                -- Use shiftwidth value

-- Status column
-- vim.opt.number = true                 -- Show line numbers
-- vim.opt.signcolumn = "yes"            -- Always show sign column
-- vim.opt.statuscolumn = "%4l %s"
vim.g.gitsigns_signcolumn = false

vim.g.mapleader = " "                   -- <leader> key
vim.g.maplocalleader = "\\"

-- Window navigation
vim.keymap.set("n", "<C-h>", "<C-w><C-h>", { desc = "Go to left window" })
vim.keymap.set("n", "<C-j>", "<C-w><C-j>", { desc = "Go to lower window" })
vim.keymap.set("n", "<C-k>", "<C-w><C-k>", { desc = "Go to upper window" })
vim.keymap.set("n", "<C-l>", ":redraw!<CR><C-w>l", { desc = "Go to right window + redraw", silent = true })
vim.keymap.set("n", "<S-Left>", "<C-w><C-h>", { desc = "Go to left window" })
vim.keymap.set("n", "<S-Down>", "<C-w><C-j>", { desc = "Go to lower window" })
vim.keymap.set("n", "<S-Up>", "<C-w><C-k>", { desc = "Go to upper window" })
vim.keymap.set("n", "<S-Right>", "<C-w>l", { desc = "Go to right window", silent = true })

-- Buffers (bufferline will override some of these if loaded)
-- Shift+PgUp/PgDown to switch between buffers, rationale: next to Ctrl (switch tabs)
vim.keymap.set("n", "<S-PageUp>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
vim.keymap.set("n", "<S-PageDown>", "<cmd>bnext<cr>", { desc = "Next buffer" })
vim.keymap.set("n", "[b", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
vim.keymap.set("n", "]b", "<cmd>bnext<cr>", { desc = "Next buffer" })
vim.keymap.set("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to other buffer" })
vim.keymap.set("n", "<leader>bd", "<cmd>bd<cr>", { desc = "Delete buffer" })

vim.keymap.set("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
vim.keymap.set("n", "<leader>cd", ":cd %:p:h<CR>", { desc = "Change to current file's directory" })
vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], { desc = "Exit terminal mode" })

-- Typing %%/ in command mode expands to current file's directory
vim.cmd([[cabbr <expr> %% expand('%:p:h')]])

-- Start terminals in insert mode and define buffer-local keybindings
vim.api.nvim_create_autocmd("TermOpen", {
  pattern = "term://*",
  callback = function(ev)
    -- Double [Esc]: switch from terminal to normal mode
    vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], { buffer = ev.buf, silent = true })
    -- [Enter]: switch from normal to insert mode
    vim.keymap.set("n", "<CR>", "i", { buffer = ev.buf, silent = true, noremap = true })
  end,
})

-- More aggressive autoread
-- Maybe also set `set -g focus-events on` in tmux
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "TermClose", "TermLeave" }, {
  group = vim.api.nvim_create_augroup("AutoReadCheck", { clear = true }),
  callback = function()
    if vim.o.buftype ~= "nofile" then
      vim.cmd("checktime")
    end
  end,
})

-- Highlight yanked text briefly
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("HighlightYank", { clear = true }),
  callback = function()
    (vim.hl or vim.highlight).on_yank()
  end,
})

local function in_container()
  if (vim.env.container ~= nil or
      vim.loop.fs_stat("/run/.containerenv") or
      vim.loop.fs_stat("/.dockerenv")) then
    return true
  else
    return false
  end
end

vim.g.in_container = in_container()
vim.g.icons_provider = "nvim-mini/mini.icons"
-- vim.g.icons_provider = "nvim-tree/nvim-web-devicons"

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
  doc = { generate = false },

  performance = {
    rtp = {
      disabled_plugins = {
        -- Disable netrw in favor of nvim-tree/oil
        "netrwPlugin"
      }
    }
  },

  spec = {
    -- Imports all ~/.config/nvim/lua/plugins/*.lua
    { import = "plugins" }
  }
})

-- Autoloaded vim plugins in ~/.config/nvim/plugin/ (shared with vim):
-- chmod.vim: chmod a+x new files with a shebang
-- fileline.vim: interpret 'filename[:line[:col]]' filenames
-- projectionist.vim: vim-projectionist config
-- vscode.vim: vscode-like key bindinds
-- wrap.vim: toggle line wrapping with <A-z> / <leader>uw
