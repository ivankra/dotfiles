-- Formatting with conform.nvim (0.10+): the filetype's formatter where
-- installed (:ConformInfo shows which), else the language server (clangd,
-- gopls, rust-analyzer, ...; lsp.lua). Only on demand, never on save:
--   <leader>cf  the buffer, or the selection (v/V)
--   <leader>cF  code in other languages inside it, e.g. Markdown code blocks
--   gq{motion}  the lines, in buffers with a formatter (else nvim's default)
-- Some ideas from LazyVim (plugins/formatting.lua, extras/formatting/prettier.lua).

-- prettierd: the same as a daemon, faster
local prettier = { "prettierd", "prettier", stop_after_first = true }
local formatters_by_ft = {
  lua = { "stylua" },
  -- Lint fixes (ruff's default rules, e.g. unused imports are removed),
  -- formatting, then sorted imports
  python = { "ruff_fix", "ruff_format", "ruff_organize_imports" },
  -- Indent from .editorconfig, else the buffer's (conform passes -i shiftwidth)
  sh = { "shfmt" },
}
-- Prettier's languages, LazyVim's list
for _, ft in ipairs({
  "css",
  "graphql",
  "handlebars",
  "html",
  "javascript",
  "javascriptreact",
  "json",
  "jsonc",
  "less",
  "markdown",
  "markdown.mdx",
  "scss",
  "typescript",
  "typescriptreact",
  "vue",
  "yaml",
}) do
  formatters_by_ft[ft] = prettier
end

-- A blockwise selection isn't passed on as a range: it would format the whole file
local function format(opts)
  if vim.fn.mode() == "\22" then
    vim.notify("Can't format a block selection, use v or V", vim.log.levels.WARN)
    return
  end
  require("conform").format(opts)
end

return {
  {
    "stevearc/conform.nvim",
    dev = true,
    cond = vim.fn.has("nvim-0.10") == 1,
    cmd = "ConformInfo",
    keys = {
      {
        "<leader>cf",
        function()
          format({ async = true })
        end,
        mode = { "n", "x" },
        desc = "Format buffer/selection",
      },
      {
        "<leader>cF",
        function()
          format({ formatters = { "injected" }, async = true })
        end,
        mode = { "n", "x" },
        desc = "Format code in other languages (injected)",
      },
    },
    opts = {
      formatters_by_ft = formatters_by_ft,
      default_format_opts = {
        -- For gq, which waits: the default 1s is short for the ruff chain
        -- or prettier on a big file
        timeout_ms = 3000,
        lsp_format = "fallback",
      },
      formatters = {
        -- Skip code blocks that don't parse, instead of failing the rest
        injected = { options = { ignore_errors = true } },
      },
    },
    init = function()
      -- gq{motion} formats with conform too, in buffers with an installed
      -- formatter for their filetype. Not everywhere: with no formatter,
      -- conform's gq does nothing. Elsewhere nvim's defaults stay: the
      -- server's formatting where one attaches (it only sets 'formatexpr' if
      -- empty), else line wrapping. gw always wraps lines (e.g. comments).
      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("ConformFormatexpr", { clear = true }),
        pattern = vim.tbl_keys(formatters_by_ft),
        callback = function(ev)
          if #require("conform").list_formatters_to_run(ev.buf) > 0 then
            vim.bo[ev.buf].formatexpr = "v:lua.require'conform'.formatexpr()"
          end
        end,
      })
    end,
  },
}
