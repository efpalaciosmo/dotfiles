vim.cmd("runtime! ftplugin/json.lua")

vim.opt_local.commentstring = "// %s"
if vim.fn.executable("prettier") == 0 then
  vim.opt_local.formatprg = ""
end
