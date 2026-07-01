local ft = require("config.ft")

ft.indent(2)

local o = vim.opt_local
o.colorcolumn = "120"
o.conceallevel = 0

if vim.fn.executable("prettier") == 1 then
  vim.opt_local.formatprg = "prettier --stdin-filepath " .. vim.fn.shellescape(vim.fn.expand("%:p"))
elseif vim.fn.executable("jq") == 1 then
  vim.opt_local.formatprg = "jq ."
end

ft.format_on_save({ lsp = false })

ft.suffixes({ ".json", ".jsonc" })
