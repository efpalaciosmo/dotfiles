local ft = require("config.ft")

ft.indent(4)

local o = vim.opt_local
o.colorcolumn = "100"
o.commentstring = "// %s"

ft.formatprg("rustfmt", "rustfmt")
ft.format_on_save({ lsp = { "rust_analyzer" } })

ft.suffixes({ ".rs" })
