-- Language servers (LSP) and completion, with nvim's built-in client (0.11+).
--
-- nvim-lspconfig only provides per-server configs (lsp/<name>.lua: command,
-- filetypes, root markers, server quirks). Servers aren't installed from
-- nvim: install them with apt/pipx/npm, and the ones found on $PATH get
-- enabled (see `servers`).
--
-- Keys in buffers with a server. Built in, so not mapped here:
--   K hover, grn rename, gra code action, grr references, gri implementation,
--   grt type definition (0.12), gO document symbols, <C-s> signature help
--   (insert mode), [d ]d next/prev diagnostic, <C-]> definition (tagfunc).
-- Added below: gd definition, gD declaration, <leader>uh toggle inlay hints,
--   and VS Code keys F2 rename, F12 definition, Shift+F12 references,
--   Ctrl+. code action.
-- Formatting (<leader>cf, gq): conform.nvim in conform.lua, which falls back to the server.
--
-- Completion: blink.cmp (init.lua). Without it (nvim 0.10, or its
-- submodule not checked out), nvim's own: the popup opens after the server's
-- trigger characters (`.`, `->`, ...), anytime with Ctrl+X Ctrl+O.

-- { lspconfig name, executable }
-- stylua: ignore
local servers = {
  { "clangd", "clangd" },                         -- C/C++
  { "lua_ls", "lua-language-server" },
  { "basedpyright", "basedpyright-langserver" },  -- Python types (pyright fork)
  { "pyright", "pyright-langserver" },            -- Python types, if no basedpyright
  { "ruff", "ruff" },                             -- Python lint + format
  { "bashls", "bash-language-server" },
  { "rust_analyzer", "rust-analyzer" },
  { "gopls", "gopls" },
  { "ts_ls", "typescript-language-server" },      -- JavaScript/TypeScript
  { "jsonnet_ls", "jsonnet-language-server" },
}
-- Servers to skip when another one is enabled
local skip_if = { pyright = "basedpyright" }

local function on_attach(ev)
  local client = vim.lsp.get_client_by_id(ev.data.client_id)
  if not client then
    return
  end
  local function map(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, desc = desc })
  end
  map("n", "gd", vim.lsp.buf.definition, "Go to definition")
  map("n", "<F2>", vim.lsp.buf.rename, "Rename symbol")
  map("n", "<F12>", vim.lsp.buf.definition, "Go to definition")
  map("n", "<S-F12>", vim.lsp.buf.references, "Find references")
  map({ "n", "x" }, "<C-.>", vim.lsp.buf.code_action, "Code action")
  if client:supports_method("textDocument/declaration") then
    map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
  end
  -- Inlay hints (inferred types, parameter names): off until toggled, per buffer
  if client:supports_method("textDocument/inlayHint") then
    map("n", "<leader>uh", function()
      local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = 0 })
      vim.lsp.inlay_hint.enable(not enabled, { bufnr = 0 })
      vim.notify("Inlay hints " .. (enabled and "off" or "on"))
    end, "Toggle inlay hints")
  end

  -- vim.g.lsp_builtin_completion = false: a completion plugin is used
  -- (blink.cmp, init.lua)
  if vim.g.lsp_builtin_completion ~= false and client:supports_method("textDocument/completion") then
    -- Not 0.12's 'autocomplete' (popup as you type): its 'autocompletedelay'
    -- doesn't work with the LSP source, it only delays drawing what you
    -- type (0.12.6, neovim#38628), and with no delay the popup flashes up
    -- mid-word.
    vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
  end
end

return {
  {
    "neovim/nvim-lspconfig",
    dev = true,
    -- Older nvim: no LSP setup. lspconfig would also warn at startup there.
    cond = vim.fn.has("nvim-0.11") == 1,
    -- Only config files, cheap. Must be in place before the first file opens.
    lazy = false,
    config = function()
      -- Neovim Lua (LuaJIT, vim.* API) unless the project has its own .luarc
      vim.lsp.config("lua_ls", {
        on_init = function(client)
          local folder = client.workspace_folders and client.workspace_folders[1]
          if
            folder and (vim.uv.fs_stat(folder.name .. "/.luarc.json") or vim.uv.fs_stat(folder.name .. "/.luarc.jsonc"))
          then
            return
          end
          client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua or {}, {
            runtime = { version = "LuaJIT", path = { "lua/?.lua", "lua/?/init.lua" } },
            workspace = { checkThirdParty = false, library = { vim.env.VIMRUNTIME } },
          })
        end,
        -- Always, whatever the project's .luarc says
        settings = { Lua = { telemetry = { enable = false } } },
      })

      -- No network access from servers. (gopls: Go telemetry is turned off
      -- by setup.sh, which also stops its opt-in prompt.)
      -- TypeScript would download @types packages from the npm registry for
      -- JavaScript projects ("automatic type acquisition").
      vim.lsp.config("ts_ls", { init_options = { disableAutomaticTypingAcquisition = true } })
      -- Off by default; would send shell code to explainshell.com on hover.
      vim.lsp.config("bashls", { settings = { bashIde = { explainshellEndpoint = "" } } })

      local enabled = {}
      for _, server in ipairs(servers) do
        local name, exe = server[1], server[2]
        if vim.fn.executable(exe) == 1 and not enabled[skip_if[name]] then
          vim.lsp.enable(name)
          enabled[name] = true
        end
      end

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLsp", { clear = true }),
        callback = on_attach,
      })

      -- No preselected item, docs next to the menu, fuzzy matching.
      -- pcall: values unknown to this nvim build would error.
      if not pcall(function()
        vim.opt.completeopt = { "menuone", "noselect", "popup", "fuzzy" }
      end) then
        vim.opt.completeopt = { "menuone", "noselect" }
      end
      -- No "match 1 of 2" etc. messages while the popup is open
      vim.opt.shortmess:append("c")
      -- Cap the menu's width (0.12+), cutting long lines with "…" (default
      -- ">"), so the docs window next to it keeps room
      if vim.fn.exists("+pummaxwidth") == 1 then
        vim.o.pummaxwidth = 70
        vim.opt.fillchars:append({ trunc = "…" })
      end

      -- 0.11 shows only signs by default. Also the full messages, on lines
      -- of their own below the cursor line only (none get cut off at the
      -- window edge, and other lines stay clean). [d / ]d land there too.
      -- The sign column is one sign wide and shared with gitsigns (priority
      -- 6). Diagnostic signs go below it, so a changed line keeps its git
      -- sign; the diagnostic still shows as the colored line number, and
      -- its message on the cursor line. severity_sort adds 0-3 to the priority
      -- (ERROR highest), so 2 keeps all severities under 6.
      local sev = vim.diagnostic.severity
      vim.diagnostic.config({
        signs = {
          priority = 2,
          numhl = {
            [sev.ERROR] = "DiagnosticSignError",
            [sev.WARN] = "DiagnosticSignWarn",
            [sev.INFO] = "DiagnosticSignInfo",
            [sev.HINT] = "DiagnosticSignHint",
          },
        },
        virtual_lines = { current_line = true },
        severity_sort = true,
        float = { source = "if_many" },
      })
    end,
  },
}
