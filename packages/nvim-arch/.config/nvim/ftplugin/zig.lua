local ft = require("config.ft")

ft.indent(4)

local o = vim.opt_local
o.colorcolumn = "100"
o.commentstring = "// %s"

if vim.fn.executable("zig") == 1 then
  vim.opt_local.formatprg = "zig fmt --stdin"
end

ft.suffixes({ ".zig", ".zon" })

-- Format-on-save via zig fmt (zls also formats, but this works without LSP).
vim.api.nvim_create_autocmd("BufWritePre", {
  buffer = 0,
  callback = function()
    if vim.fn.executable("zig") == 0 then return end
    local view = vim.fn.winsaveview()
    vim.cmd("silent! %!zig fmt --stdin")
    if vim.v.shell_error ~= 0 then
      vim.cmd("silent! undo")
    end
    vim.fn.winrestview(view)
  end,
  desc = "zig fmt on save",
})
