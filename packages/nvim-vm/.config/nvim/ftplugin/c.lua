local ft = require("config.ft")

-- Match clang-format's LLVM fallback when a project has no .clang-format.
ft.indent(2)

local o = vim.opt_local
o.colorcolumn = "80"
o.commentstring = "// %s"
o.cinoptions = "g0,N-s,(0,m1,+2s"

if vim.fn.executable("clang-format") == 1 then
  vim.opt_local.formatprg = "clang-format --assume-filename="
    .. vim.fn.shellescape(vim.fn.expand("%:p"))
end

ft.format_on_save({ lsp = false })

ft.suffixes({ ".h", ".c", ".hpp", ".cpp" })

-- Quick header/source toggle (clangd switchSourceHeader).
vim.keymap.set("n", "<leader>lh", function()
  local clients = vim.lsp.get_clients({ bufnr = 0, name = "clangd" })
  if #clients == 0 then
    vim.notify("clangd is not attached", vim.log.levels.WARN)
    return
  end
  vim.lsp.buf_request(0, "textDocument/switchSourceHeader",
    vim.lsp.util.make_text_document_params(0),
    function(err, result)
      if err or not result then return end
      vim.cmd.edit(vim.uri_to_fname(result))
    end)
end, { buffer = 0, desc = "Switch source ↔ header (clangd)" })
