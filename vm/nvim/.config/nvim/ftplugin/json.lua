local ft = require("config.ft")

ft.indent(2)

local o = vim.opt_local
o.colorcolumn = "120"
o.conceallevel = 0

if vim.fn.executable("jq") == 1 then
  vim.opt_local.formatprg = "jq ."
end

ft.suffixes({ ".json", ".jsonc" })
