-- Plugin-free Neovim 0.12 config.
-- Entry point: keep this file thin. Modules live under lua/config/.

if vim.fn.has("nvim-0.12") == 0 then
  vim.notify("This config requires Neovim 0.12+", vim.log.levels.ERROR)
end

vim.loader.enable()

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Register parsers installed alongside this config or under the user-local tree.
do
  local candidates = {
    vim.fn.stdpath("config") .. "/parser",
    vim.fn.expand("~/.local/lib/tree-sitter"),
  }
  for _, dir in ipairs(candidates) do
    if vim.fn.isdirectory(dir) == 1 then
      local handle = vim.uv.fs_scandir(dir)
      while handle do
        local name, t = vim.uv.fs_scandir_next(handle)
        if not name then break end
        if t == "file" then
          local lang = name:match("^(.+)%.so$")
          if lang then
            lang = lang:gsub("^libtree%-sitter%-", "")
            local stripped = lang:gsub("^tree%-sitter%-", "")
            local short = stripped:gsub("%-", "_")
            pcall(vim.treesitter.language.add, short, { path = dir .. "/" .. name })
          end
        end
      end
    end
  end
end

-- Make vim.treesitter.start() tolerant of missing or broken parsers so file
-- opens never fail. Highlighting silently degrades to syntax.lua.
do
  local orig_start = vim.treesitter.start
  vim.treesitter.start = function(bufnr, lang)
    local ok, err = pcall(orig_start, bufnr, lang)
    local msg = tostring(err)
    local parser_error = msg:match("Parser could not be created")
      or msg:match("Failed to load parser")
      or msg:match("no parser")
      or msg:match("treesitter.*parser")
      or msg:match("parser.*treesitter")
    if not ok and not parser_error then
      vim.notify(err, vim.log.levels.WARN)
    end
  end
end

require("config.options")
require("config.plugins")
require("config.diagnostics")
require("config.ui")
require("config.lsp")
require("config.keymaps")
require("config.autocmds")
