-- ============================================================================
-- Built-in statusline (no plugins).
--
-- Layout:
--   [ N ] file/relative ●     [diagnostics] [lsp] [ft] [42:7  20%]
--
-- Mode pills swap colour with the editor mode (orange = normal, green =
-- insert, purple = visual, yellow = command, red = replace, cyan = terminal),
-- matching the Adwaita Lualine theme used by the VM Neovim config so the
-- two profiles look consistent at a glance.
-- ============================================================================

local M = {}

-- Color setup. Colors are derived from the Adwaita palette in
-- lua/config/theme/util.lua so the statusline always matches the colorscheme.
local function setup_highlights()
  local ok, util = pcall(require, "config.theme.util")
  if not ok then return end
  local c = util.gen_colors()
  local hl = util.highlight

  -- Mode pills (one highlight per mode, painted into the leading "▎ N " block).
  hl("StlModeNormal",   { fg = c.bg,   bg = c.orange_3, bold = true })
  hl("StlModeInsert",   { fg = c.bg,   bg = c.green_3,  bold = true })
  hl("StlModeVisual",   { fg = c.bg,   bg = c.purple_2, bold = true })
  hl("StlModeReplace",  { fg = c.bg,   bg = c.red_2,    bold = true })
  hl("StlModeCommand",  { fg = c.bg,   bg = c.s_yellow, bold = true })
  hl("StlModeTerminal", { fg = c.bg,   bg = c.orange_3, bold = true })
  hl("StlModeOther",    { fg = c.bg,   bg = c.dark_1,   bold = true })

  -- Section accents.
  hl("StlBranch",     { fg = c.orange_1, bg = c.bg_popup })
  hl("StlFile",       { fg = c.light_3,  bg = c.bg_alt })
  hl("StlFileMod",    { fg = c.orange_3, bg = c.bg_alt, bold = true })
  hl("StlFileRO",     { fg = c.red_2,    bg = c.bg_alt, bold = true })
  hl("StlLsp",        { fg = c.dark_1,   bg = c.bg_alt })
  hl("StlFt",         { fg = c.s_blue,   bg = c.bg_alt })
  hl("StlPos",        { fg = c.bg,       bg = c.orange_3, bold = true })
  hl("StlMid",        { fg = c.light_3,  bg = c.bg_alt })

  -- Native StatusLine groups (used by inactive windows / fallback).
  hl("StatusLine",   { fg = c.light_3, bg = c.bg_alt })
  hl("StatusLineNC", { fg = c.dark_1,  bg = c.bg })
end

-- ----------------------------------------------------------------------------
-- Mode → (label, highlight group)
-- ----------------------------------------------------------------------------
local mode_table = {
  n      = { "N", "StlModeNormal" },
  no     = { "O", "StlModeNormal" },
  nov    = { "O", "StlModeNormal" },
  noV    = { "O", "StlModeNormal" },
  niI    = { "N", "StlModeNormal" },
  niR    = { "N", "StlModeNormal" },
  niV    = { "N", "StlModeNormal" },
  i      = { "I", "StlModeInsert" },
  ic     = { "I", "StlModeInsert" },
  ix     = { "I", "StlModeInsert" },
  R      = { "R", "StlModeReplace" },
  Rc     = { "R", "StlModeReplace" },
  Rx     = { "R", "StlModeReplace" },
  Rv     = { "R", "StlModeReplace" },
  v      = { "V", "StlModeVisual" },
  V      = { "V", "StlModeVisual" },
  ["\22"] = { "B", "StlModeVisual" }, -- <C-V>
  s      = { "S", "StlModeVisual" },
  S      = { "S", "StlModeVisual" },
  ["\19"] = { "B", "StlModeVisual" }, -- <C-S>
  c      = { "C", "StlModeCommand" },
  cv     = { "C", "StlModeCommand" },
  ce     = { "C", "StlModeCommand" },
  r      = { "P", "StlModeOther" },
  rm     = { "M", "StlModeOther" },
  ["r?"] = { "?", "StlModeOther" },
  ["!"]  = { "!", "StlModeOther" },
  t      = { "T", "StlModeTerminal" },
  nt     = { "T", "StlModeTerminal" },
}

local function mode_chunk()
  local m = vim.api.nvim_get_mode().mode
  local entry = mode_table[m] or { "?", "StlModeOther" }
  return string.format("%%#%s# %s %%*", entry[2], entry[1])
end

