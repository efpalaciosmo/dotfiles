-- :colorscheme adwaita
-- GNOME Adwaita Dark (lighter variant). Light background not implemented:
-- this config runs with vim.o.background = 'dark'.

if vim.fn.exists("syntax_on") == 1 then
  vim.cmd("syntax reset")
end

vim.o.termguicolors = true
vim.g.colors_name = "adwaita"

require("config.theme.dark").set()
