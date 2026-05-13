-- Plugin-FREE Neovim 0.12 config for the Arch Linux host.
-- Uses ONLY built-in Neovim features: native LSP, vim.treesitter, netrw,
-- the built-in statusline, vim.diagnostic, omnifunc / vim.lsp.completion,
-- :find / :grep, ftplugin/, etc.
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
-- Arch installs tree-sitter parsers under /usr/lib/tree-sitter/ (when you
-- install language packages such as `tree-sitter-grammars-bash`, etc.) but
-- different packagers use slightly different naming and Neovim's runtime
-- only auto-discovers `parser/<lang>.so` under the runtimepath.
--
-- Walk every common path and register what we find by hand so the rest of
-- the config (treesitter folds, treesitter highlights) just works without
-- relying on nvim-treesitter.
-- ============================================================================
do
  local candidates = {
    "/usr/lib/tree-sitter",
    "/usr/lib64/tree-sitter",
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
                    or name:match("^(.+)%.so$")
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

-- Make vim.treesitter.start() tolerant of missing parsers so that built-in
-- ftplugins (e.g. ftplugin/lua.lua) which call it unconditionally don't
-- crash file opens. Highlighting silently degrades to syntax.lua.
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
require("config.diagnostics")
require("config.ui")
require("config.statusline")
require("config.lsp")
require("config.keymaps")
require("config.autocmds")
