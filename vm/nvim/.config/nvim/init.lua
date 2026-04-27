-- Plugin-free Neovim 0.12 config.
-- Entry point: keep this file thin. Modules live under lua/config/.

if vim.fn.has("nvim-0.12") == 0 then
  vim.notify("This config requires Neovim 0.12+", vim.log.levels.ERROR)
end

vim.loader.enable()

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ============================================================================
-- Tree-sitter parser bootstrap.
--
-- Some distros (Fedora / openSUSE / WSL2 derivatives) install parsers under
-- /usr/lib64/tree-sitter/ with the canonical `libtree-sitter-<lang>.so`
-- naming, but wire up a BROKEN symlink at $VIMRUNTIME/parser (it points to
-- `/usr/lib64/tree_sitter` with an underscore that doesn't exist).
-- Result: vim.api.nvim_get_runtime_file('parser/*.so', true) returns nothing,
-- so vim.treesitter.start() silently fails for every language.
--
-- Register every parser we find on disk by hand so the rest of the config
-- (markdown rendering, treesitter folds, treesitter highlights) just works.
-- ============================================================================
do
  local candidates = {
    "/usr/lib64/tree-sitter",
    "/usr/lib/tree-sitter",
    "/usr/lib/x86_64-linux-gnu/tree-sitter",
    "/usr/local/lib/tree-sitter",
  }
  for _, dir in ipairs(candidates) do
    if vim.fn.isdirectory(dir) == 1 then
      local handle = vim.uv.fs_scandir(dir)
      while handle do
        local name, t = vim.uv.fs_scandir_next(handle)
        if not name then break end
        if t == "file" then
          local lang = name:match("^libtree%-sitter%-(.+)%.so$")
          if lang then
            -- Some packagers double-prefix (e.g. libtree-sitter-tree-sitter-markdown.so).
            -- Strip the redundant `tree-sitter-` and convert hyphens to
            -- underscores so the parser name matches the exported symbol
            -- (`tree_sitter_<lang>`), which Neovim resolves automatically.
            local stripped = lang:gsub("^tree%-sitter%-", "")
            local short = stripped:gsub("%-", "_")
            pcall(vim.treesitter.language.add, short, { path = dir .. "/" .. name })
          end
        end
      end
    end
  end
end

-- Make vim.treesitter.start() tolerant of *still*-missing parsers so that
-- built-in ftplugins (e.g. ftplugin/lua.lua) which call it unconditionally
-- don't crash file opens. Highlighting silently degrades to syntax.lua.
do
  local orig_start = vim.treesitter.start
  vim.treesitter.start = function(bufnr, lang)
    local ok, err = pcall(orig_start, bufnr, lang)
    if not ok and not tostring(err):match("Parser could not be created") then
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
