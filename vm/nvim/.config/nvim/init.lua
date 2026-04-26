vim.g.mapleader = " "
vim.g.maplocalleader = " "

if vim.fn.has("nvim-0.11") == 0 then
	local version = vim.version()
	vim.api.nvim_echo({
		{ "This config requires Neovim 0.11+.\n", "WarningMsg" },
		{ string.format("Current version: %d.%d.%d", version.major, version.minor, version.patch), "None" },
	}, true, {})
	return
end

require("config.option")
require("config.plugins")
require("config.theme").load()
require("config.keymap")
require("config.autocmds")
require("config.lsp")
