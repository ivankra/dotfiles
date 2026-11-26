-- Git status as letters, nvim-tree's default glyphs in the comments
-- stylua: ignore
local git_glyphs = {
  unstaged =  "M",  -- ✗ 
  staged =    "A",  -- ✓ 
  unmerged =  "C",  -- 
  renamed =   "R",  -- ➜
  untracked = "U",  -- ★ 
  deleted =   "D",
  ignored =   "I",  -- ◌ 
}

-- A folder's most important git state (VS Code's order), as a highlight
-- group suffix. Ignored contents don't count.
local function git_folder_state(node)
  local status = node.type == "directory" and node.git_status
  if not status then
    return nil
  end
  local xys = { status.file }
  vim.list_extend(xys, status.dir and status.dir.direct or {})
  vim.list_extend(xys, status.dir and status.dir.indirect or {})
  local found = {}
  for _, xy in pairs(xys) do
    if xy:find("U") or xy == "AA" or xy == "DD" then
      found.Merge = true
    elseif xy == "??" then
      found.New = true
    elseif xy ~= "!!" then
      found[xy:sub(2, 2) ~= " " and "Dirty" or "Staged"] = true -- worktree, else index
    end
  end
  return found.Merge and "Merge"
    or found.Dirty and "Dirty"
    or found.New and "New"
    or found.Staged and "Staged"
    or status.file == "!!" and "Ignored"
    or nil
end

-- Whether node is .git or inside it
local function in_dot_git(node)
  while node do
    if node.name == ".git" then
      return true
    end
    node = node.parent
  end
  return false
end

-- Folders: one ● and a colored name for git changes (as VS Code), instead
-- of the builtin's letters. Ignored ones and .git greyed.
local function git_folder_decorator()
  local Decorator = require("nvim-tree.api").Decorator:extend()
  function Decorator:new()
    self.enabled = true
    self.highlight_range = "name"
    self.icon_placement = "right_align"
  end
  function Decorator:icons(node)
    local state = git_folder_state(node)
    return state and state ~= "Ignored" and { { str = "●", hl = { "NvimTreeGit" .. state .. "Icon" } } } or nil
  end
  function Decorator:highlight_group(node)
    if in_dot_git(node) then
      return node.type == "directory" and "NvimTreeGitFolderIgnoredHL" or "NvimTreeGitFileIgnoredHL"
    end
    local state = git_folder_state(node)
    return state and "NvimTreeGitFolder" .. state .. "HL"
  end
  return Decorator
end

-- Git-ignored in NonText (as snacks), not Comment. Runs before nvim-tree's own ColorScheme autocmd.
local function nvim_tree_ignored_hl()
  local function link()
    if vim.tbl_isempty(vim.api.nvim_get_hl(0, { name = "NvimTreeGitIgnored" })) then
      vim.cmd("hi def link NvimTreeGitIgnoredIcon NonText")
    end
  end
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = vim.api.nvim_create_augroup("NvimTreeIgnoredHL", { clear = true }),
    callback = link,
  })
  link()
end

-- https://github.com/nvim-tree/nvim-tree.lua/wiki/Auto-Close
local function nvim_tree_auto_close()
  vim.api.nvim_create_autocmd("QuitPre", {
    group = vim.api.nvim_create_augroup("NvimTreeAutoClose", { clear = true }),
    callback = function()
      -- Quitting a float (e.g. a focused LSP hover) leaves the editor
      -- windows open, so the tree stays too
      if vim.api.nvim_win_get_config(0).relative ~= "" then
        return
      end
      local tree_wins = {}
      local floating_wins = {}
      -- Current tab only: with other tabs open, :q here would leave the tree alone in this tab
      local wins = vim.api.nvim_tabpage_list_wins(0)
      for _, w in ipairs(wins) do
        local bufname = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(w))
        if bufname:match("NvimTree_") ~= nil then
          table.insert(tree_wins, w)
        end
        if vim.api.nvim_win_get_config(w).relative ~= "" then
          table.insert(floating_wins, w)
        end
      end
      if 1 == #wins - #floating_wins - #tree_wins then
        -- Should quit, so we close all invalid windows.
        for _, w in ipairs(tree_wins) do
          vim.api.nvim_win_close(w, true)
        end
      end
    end,
  })
