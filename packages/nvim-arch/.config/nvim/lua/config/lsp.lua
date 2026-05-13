-- LSP setup using Neovim 0.12's built-in vim.lsp.config() / vim.lsp.enable().
-- No nvim-lspconfig: every server is fully described locally so there is
-- ZERO third-party plugin dependency. Servers must be on $PATH; missing ones
-- are skipped at the bottom of this file (and can be re-checked at runtime
-- with :LspEnableAll, see end of file).

-- ============================================================================
-- Capabilities & defaults (applied to every server via vim.lsp.config('*')).
-- ============================================================================

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true
capabilities.textDocument.completion.completionItem.resolveSupport = {
  properties = { "documentation", "detail", "additionalTextEdits" },
}
capabilities.textDocument.foldingRange = {
  dynamicRegistration = false,
  lineFoldingOnly = true,
}

vim.lsp.config("*", {
  capabilities = capabilities,
  root_markers = { ".git", ".hg", ".svn" },
})

-- ============================================================================
-- Per-server configs. Add/remove freely; only servers whose binary is found
-- on $PATH are actually enabled below.
-- ============================================================================

vim.lsp.config("lua_ls", {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = { ".luarc.json", ".luarc.jsonc", ".stylua.toml", "stylua.toml", ".git" },
  settings = {
    Lua = {
      runtime = { version = "LuaJIT" },
      workspace = {
        checkThirdParty = false,
        library = {
          vim.env.VIMRUNTIME,
          "${3rd}/luv/library",
        },
      },
      diagnostics = { globals = { "vim" } },
      telemetry = { enable = false },
      hint = { enable = true },
    },
  },
})

vim.lsp.config("pyright", {
  cmd = { "pyright-langserver", "--stdio" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "Pipfile", ".git" },
  settings = {
    python = {
      analysis = {
        typeCheckingMode = "basic",
        useLibraryCodeForTypes = true,
        diagnosticMode = "openFilesOnly",
      },
    },
  },
})

