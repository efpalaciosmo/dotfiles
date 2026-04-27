-- UI: colorscheme + per-window highlight tweaks.
-- Statusline lives in lua/config/plugins.lua (lualine).

-- ============================================================================
-- Colorscheme
-- ============================================================================
pcall(vim.cmd.colorscheme, "adwaita")

-- ============================================================================
-- fillchars: make sure horizontal/vertical split separators have visible
-- characters so the orange WinSeparator highlight actually paints a line.
-- (eob blanks the ~ glyph, diff is the slash; the rest are the 0.12 defaults.)
-- ============================================================================
vim.opt.fillchars:append({
  vert = "│",
  vertleft = "┤",
  vertright = "├",
  verthoriz = "┼",
  horiz = "─",
  horizup = "┴",
  horizdown = "┬",
})

-- ============================================================================
-- Floating terminals (<leader>tf) → orange rounded border.
-- Split terminals automatically get the orange border because WinSeparator is
-- orange globally; only the floating case needs an extra winhighlight nudge
-- since FloatBorder defaults to a subtle grey for popups (blink, fzf-lua, ...).
-- ============================================================================
vim.api.nvim_create_autocmd("TermOpen", {
  group = vim.api.nvim_create_augroup("UserTermBorder", { clear = true }),
  callback = function(ev)
    local win = vim.api.nvim_get_current_win()
    local cfg = vim.api.nvim_win_get_config(win)
    if cfg and cfg.relative ~= "" then
      vim.opt_local.winhighlight = "FloatBorder:TermFloatBorder"
    end
    -- Sane defaults for any terminal buffer (kept here too in case
    -- autocmds.lua isn't loaded in some context).
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
    vim.opt_local.colorcolumn = ""
  end,
})