-- ----------------------------------------------------------------------------
-- Git branch (no plugins; cheap shell-out cached per-buffer).
-- ----------------------------------------------------------------------------
local function buffer_dir()
  local name = vim.api.nvim_buf_get_name(0)
  if name == "" then return vim.uv.cwd() end
  return vim.fn.fnamemodify(name, ":p:h")
end

local function git_branch()
  local cached = vim.b.stl_git_branch
  if cached ~= nil then return cached end

  local dir = buffer_dir()
  if not dir or dir == "" then
    vim.b.stl_git_branch = ""
    return ""
  end
  local head = vim.fs.find(".git", { upward = true, path = dir })[1]
  if not head then
    vim.b.stl_git_branch = ""
    return ""
  end
  local head_file = head .. "/HEAD"
  local fd = io.open(head_file, "r")
  if not fd then
    vim.b.stl_git_branch = ""
    return ""
  end
  local line = fd:read("*l") or ""
  fd:close()
  local branch = line:match("ref: refs/heads/(.+)") or line:sub(1, 7)
  vim.b.stl_git_branch = branch
  return branch
end

local function branch_chunk()
  local b = git_branch()
  if b == "" then return "" end
  return string.format(" %%#StlBranch# %s %%*", b)
end

-- Bust the cache when the buffer or git HEAD changes.
local cache_grp = vim.api.nvim_create_augroup("UserStatuslineGitCache", { clear = true })
vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "FocusGained", "ShellCmdPost" }, {
  group = cache_grp,
  callback = function() vim.b.stl_git_branch = nil end,
})

-- ----------------------------------------------------------------------------
-- File path + modified / readonly markers.
-- ----------------------------------------------------------------------------
local function file_chunk()
  local hl = "StlFile"
  if vim.bo.modified then hl = "StlFileMod"
  elseif vim.bo.readonly or not vim.bo.modifiable then hl = "StlFileRO"
  end

  local fname = vim.fn.expand("%:.")
  if fname == "" then fname = "[No Name]" end

  local marks = ""
  if vim.bo.modified then marks = marks .. " ●" end
  if vim.bo.readonly then marks = marks .. "  " end

  return string.format("%%#%s# %s%s %%*", hl, fname, marks)
end

-- ----------------------------------------------------------------------------
-- Diagnostics summary (E/W/I/H counts).
-- ----------------------------------------------------------------------------
local function diagnostics_chunk()
  local out = {}
  local sev = vim.diagnostic.severity
  local labels = {
    { sev.ERROR, " ", "DiagnosticError" },
    { sev.WARN,  " ", "DiagnosticWarn"  },
    { sev.INFO,  " ", "DiagnosticInfo"  },
    { sev.HINT,  " ", "DiagnosticHint"  },
  }
  for _, def in ipairs(labels) do
    local n = #vim.diagnostic.get(0, { severity = def[1] })
    if n > 0 then
      table.insert(out, string.format("%%#%s#%s%d%%*", def[3], def[2], n))
    end
  end
  if #out == 0 then return "" end
  return " " .. table.concat(out, " ") .. " "
end

-- ----------------------------------------------------------------------------
-- Active LSP clients.
-- ----------------------------------------------------------------------------
local function lsp_chunk()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then return "" end
  local names = {}
  for _, c in ipairs(clients) do table.insert(names, c.name) end
  return string.format(" %%#StlLsp# %s %%*", table.concat(names, ","))
end

-- ----------------------------------------------------------------------------
-- Filetype.
-- ----------------------------------------------------------------------------
local function ft_chunk()
  local ft = vim.bo.filetype
  if ft == "" then return "" end
  return string.format(" %%#StlFt# %s %%*", ft)
end

-- ----------------------------------------------------------------------------
-- Position (line:col + percent).
-- ----------------------------------------------------------------------------
local function pos_chunk()
  return "%#StlPos# %l:%c  %p%% %*"
end

-- ----------------------------------------------------------------------------
-- Render.
-- ----------------------------------------------------------------------------
function _G._user_statusline()
  return table.concat({
    mode_chunk(),
    branch_chunk(),
    " ",
    file_chunk(),
    diagnostics_chunk(),
    "%#StlMid#%=",
    lsp_chunk(),
    ft_chunk(),
    " ",
    pos_chunk(),
  })
end

-- ----------------------------------------------------------------------------
-- Apply. Re-sets after a colorscheme change so our highlights win.
-- ----------------------------------------------------------------------------
function M.apply()
  setup_highlights()
  vim.o.statusline = "%{%v:lua._user_statusline()%}"
end

vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("UserStatuslineRehl", { clear = true }),
  callback = function() setup_highlights() end,
})

M.apply()

return M
