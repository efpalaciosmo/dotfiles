local ft = require("config.ft")

ft.indent(2)

local o = vim.opt_local
o.colorcolumn = "120"
o.commentstring = "<!-- %s -->"
o.matchpairs:append("<:>")

if vim.fn.executable("prettier") == 1 then
  vim.opt_local.formatprg = "prettier --stdin-filepath "
    .. vim.fn.shellescape(vim.fn.expand("%:p"))
end

ft.suffixes({ ".html", ".htm" })