end

return {
  {
    "nvim-tree/nvim-tree.lua",
    dev = true,
    -- Lazy: oil.nvim handles directory buffers, so nothing needs the tree at startup
    cmd = { "NvimTreeToggle", "NvimTreeOpen", "NvimTreeFocus", "NvimTreeFindFile", "NvimTreeFindFileToggle" },
    dependencies = { vim.g.icons_plugin },
    keys = {
      { "<C-B>", ":NvimTreeFindFileToggle<CR>", desc = "Toggle Explorer", silent = true },
      { "<leader>e", ":NvimTreeFindFileToggle<CR>", desc = "Toggle Explorer", silent = true },
    },

    opts = function()
      local api = require("nvim-tree.api")
      local function on_attach(bufnr)
        api.config.mappings.default_on_attach(bufnr)
        -- Delete file with <Del> (in addition to "d")
        vim.keymap.set("n", "<Del>", api.fs.remove, { buffer = bufnr, desc = "Delete" })
        -- Single click to open file/folder
        vim.keymap.set("n", "<LeftRelease>", api.node.open.edit, { buffer = bufnr, desc = "Open" })
      end

      -- Deleted file: wipe its buffer but keep its window
      api.events.subscribe(api.events.Event.WillRemoveFile, function(data)
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_get_name(buf) == data.fname then
            require("mini.bufremove").wipeout(buf, true)
          end
        end
      end)
      -- Deleted folder with the only open file: reopen a window
      api.events.subscribe(api.events.Event.FolderRemoved, function()
        local wins = vim.tbl_filter(function(win)
          return vim.api.nvim_win_get_config(win).relative == ""
        end, vim.api.nvim_tabpage_list_wins(0))
        if #wins == 1 and vim.bo[vim.api.nvim_win_get_buf(wins[1])].filetype == "NvimTree" then
          vim.cmd("botright vnew | wincmd p")
          api.tree.resize()
        end
      end)

      return {
        on_attach = on_attach,
        sync_root_with_cwd = true,
        -- oil.nvim handles directory buffers (`nvim <dir>`, `:e dir/`)
        hijack_directories = { enable = false },
        git = { show_on_dirs = false }, -- git_folder_decorator instead
        filters = {
          -- Do not filter out hidden/ignored files by default (toggle with H/I)
          dotfiles = false,
          git_ignored = false,
        },
        filesystem_watchers = {
          enable = true,
        },
        -- Same for files in a deleted folder
        actions = { remove_file = { close_window = false } },
        update_focused_file = {
          enable = true, -- automatically focus on current buffer's file
        },
        view = { signcolumn = "no" },
        renderer = {
          -- nvim-tree's defaults, plus git_folder_decorator() before Cut
          decorators = {
            "Git",
            "Open",
            "Hidden",
            "Modified",
            "Bookmark",
            "Diagnostics",
            "Copied",
            git_folder_decorator(),
            "Cut",
          },
          -- No /.. suffix. Hidden while the tabline shows it (bufferline.lua)
          root_folder_label = ":~",
          -- Single-folder chains on one row: src/main/java
          group_empty = true,
          -- Don't add weird highlights to README/Makefile/etc
          special_files = {},
          highlight_git = "all",
          icons = {
            git_placement = "right_align",
            -- Without a Nerd Font: no folder icons, > / v arrows
            show = { folder = vim.g.nerd_font },
            glyphs = {
              git = git_glyphs,
              folder = not vim.g.nerd_font and { arrow_closed = ">", arrow_open = "v" } or nil,
            },
          },
        },
      }
    end,

    init = function()
      nvim_tree_ignored_hl()
      nvim_tree_auto_close()
    end,
  },
}