vim.lsp.config("ruff", {
  cmd = { "ruff", "server" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", "ruff.toml", ".ruff.toml", ".git" },
})

vim.lsp.config("vtsls", {
  cmd = { "vtsls", "--stdio" },
  filetypes = {
    "javascript", "javascriptreact",
    "typescript", "typescriptreact",
    "vue",
  },
  root_markers = { "tsconfig.json", "jsconfig.json", "package.json", ".git" },
})

vim.lsp.config("clangd", {
  cmd = { "clangd", "--background-index", "--clang-tidy", "--header-insertion=iwyu" },
  filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
  root_markers = { ".clangd", "compile_commands.json", "compile_flags.txt", "Makefile", ".git" },
})

vim.lsp.config("zls", {
  cmd = { "zls" },
  filetypes = { "zig", "zir" },
  root_markers = { "zls.json", "build.zig", ".git" },
  settings = {
    zls = {
      enable_inlay_hints = true,
      inlay_hints_show_variable_type_hints = true,
      inlay_hints_show_parameter_name = true,
      warn_style = true,
    },
  },
})

vim.lsp.config("julials", {
  cmd = { "julia", "--startup-file=no", "--history-file=no", "-e", [[
    using LanguageServer
    runserver()
  ]] },
  filetypes = { "julia" },
  root_markers = { "Project.toml", "JuliaProject.toml", ".git" },
})

vim.lsp.config("sqlls", {
  cmd = { "sql-language-server", "up", "--method", "stdio" },
  filetypes = { "sql", "mysql" },
  root_markers = { ".sqllsrc.json", ".git" },
})

vim.lsp.config("marksman", {
  cmd = { "marksman", "server" },
  filetypes = { "markdown", "markdown.mdx" },
  root_markers = { ".marksman.toml", ".git" },
})

vim.lsp.config("jsonls", {
  cmd = { "vscode-json-language-server", "--stdio" },
  filetypes = { "json", "jsonc" },
  root_markers = { ".git" },
})

vim.lsp.config("yamlls", {
  cmd = { "yaml-language-server", "--stdio" },
  filetypes = { "yaml", "yaml.docker-compose" },
  root_markers = { ".git" },
})

vim.lsp.config("html", {
  cmd = { "vscode-html-language-server", "--stdio" },
  filetypes = { "html" },
  root_markers = { "package.json", ".git" },
})

vim.lsp.config("cssls", {
  cmd = { "vscode-css-language-server", "--stdio" },
  filetypes = { "css", "scss", "less" },
  root_markers = { "package.json", ".git" },
})

vim.lsp.config("tailwindcss", {
  cmd = { "tailwindcss-language-server", "--stdio" },
  filetypes = {
    "html", "css", "scss",
    "javascript", "javascriptreact",
    "typescript", "typescriptreact",
    "vue", "svelte", "astro",
  },
  root_markers = {
    "tailwind.config.js", "tailwind.config.cjs", "tailwind.config.mjs", "tailwind.config.ts", ".git",
  },
})

-- ============================================================================
-- Enable servers whose first cmd entry is actually executable.
-- ============================================================================

local servers = {
  "lua_ls",
  "pyright",
  "ruff",
  "vtsls",
  "clangd",
  "zls",
  "julials",
  "sqlls",
  "marksman",
  "html",
  "cssls",
  "tailwindcss",
  "jsonls",
  "yamlls",
}

local function enable_available_servers()
  for _, name in ipairs(servers) do
    local cfg = vim.lsp.config[name]
    if cfg and cfg.cmd and vim.fn.executable(cfg.cmd[1]) == 1 then
      vim.lsp.enable(name)
    end
  end
end

enable_available_servers()

-- Re-probe servers after the user installs them later (handy when the
-- pacman list grows or rustup / npm / etc. drop new binaries on PATH).
vim.api.nvim_create_user_command("LspEnableAll", function()
  enable_available_servers()
  vim.notify("LSP: re-checked servers on $PATH", vim.log.levels.INFO)
end, { desc = "Re-probe $PATH and enable any newly available LSP server" })

-- ============================================================================
-- LspAttach: per-buffer keymaps, native LSP completion + feature opt-ins.
-- The 0.12 defaults already provide grn / gra / grr / gri / grt / gO / <C-S>.
-- We add the conventional <leader>-prefixed equivalents and toggles.
-- ============================================================================

vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("UserLspAttach", { clear = true }),
  callback = function(args)
    local bufnr = args.buf
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then
      return
    end

    -- Native, plugin-free triggered LSP completion (Neovim 0.11+).
    -- Pops the menu automatically when the LSP advertises trigger characters.
    if client:supports_method("textDocument/completion") then
      pcall(function()
        vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
      end)
    end

    -- omnifunc (for manual <C-x><C-o> completion fallback).
    vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"

    local function map(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
    end

    map("n", "K", vim.lsp.buf.hover, "LSP hover")
    map("n", "gd", vim.lsp.buf.definition, "Go to definition")
    map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
    map("n", "gy", vim.lsp.buf.type_definition, "Go to type definition")
    map("n", "<leader>la", vim.lsp.buf.code_action, "Code action")
    map("n", "<leader>lr", vim.lsp.buf.rename, "Rename symbol")
    map("n", "<leader>lf", function()
      vim.lsp.buf.format({ async = true })
    end, "Format buffer")
    map("v", "<leader>lf", function()
      vim.lsp.buf.format({ async = true })
    end, "Format selection")
    map("n", "<leader>ls", vim.lsp.buf.signature_help, "Signature help")
    map("n", "<leader>lR", vim.lsp.buf.references, "References")
    map("n", "<leader>li", vim.lsp.buf.implementation, "Implementation")
    map("n", "<leader>lo", vim.lsp.buf.document_symbol, "Document symbols")
    map("n", "<leader>lO", vim.lsp.buf.workspace_symbol, "Workspace symbols")

    -- Inlay hints (toggle).
    if client:supports_method("textDocument/inlayHint") then
      vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
      map("n", "<leader>lh", function()
        vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }), { bufnr = bufnr })
      end, "Toggle inlay hints")
    end

    -- Document highlight on CursorHold.
    if client:supports_method("textDocument/documentHighlight") then
      local hl_grp = vim.api.nvim_create_augroup("UserLspDocHL." .. bufnr, { clear = true })
      vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
        group = hl_grp,
        buffer = bufnr,
        callback = vim.lsp.buf.document_highlight,
      })
      vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI", "BufLeave" }, {
        group = hl_grp,
        buffer = bufnr,
        callback = vim.lsp.buf.clear_references,
      })
    end

    -- Code lens refresh.
    if client:supports_method("textDocument/codeLens") then
      vim.api.nvim_create_autocmd({ "BufEnter", "InsertLeave", "CursorHold" }, {
        buffer = bufnr,
        callback = function()
          vim.lsp.codelens.refresh({ bufnr = bufnr })
        end,
      })
      map("n", "<leader>lL", vim.lsp.codelens.run, "Run code lens")
    end
  end,
})

-- ============================================================================
-- Tab / S-Tab navigation when the native pum is open.
-- (No completion plugin: this is the only thing wiring Tab to the menu.)
-- ============================================================================
vim.keymap.set("i", "<Tab>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-n>"
  end
  return "<Tab>"
end, { expr = true, desc = "Pum: next item / Tab" })

vim.keymap.set("i", "<S-Tab>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-p>"
  end
  return "<S-Tab>"
end, { expr = true, desc = "Pum: prev item / S-Tab" })

vim.keymap.set("i", "<CR>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-y>"
  end
  return "<CR>"
end, { expr = true, desc = "Pum: accept / newline" })

-- Manually trigger LSP completion (in case autotrigger is off in some buffer).
vim.keymap.set("i", "<C-Space>", function()
  vim.lsp.completion.get()
end, { desc = "Trigger LSP completion" })

-- ============================================================================
-- Diagnostic navigation (works without an attached LSP too).
-- ============================================================================

vim.keymap.set("n", "]d", function()
  vim.diagnostic.jump({ count = 1, float = true })
end, { desc = "Next diagnostic" })

vim.keymap.set("n", "[d", function()
  vim.diagnostic.jump({ count = -1, float = true })
end, { desc = "Prev diagnostic" })

vim.keymap.set("n", "]e", function()
  vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR, float = true })
end, { desc = "Next error" })

vim.keymap.set("n", "[e", function()
  vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR, float = true })
end, { desc = "Prev error" })

vim.keymap.set("n", "<leader>ld", vim.diagnostic.open_float, { desc = "Line diagnostics" })
vim.keymap.set("n", "<leader>lq", vim.diagnostic.setloclist, { desc = "Diagnostics → loclist" })
vim.keymap.set("n", "<leader>lt", function()
  vim.diagnostic.enable(not vim.diagnostic.is_enabled())
end, { desc = "Toggle diagnostics" })
