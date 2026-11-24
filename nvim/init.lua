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
vim.opt.wildmode = "longest:full,full"  -- Completion mode like readline's show-all-if-ambiguous

-- Yank/paste using X11 clipboard, except over SSH (OSC 52)
vim.schedule(function()
  vim.opt.clipboard = vim.env.SSH_CONNECTION and "" or "unnamedplus"
end)

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

-- Comments: built-in `gcc` (line, takes a count) and `gc{motion}` / visual `gc` (0.10+).
-- Ctrl+/ toggles line comments (VS Code style binding).
-- Cursor column shift for text after the indentation when gcc turned line
-- `before` into `after`: the width of the opening marker that was added (+)
-- or removed (-). Not the whole length change: a closing marker (HTML's
-- ` -->`) goes after the cursor.
local function comment_cursor_shift(before, after, indent, commentstring)
  local long, short, sign = after, before, 1
  if #after < #before then
    long, short, sign = before, after, -1
  elseif #after == #before then
    return 0
  end
  local text = short:sub(indent + 1)
  -- gcc inserts commentstring's parts as they are: indent .. left .. text .. right
  local left, right = commentstring:match("^(.-)%%s(.-)$")
  if left then
    if text == "" then
      return sign * #left:match("^%s*(.-)%s*$") -- blank line: unpadded marker
    elseif long == short:sub(1, indent) .. left .. text .. right then
      return sign * #left
    end
  end
  -- Otherwise (treesitter-injected language with its own commentstring, like
  -- JS inside HTML; a marker removed without its padding): where the text
  -- starts, after a non-empty marker
  local s = long:find(text, indent + 2, true)
  return s and sign * (s - 1 - indent) or 0
end
-- In insert mode, keep typing where you were: gcc moves the cursor to column 0
local function toggle_comment_insert()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local before = vim.api.nvim_get_current_line()
  local indent = (before:find("%S") or 1) - 1 -- where the comment marker goes
  vim.cmd("normal gcc")
  if col >= indent then
    local after = vim.api.nvim_get_current_line()
    -- Not back into the indentation (cursor was inside a removed marker)
    col = math.max(indent, col + comment_cursor_shift(before, after, indent, vim.bo.commentstring))
  end
  vim.api.nvim_win_set_cursor(0, { row, col })
end
local function map_comment_key(key)
  vim.keymap.set("n", key, "gcc", { remap = true, desc = "Toggle comment" })
  vim.keymap.set("x", key, "gc", { remap = true, desc = "Toggle comment" })
  vim.keymap.set("i", key, toggle_comment_insert, { desc = "Toggle comment" })
end
-- Older nvim has no gcc to map to
if vim.fn.has("nvim-0.10") == 1 then
  map_comment_key("<C-/>")
  -- CLI terminals usually send <C-_> on Ctrl+/. In GUIs it's Ctrl+- (font size,
  -- see vscode.vim). GUIs aren't known yet while init.lua runs (g:GuiLoaded is
  -- set after attaching), so decide on UIEnter, like vscode.vim's SetupGui().
  vim.api.nvim_create_autocmd("UIEnter", {
    once = true,
    callback = function()
      if vim.fn.has("gui_running") == 0 and not vim.g.GuiLoaded then
        map_comment_key("<C-_>")
      end
    end,
  })
end

-- Typing %%/ in command mode expands to current file's directory
-- fnameescape(): a dir like notes#1 would otherwise expand # to the alternate file
vim.cmd([[cabbr <expr> %% getcmdtype() == ':' ? fnameescape(expand('%:p:h')) : '%%']])

