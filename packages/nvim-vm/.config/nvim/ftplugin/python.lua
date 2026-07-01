local ft = require("config.ft")

ft.indent(4)

local o = vim.opt_local
o.colorcolumn = "88"
o.textwidth = 88
o.commentstring = "# %s"
o.formatoptions:append("croqlj")

-- Prefer ruff for `gq` formatting; fall back to black if available.
if vim.fn.executable("ruff") == 1 then
  local file = vim.fn.shellescape(vim.fn.expand("%:p"))
  vim.opt_local.formatprg = "ruff check --select I --fix --stdin-filename "
    .. file
    .. " - 2>/dev/null | "
    .. "ruff format --stdin-filename "
    .. file
    .. " - 2>/dev/null"
elseif vim.fn.executable("black") == 1 then
  vim.opt_local.formatprg = "black --quiet --stdin-filename "
    .. vim.fn.shellescape(vim.fn.expand("%:p")) .. " -"
end

ft.format_on_save({ lsp = false })

ft.suffixes({ ".py", ".pyi" })

-- `K` should always show basedpyright's hover, even if ruff attaches first.
-- (LspAttach already maps K -> hover; this just re-asserts buffer-local.)
vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = 0, desc = "LSP hover" })
