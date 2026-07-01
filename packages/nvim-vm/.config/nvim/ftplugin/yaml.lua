local ft = require("config.ft")

ft.indent(2)

local o = vim.opt_local
o.colorcolumn = "120"
o.commentstring = "# %s"
-- YAML is whitespace-sensitive; smartindent breaks alignment.
o.smartindent = false
o.indentkeys = "0#,-,!^F,o,O,e"
o.foldmethod = "indent"
o.foldlevel = 99

if vim.fn.executable("prettier") == 1 then
  vim.opt_local.formatprg = "prettier --stdin-filepath " .. vim.fn.shellescape(vim.fn.expand("%:p"))
elseif vim.fn.executable("yq") == 1 then
  vim.opt_local.formatprg = "yq -P -"
end

ft.format_on_save({ lsp = false })

ft.suffixes({ ".yml", ".yaml" })