-- Reopen files where the cursor was last time (the '" mark, kept in shada).
-- Like vim's defaults.vim, and :h restore-cursor. Not in commit messages and
-- rebase todos (new text each time), hex dumps or diffs.
vim.api.nvim_create_autocmd("BufReadPost", {
  group = vim.api.nvim_create_augroup("RestoreCursor", { clear = true }),
  callback = function(ev)
    -- Runs before filetype detection (enabled after init.lua), so ask for it
    -- (0.8+: older vim.filetype.match() takes other arguments)
    local ft = vim.bo[ev.buf].filetype
    if ft == "" and vim.fn.has("nvim-0.8") == 1 then
      ft = vim.filetype.match({ buf = ev.buf }) or ""
    end
    if ft:find("commit") or ft == "gitrebase" or ft == "xxd" or vim.wo.diff then
      return
    end
    local line = vim.api.nvim_buf_get_mark(ev.buf, '"')[1]
    if line >= 1 and line <= vim.api.nvim_buf_line_count(ev.buf) then
      vim.cmd('normal! g`"')
    end
  end,
})

-- Start terminals in insert mode and define buffer-local keybindings
vim.api.nvim_create_autocmd("TermOpen", {
  group = vim.api.nvim_create_augroup("TermSetup", { clear = true }),
  pattern = "term://*",
  callback = function(ev)
    -- Double [Esc]: switch from terminal to normal mode
    vim.keymap.set("t", "<Esc><Esc>", [[<C-\><C-n>]], { buffer = ev.buf, silent = true })
    -- [Enter]: switch from normal to insert mode
    vim.keymap.set("n", "<CR>", "i", { buffer = ev.buf, silent = true })
    -- Only if it's the current buffer: a plugin may start a terminal in a
    -- hidden buffer, and then this would put the current one in Insert mode
    if ev.buf == vim.api.nvim_get_current_buf() then
      vim.cmd("startinsert")
    end
  end,
})
-- Because of <Esc><Esc>, a single Esc reaches the terminal app only after
-- 'timeoutlen'. Shorten it in terminal mode so Esc-heavy apps (vi-mode shell,
-- fzf, lazygit) lag less. The same value is the double-tap window, so not
-- too short: 150ms was easy to miss.
local term_timeoutlen = 250
local saved_timeoutlen
vim.api.nvim_create_autocmd("ModeChanged", {
  group = vim.api.nvim_create_augroup("TermTimeoutlen", { clear = true }),
  pattern = { "*:t", "t:*" },
  callback = function()
    if vim.v.event.new_mode == "t" then
      saved_timeoutlen = saved_timeoutlen or vim.o.timeoutlen
      vim.o.timeoutlen = term_timeoutlen
    elseif saved_timeoutlen then
      vim.o.timeoutlen = saved_timeoutlen
      saved_timeoutlen = nil
    end
  end,
})

-- Autoread: 'autoread' only acts when nvim checks files, so check on these
-- events. Instant reloads: hotreload.nvim (lua/plugins/init.lua), which skips
-- modified buffers; these checks prompt for those. FocusGained needs tmux
-- focus-events.
local function checktime()
  -- checktime checks all buffers; it errors in the cmdline window
  if vim.fn.getcmdwintype() == "" then
    pcall(vim.cmd, "checktime") -- not vim.cmd.checktime: 0.8+
  end
end
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "TermClose", "TermLeave" }, {
  group = vim.api.nvim_create_augroup("AutoReadCheck", { clear = true }),
  callback = function(ev)
    checktime()

    -- Refresh nvim-tree if it's open. Only on focus: while in nvim, its
    -- filesystem watchers already keep it up to date.
    local tree_api = package.loaded["nvim-tree.api"]
    if ev.event == "FocusGained" and tree_api then
      -- pcall around the lookups too, in case the API isn't fully there
      pcall(function()
        if tree_api.tree.is_visible() then
          tree_api.tree.reload()
        end
      end)
    end
  end,
})

-- Treesitter highlighting for languages whose parsers ship with nvim.
-- More languages need nvim-treesitter (see docker/dvim/dvim.lua).
if vim.fn.has("nvim-0.10") == 1 then
  vim.api.nvim_create_autocmd("FileType", {
    group = vim.api.nvim_create_augroup("BundledTreesitter", { clear = true }),
    pattern = { "c", "lua", "vim", "markdown", "query" }, -- help: nvim's own ftplugin
    callback = function(ev)
      pcall(vim.treesitter.start, ev.buf) -- no-op if this build lacks the parser
    end,
  })
end

-- Highlight yanked text briefly
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("HighlightYank", { clear = true }),
  callback = function()
    -- 0.13 replaces on_yank() with hl_op(); vim.hl is 0.11+, vim.highlight older
    if vim.fn.has("nvim-0.13") == 1 then
      vim.hl.hl_op()
    else
      (vim.hl or vim.highlight).on_yank()
    end
  end,
})

vim.g.in_container = vim.env.container ~= nil
  or vim.uv.fs_stat("/run/.containerenv") ~= nil
  or vim.uv.fs_stat("/.dockerenv") ~= nil
vim.g.icons_provider = "nvim-mini/mini.icons"
-- vim.g.icons_provider = "nvim-tree/nvim-web-devicons"
vim.g.statusline_plugin = "lualine"

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
-- chmod.vim: chmod a+rx files that become scripts (new, or shebang added)
-- fileline.vim: interpret 'filename[:line[:col]]' filenames
-- projectionist.vim: vim-projectionist config
-- typos.vim: :W/:Wq for :w/:wq, 'langmap' for the Russian layout
-- vscode.vim: vscode-like key bindings
-- ui.vim: UI toggles (<leader>u*)
