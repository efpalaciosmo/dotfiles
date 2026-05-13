local ft = require("config.ft")

ft.indent(2)

local o = vim.opt_local
o.colorcolumn = "120"
o.commentstring = "-- %s"

ft.formatprg("stylua", "stylua --search-parent-directories --stdin-filepath "
  .. vim.fn.shellescape(vim.fn.expand("%:p")) .. " -")

ft.suffixes({ ".lua" })
