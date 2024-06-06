vim.lsp.handlers['textDocument/publishDiagnostics'] = vim.lsp.with(
vim.lsp.diagnostic.on_publish_diagnostics,
{
  underline = true,
  virtual_text = {
    spacing = 5,
    min = 'severity',
  },
  update_in_insert = true,
}
)

require'nvim-treesitter.configs'.setup {
  sync_install = true,
  auto_install = true,
  modules = {},
  ignore_install = {},
  ensure_installed = {
    "css",
    "html",
    "typescript",
    "javascript",
    "json",
    "lua",
    "python",
    "c_sharp",
    "bash",
    "sql",
  },
  highlight = {
    enable = true,              -- false will disable the whole extension
    additional_vim_regex_highlighting = false,
  },
  autotag = {
    enable = true,
  },
  rainbow = {
    enable = true, -- disable = { "jsx", "cpp" }, list of languages you want to disable the plugin for
    extended_mode = false, -- Also highlight non-bracket delimiters like html tags, boolean or table: lang -> boolean
    max_file_lines = nil, -- Do not enable for files with more than n lines, int
    -- colors = {}, -- table of hex strings
    -- termcolors = {} -- table of color name strings
  },
  autopairs = {
    enable = true
  }
}
