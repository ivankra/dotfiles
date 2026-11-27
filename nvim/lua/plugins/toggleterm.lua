-- Toggleable terminal on Ctrl+`/Ctrl+Space.
-- Floating lazygit window on <leader>gg / :Lazygit.

-- Own lazygit config plus lazygit.yml (e opens files in this nvim), for
-- LG_CONFIG_FILE. Missing files are errors, so only existing ones.
local function lazygit_configs()
  local configs = {}
  for _, file in ipairs({
    (vim.env.XDG_CONFIG_HOME or vim.env.HOME .. "/.config") .. "/lazygit/config.yml",
    vim.g.dotfiles .. "/nvim/lazygit.yml",
  }) do
    if vim.uv.fs_stat(file) then
      table.insert(configs, file)
    end
  end
  return table.concat(configs, ",")
end

-- :Lazygit: toggleable floating window with lazygit
local function lazygit_command()
  local lazygit
  vim.api.nvim_create_user_command("Lazygit", function()
    -- Fallback to fugitive if lazygit is not installed
    if vim.fn.executable("lazygit") == 0 then
      vim.cmd(vim.bo.filetype == "fugitive" and "normal gq" or "Git")
      return
    end
    -- The current buffer's repo, as fugitive (no file, e.g. nvim-tree: cwd's).
    -- Kept running while it's the same; from inside lazygit just hide it.
    local root = vim.fs.root(0, ".git") or vim.fn.getcwd()
    if lazygit and lazygit.dir ~= root and vim.api.nvim_get_current_buf() ~= lazygit.bufnr then
      lazygit:shutdown()
      lazygit = nil
    end
    lazygit = lazygit
      or require("toggleterm.terminal").Terminal:new({
        cmd = "lazygit",
        env = { LG_CONFIG_FILE = lazygit_configs() },
        dir = root,
        -- Quit (q): forget it, as toggleterm frees its id for other terminals.
        -- Unless already replaced (shutdown() exits it later).
        on_exit = function(term)
          if lazygit == term then
            lazygit = nil
          end
        end,
        direction = "float",
        display_name = " lazygit ", -- float's title
        float_opts = { title_pos = "center" },
        hidden = true,
        on_create = function(term)
          local map_opts = { buffer = term.bufnr, desc = "Toggle lazygit" }
          vim.keymap.set("t", "<C-S-G>", "<cmd>Lazygit<cr>", map_opts)
          -- Esc is lazygit's (plugin/autocmds.lua maps <Esc><Esc>)
          pcall(vim.keymap.del, "t", "<Esc><Esc>", { buffer = term.bufnr })
        end,
      })
    lazygit:toggle()
  end, { desc = "Toggle lazygit" })
end

return {
  {
    "akinsho/toggleterm.nvim",
    dev = true,
    -- <C-Space> not in insert mode or on the : line: blink.cmp's (init.lua).
    -- Terminals that send <C-`> as <C-Space> (NUL), like gnome-terminal and
    -- ptyxis, toggle with Ctrl+` there too.
    cmd = { "ToggleTerm", "TermExec", "TermNew", "Lazygit" },
    -- No rhs: the first press loads the plugin, then hits its open_mapping
    keys = {
      { "<C-`>", mode = { "n", "i" }, desc = "Toggle terminal" },
      { "<C-Space>", "<cmd>ToggleTerm<cr>", desc = "Toggle terminal" },
      { "<leader>gg", "<cmd>Lazygit<cr>", desc = "Lazygit" }, -- also Ctrl+Shift+G (vscode.vim)
    },
    opts = {
      open_mapping = [[<C-`>]],
      -- Closing from inside one: its own terminal mode only, so programs in
      -- other terminals (:terminal) keep Ctrl+Space
      on_create = function(term)
        vim.keymap.set("t", "<C-Space>", "<cmd>ToggleTerm<cr>", { buffer = term.bufnr, desc = "Toggle terminal" })
      end,
    },
    config = function(_, opts)
      require("toggleterm").setup(opts)
      lazygit_command()
    end,
  },
}
