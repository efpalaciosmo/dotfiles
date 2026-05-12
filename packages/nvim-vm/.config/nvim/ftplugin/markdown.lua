-- ============================================================================
-- ftplugin/markdown.lua
--
-- Visual rendering (icons, heading pills, code-block borders, checkboxes, ...)
-- is handled by render-markdown.nvim — see lua/config/plugins.lua.
-- This file only carries:
--   - prose-friendly buffer options
--   - editor helpers that act on the BUFFER (toggle bullets / numbers /
--     checkboxes / task state / heading level)
-- ============================================================================

local set = vim.opt_local

set.textwidth = 80
set.spell = true
set.linebreak = true
set.wrap = true
set.formatoptions:append("t")
set.smartindent = false
set.colorcolumn = ""
set.conceallevel = 2
set.concealcursor = "nc"

-- ----------------------------------------------------------------------------
-- Helpers
-- ----------------------------------------------------------------------------

local function selection_lines()
  local s, e = vim.fn.line("'<"), vim.fn.line("'>")
  return s, e, vim.fn.getline(s, e)
end

local function set_lines(start, lines)
  vim.fn.setline(start, lines)
end

-- ----------------------------------------------------------------------------
-- Toggle numbered list
-- ----------------------------------------------------------------------------
local function toggle_numbers_visual()
  local s, _, lines = selection_lines()
  local has = false
  for _, l in ipairs(lines) do
    if l:match("^%s*%d+%.%s") then has = true; break end
  end
  for i, l in ipairs(lines) do
    if has then
      lines[i] = l:gsub("^%s*%d+%.%s*", "")
    elseif l ~= "" then
      lines[i] = i .. ". " .. l
    end
  end
  set_lines(s, lines)
end

local function toggle_numbers_line()
  local n = vim.fn.line(".")
  local l = vim.fn.getline(n)
  if l:match("^%s*%d+%.%s") then
    l = l:gsub("^%s*%d+%.%s*", "")
  else
    l = "1. " .. l
  end
  vim.fn.setline(n, l)
end

-- ----------------------------------------------------------------------------
-- Toggle bullets
-- ----------------------------------------------------------------------------
local function toggle_bullets_visual()
  local s, _, lines = selection_lines()
  local has = false
  for _, l in ipairs(lines) do
    if l:match("^%s*[%-%*%+]%s") then has = true; break end
  end
  for i, l in ipairs(lines) do
    if has then
      lines[i] = l:gsub("^(%s*)[%-%*%+]%s*", "%1")
    elseif l ~= "" and not l:match("^%s*%d+%.%s") then
      lines[i] = "- " .. l
    end
  end
  set_lines(s, lines)
end

local function toggle_bullets_line()
  local n = vim.fn.line(".")
  local l = vim.fn.getline(n)
  if l:match("^%s*[%-%*%+]%s") then
    l = l:gsub("^(%s*)[%-%*%+]%s*", "%1")
  elseif not l:match("^%s*%d+%.%s") then
    l = "- " .. l
  end
  vim.fn.setline(n, l)
end

-- ----------------------------------------------------------------------------
-- Toggle checkboxes
-- ----------------------------------------------------------------------------
local function toggle_checkboxes_visual()
  local s, _, lines = selection_lines()
  local has = false
  for _, l in ipairs(lines) do
    if l:match("^%s*%-%s*%[.%]%s") then has = true; break end
  end
  for i, l in ipairs(lines) do
    if has then
      lines[i] = l:gsub("^(%s*%-)%s*%[.%]%s*", "%1 ")
    elseif l:match("^%s*%-%s") then
      lines[i] = l:gsub("^(%s*%-)%s*", "%1 [ ] ")
    elseif l ~= "" then
      lines[i] = "- [ ] " .. l
    end
  end
  set_lines(s, lines)
end

