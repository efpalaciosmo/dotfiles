local ft = require("config.ft")

ft.indent(2)

local o = vim.opt_local
o.colorcolumn = "100"
o.commentstring = "// %s"

if vim.fn.executable("prettier") == 1 then
  vim.opt_local.formatprg = "prettier --stdin-filepath "
    .. vim.fn.shellescape(vim.fn.expand("%:p"))
end

ft.suffixes({ ".js", ".jsx", ".ts", ".tsx", ".json", ".mjs", ".cjs" })
