vim.diagnostic.config({
  underline = true,
  severity_sort = true,
  update_in_insert = false,
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "E",
      [vim.diagnostic.severity.WARN] = "W",
      [vim.diagnostic.severity.HINT] = "H",
      [vim.diagnostic.severity.INFO] = "I",
    },
  },
  virtual_text = {
    spacing = 2,
    source = "if_many",
  },
  float = {
    border = "rounded",
    source = "if_many",
  },
})

local blink = require("blink.cmp")
vim.lsp.config("*", {
  capabilities = blink.get_lsp_capabilities(),
})

vim.lsp.config("lua_ls", {
  settings = {
    Lua = {
      completion = {
        callSnippet = "Replace",
      },
      diagnostics = {
        globals = { "vim" },
      },
      workspace = {
        checkThirdParty = false,
      },
    },
  },
})

vim.lsp.config("marksman", {
  cmd_env = { DOTNET_SYSTEM_GLOBALIZATION_INVARIANT = "1" },
})

vim.lsp.config("tinymist", {
  settings = {
    exportPdf    = "never",
    formatterMode = "typstyle",
  },
})

local executable_by_server = {
  astro = { "astro-language-server", "astro-ls" },
  clangd = { "clangd" },
  cssls = { "vscode-css-language-server", "css-languageserver" },
  gopls = { "gopls" },
  html = { "vscode-html-language-server", "html-languageserver" },
  jsonls = { "vscode-json-language-server", "json-languageserver" },
  lua_ls = { "lua-language-server" },
  marksman = { "marksman" },
  pyright = { "pyright-langserver", "pyright" },
  sqlls = { "sql-language-server", "sqlls" },
  tinymist = { "tinymist" },
  ts_ls = { "typescript-language-server" },
  zls = { "zls" },
}

local servers = {
  "astro",
  "clangd",
  "cssls",
  "gopls",
  "html",
  "jsonls",
  "lua_ls",
  "marksman",
  "pyright",
  "sqlls",
  "tinymist",
  "ts_ls",
  "zls",
}

require("mason").setup()
require("mason-lspconfig").setup({
  ensure_installed = servers,
  automatic_enable = false,
})

local function has_executable(commands)
  for _, command in ipairs(commands) do
    if vim.fn.executable(command) == 1 then
      return true
    end
  end

  return false
end

for _, server in ipairs(servers) do
  local commands = executable_by_server[server] or {}
  if has_executable(commands) then
    vim.lsp.enable(server)
  end
end