local function toggle_checkboxes_line()
  local n = vim.fn.line(".")
  local l = vim.fn.getline(n)
  if l:match("^%s*%-%s*%[.%]%s") then
    l = l:gsub("^(%s*%-)%s*%[.%]%s*", "%1 ")
  elseif l:match("^%s*%-%s") then
    l = l:gsub("^(%s*%-)%s*", "%1 [ ] ")
  elseif l ~= "" then
    l = "- [ ] " .. l
  end
  vim.fn.setline(n, l)
end

-- ----------------------------------------------------------------------------
-- Toggle task state (checked / unchecked)
-- ----------------------------------------------------------------------------
local function toggle_task_state_visual()
  local s, _, lines = selection_lines()
  local changed = 0
  for i, l in ipairs(lines) do
    if l:match("^%s*%-%s*%[ %]") then
      lines[i] = l:gsub("(%[) (])", "%1x%2"); changed = changed + 1
    elseif l:match("^%s*%-%s*%[[xX]%]") then
      lines[i] = l:gsub("(%[)[xX](])", "%1 %2"); changed = changed + 1
    end
  end
  if changed > 0 then set_lines(s, lines) end
end

local function toggle_task_state_line()
  local n = vim.fn.line(".")
  local l = vim.fn.getline(n)
  if l:match("^%s*%-%s*%[ %]") then
    l = l:gsub("(%[) (])", "%1x%2")
  elseif l:match("^%s*%-%s*%[[xX]%]") then
    l = l:gsub("(%[)[xX](])", "%1 %2")
  end
  vim.fn.setline(n, l)
end

-- ----------------------------------------------------------------------------
-- Toggle heading level (1..6)
-- ----------------------------------------------------------------------------
local function toggle_heading(level)
  local line = vim.api.nvim_get_current_line()
  local cur = vim.api.nvim_win_get_cursor(0)
  local content = line:gsub("^#+%s*", "")
  local current_level = line:match("^(#+)")
  if current_level and #current_level == level then
    vim.api.nvim_set_current_line(content)
    vim.api.nvim_win_set_cursor(0, { cur[1], math.max(0, cur[2] - level - 1) })
  else
    vim.api.nvim_set_current_line(string.rep("#", level) .. " " .. content)
    vim.api.nvim_win_set_cursor(0, { cur[1], cur[2] + level + 1 })
  end
end

-- ----------------------------------------------------------------------------
-- Keymaps (buffer-local)
-- ----------------------------------------------------------------------------
local function map(mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, { buffer = 0, silent = true, desc = desc })
end

map("v", "tn", function() toggle_numbers_visual() end,    "Toggle numbered list")
map("v", "tb", function() toggle_bullets_visual() end,    "Toggle bullets")
map("v", "tc", function() toggle_checkboxes_visual() end, "Toggle checkboxes")
map("v", "tt", function() toggle_task_state_visual() end, "Toggle task done/undone")

map("n", "tn", toggle_numbers_line,    "Toggle numbered list")
map("n", "tb", toggle_bullets_line,    "Toggle bullet")
map("n", "tc", toggle_checkboxes_line, "Toggle checkbox")
map("n", "tt", toggle_task_state_line, "Toggle task done/undone")

for i = 1, 6 do
  map("n", "<leader>h" .. i, function() toggle_heading(i) end, "Toggle H" .. i)
end

-- Render-markdown control on the buffer.
map("n", "<leader>mr", "<cmd>RenderMarkdown toggle<cr>", "Toggle markdown rendering")
map("n", "<leader>me", "<cmd>RenderMarkdown enable<cr>",  "Enable markdown rendering")
map("n", "<leader>md", "<cmd>RenderMarkdown disable<cr>", "Disable markdown rendering")

-- Bulk task ops.
map("n", "<leader>tD", function()
  vim.cmd([[silent! keeppatterns g/- \[ \]/s/\[ \]/[x]/]])
end, "Mark all tasks done")
map("n", "<leader>tU", function()
  vim.cmd([[silent! keeppatterns g/- \[x\]/s/\[x\]/[ ]/]])
end, "Mark all tasks undone")
