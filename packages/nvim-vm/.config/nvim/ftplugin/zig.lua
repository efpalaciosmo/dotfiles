local ft = require("config.ft")

ft.indent(4)

local o = vim.opt_local
o.colorcolumn = "100"
o.commentstring = "// %s"

if vim.fn.executable("zig") == 1 then
  vim.opt_local.formatprg = "zig fmt --stdin"
end

ft.suffixes({ ".zig", ".zon" })
ft.format_on_save({ lsp = false })
