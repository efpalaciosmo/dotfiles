-- Tiny helpers shared by every ftplugin/<lang>.lua.
-- Keeps each ftplugin file focused on what makes that language unique.

local M = {}

--- Set expandtab + shiftwidth/tabstop/softtabstop in one call.
--- @param sw integer  number of spaces per indent step
--- @param expandtab? boolean  default true; pass false for tab-indented filetypes
function M.indent(sw, expandtab)
  local o = vim.opt_local
  o.expandtab = expandtab ~= false
  o.shiftwidth = sw
  o.tabstop = sw
  o.softtabstop = sw
end

--- Configure 'formatprg' (used by `gq`) only if the binary is on $PATH.
--- @param bin string         executable name to probe
--- @param command string     full command, including args
function M.formatprg(bin, command)
  if vim.fn.executable(bin) == 1 then
    vim.opt_local.formatprg = command
  end
end

--- Append filetype-specific suffixes to 'suffixesadd' for `gf` / find.
--- @param suffixes string[]
function M.suffixes(suffixes)
  for _, s in ipairs(suffixes) do
    vim.opt_local.suffixesadd:prepend(s)
  end
end

return M
