local ft = require("config.ft")

ft.indent(4)

local o = vim.opt_local
o.colorcolumn = "100"
o.commentstring = "-- %s"

if vim.fn.executable("sqlfluff") == 1 then
  vim.opt_local.formatprg = "sqlfluff format --dialect ansi -"
end

ft.format_on_save({ lsp = false })

ft.suffixes({ ".sql" })
