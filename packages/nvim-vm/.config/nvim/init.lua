-- Plugin-free Neovim 0.12 config.
-- Entry point: keep this file thin. Modules live under lua/config/.

if vim.fn.has("nvim-0.12") == 0 then
  vim.notify("This config requires Neovim 0.12+", vim.log.levels.ERROR)
end

vim.loader.enable()

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Make Neovim see Homebrew/Linuxbrew tools even when launched from an
-- environment that did not source the shell profile.
do
  local function prepend_path(dir)
    if not dir or dir == "" or not vim.uv.fs_stat(dir) then
      return
    end

    local path = vim.env.PATH or ""
    if (":" .. path .. ":"):find(":" .. dir .. ":", 1, true) then
      return
    end

    vim.env.PATH = dir .. (path ~= "" and ":" .. path or "")
  end

  local tool_paths = {
    vim.fn.expand("~/.local/bin"),
    "/home/linuxbrew/.linuxbrew/bin",
    "/home/linuxbrew/.linuxbrew/sbin",
    "/opt/homebrew/bin",
    "/opt/homebrew/sbin",
    "/usr/local/bin",
    "/usr/local/sbin",
  }

  for i = #tool_paths, 1, -1 do
    prepend_path(tool_paths[i])
  end
end

-- ============================================================================
-- Tree-sitter parser bootstrap.
--
-- Prefer nvim-treesitter-managed parsers, but register parser libraries from
-- common system and Homebrew locations when they are already present.
-- ============================================================================
do
  local candidates = {
    vim.fn.expand("~/.local/lib/tree-sitter"),
    "/opt/homebrew/lib/tree-sitter",
    "/usr/local/lib/tree-sitter",
    "/home/linuxbrew/.linuxbrew/lib/tree-sitter",
    "/usr/lib/tree-sitter",
    "/usr/lib64/tree-sitter",
    "/usr/lib/x86_64-linux-gnu/tree-sitter",
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
