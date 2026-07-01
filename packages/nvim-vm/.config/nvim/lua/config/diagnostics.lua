-- Native diagnostics configuration (Neovim 0.12).
-- Sign customization MUST go through vim.diagnostic.config(); :sign-define no longer works.

local sev = vim.diagnostic.severity

vim.diagnostic.config({
  severity_sort = true,
  update_in_insert = false,
  underline = true,
  virtual_text = {
    spacing = 2,
    prefix = "▎",
    severity = { min = sev.WARN },
  },
  virtual_lines = false,
  float = {
    border = "rounded",
    source = true,
    header = "",
    prefix = "",
  },
  signs = {
    text = {
      [sev.ERROR] = "",
      [sev.WARN] = "",
      [sev.INFO] = "",
      [sev.HINT] = "",
    },
    numhl = {
      [sev.ERROR] = "DiagnosticSignError",
      [sev.WARN] = "DiagnosticSignWarn",
      [sev.INFO] = "DiagnosticSignInfo",
      [sev.HINT] = "DiagnosticSignHint",
    },
  },
})

-- Toggle virtual_text vs virtual_lines on demand.
vim.api.nvim_create_user_command("DiagnosticLinesToggle", function()
  local cfg = vim.diagnostic.config() or {}
  local new_lines = not cfg.virtual_lines
  vim.diagnostic.config({
    virtual_text = not new_lines and {
      spacing = 2,
      prefix = "▎",
      severity = { min = sev.WARN },
    } or false,
    virtual_lines = new_lines,
  })
end, { desc = "Toggle diagnostic virtual_lines" })
