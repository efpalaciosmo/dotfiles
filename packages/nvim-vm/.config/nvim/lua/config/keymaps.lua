local map = vim.keymap.set

-- ============================================================================
-- Motion / search ergonomics
-- ============================================================================
map("n", "j", function()
  return vim.v.count == 0 and "gj" or "j"
end, { expr = true, silent = true, desc = "Down (wrap-aware)" })
map("n", "k", function()
  return vim.v.count == 0 and "gk" or "k"
end, { expr = true, silent = true, desc = "Up (wrap-aware)" })

map("n", "<leader>c", "<cmd>nohlsearch<cr>", { desc = "Clear search highlights" })
map("n", "n", "nzzzv", { desc = "Next match (centered)" })
map("n", "N", "Nzzzv", { desc = "Prev match (centered)" })
map("n", "<C-d>", "<C-d>zz", { desc = "Half page down (centered)" })
map("n", "<C-u>", "<C-u>zz", { desc = "Half page up (centered)" })

-- ============================================================================
-- Yank / paste / delete without clobbering register
-- ============================================================================
map("x", "<leader>p", '"_dP', { desc = "Paste without yanking" })
map({ "n", "v" }, "<leader>x", '"_d', { desc = "Delete without yanking" })

-- ============================================================================
-- Buffers
-- ============================================================================
map("n", "<S-l>", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<S-h>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
map("n", "<leader>bn", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "<leader>bp", "<cmd>bprevious<cr>", { desc = "Prev buffer" })
map("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete buffer" })
map("n", "<leader>bo", function()
  local current = vim.api.nvim_get_current_buf()
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if b ~= current and vim.bo[b].buflisted then
      pcall(vim.api.nvim_buf_delete, b, {})
    end
  end
end, { desc = "Delete other buffers" })

-- ============================================================================
-- Windows / splits
-- ============================================================================
map("n", "<C-h>", "<C-w>h", { desc = "Window left" })
map("n", "<C-j>", "<C-w>j", { desc = "Window down" })
map("n", "<C-k>", "<C-w>k", { desc = "Window up" })
map("n", "<C-l>", "<C-w>l", { desc = "Window right" })

map("n", "<leader>sv", "<cmd>vsplit<cr>", { desc = "Split vertical" })
map("n", "<leader>sh", "<cmd>split<cr>", { desc = "Split horizontal" })

map("n", "<leader>rk", "<cmd>resize +2<cr>", { desc = "Increase height" })
map("n", "<leader>rj", "<cmd>resize -2<cr>", { desc = "Decrease height" })
map("n", "<leader>rh", "<cmd>vertical resize -2<cr>", { desc = "Decrease width" })
map("n", "<leader>rl", "<cmd>vertical resize +2<cr>", { desc = "Increase width" })

for _, key in ipairs({ "<Up>", "<Down>", "<Left>", "<Right>" }) do
  map({ "n", "i", "v", "c" }, key, "<Nop>", { desc = "Disable arrow navigation" })
end

-- ============================================================================
-- Move lines / blocks
-- ============================================================================
map("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move line down" })
map("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move line up" })
map("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move selection down" })
map("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move selection up" })

map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })

map("n", "J", "mzJ`z", { desc = "Join lines, keep cursor" })

-- ============================================================================
-- File ops
-- ============================================================================
map("n", "<leader>w", "<cmd>write ++p<cr>", { desc = "Save (++p auto-mkdir)" })
map("n", "<leader>W", "<cmd>wall ++p<cr>", { desc = "Save all (++p auto-mkdir)" })
map("n", "<leader>Q", "<cmd>quit<cr>", { desc = "Quit window" })

map("n", "<leader>pa", function()
  local path = vim.fn.expand("%:p")
  vim.fn.setreg("+", path)
  vim.notify("file: " .. path)
end, { desc = "Copy full file path" })

-- ============================================================================
-- File explorer (oil.nvim).
-- ============================================================================
map("n", "-", "<cmd>Oil<cr>", { desc = "Open parent directory in oil" })
map("n", "<leader>e", function()
  require("oil").toggle_float()
end, { desc = "Toggle oil (floating)" })
map("n", "<leader>E", "<cmd>Oil<cr>", { desc = "Open oil in current window" })
map("n", "<leader>eh", "<cmd>leftabove split | Oil<cr>", { desc = "Open oil in horizontal split" })
map("n", "<leader>ev", "<cmd>leftabove vsplit | Oil<cr>", { desc = "Open oil in vertical split" })

-- ============================================================================
-- Fuzzy navigation (fzf-lua).
-- 'grepprg' is still configured below so :grep / :Make-style flows still work.
-- ============================================================================

if vim.fn.executable("rg") == 1 then
  vim.o.grepprg = "rg --vimgrep --smart-case --hidden --glob !.git"
  vim.o.grepformat = "%f:%l:%c:%m"
end

map("n", "<leader>ff", function() require("fzf-lua").files() end, { desc = "Find files" })
map("n", "<leader>fF", function()
  require("fzf-lua").files({ cwd = vim.fn.expand("%:p:h") })
end, { desc = "Find files (current dir)" })
map("n", "<leader>fb", function() require("fzf-lua").buffers() end, { desc = "Switch buffer" })
map("n", "<leader>fh", function() require("fzf-lua").helptags() end, { desc = "Help tags" })
map("n", "<leader>fr", function() require("fzf-lua").oldfiles() end, { desc = "Recent files" })
map("n", "<leader>fg", function() require("fzf-lua").live_grep() end, { desc = "Live grep (project)" })
map("n", "<leader>fG", function() require("fzf-lua").live_grep_resume() end, { desc = "Live grep (resume)" })
map("n", "<leader>f*", function() require("fzf-lua").grep_cword() end, { desc = "Grep word under cursor" })
map("v", "<leader>f*", function() require("fzf-lua").grep_visual() end, { desc = "Grep visual selection" })
map("n", "<leader>fc", function() require("fzf-lua").commands() end, { desc = "Commands" })
map("n", "<leader>fk", function() require("fzf-lua").keymaps() end, { desc = "Keymaps" })
map("n", "<leader>f/", function() require("fzf-lua").lgrep_curbuf() end, { desc = "Grep current buffer" })
map("n", "<leader>fd", function() require("fzf-lua").diagnostics_workspace() end, { desc = "Diagnostics (workspace)" })
map("n", "<leader>fs", function() require("fzf-lua").lsp_document_symbols() end, { desc = "Symbols (document)" })
map("n", "<leader>fS", function() require("fzf-lua").lsp_live_workspace_symbols() end, { desc = "Symbols (workspace)" })
map("n", "<leader>fp", function() require("fzf-lua").resume() end, { desc = "Resume last picker" })

-- Git pickers
map("n", "<leader>gf", function() require("fzf-lua").git_files() end, { desc = "Git files" })
map("n", "<leader>gs", function() require("fzf-lua").git_status() end, { desc = "Git status" })
map("n", "<leader>gc", function() require("fzf-lua").git_commits() end, { desc = "Git commits (project)" })
map("n", "<leader>gC", function() require("fzf-lua").git_bcommits() end, { desc = "Git commits (buffer)" })
map("n", "<leader>gb", function() require("fzf-lua").git_branches() end, { desc = "Git branches" })

-- ============================================================================
-- Quickfix / loclist
-- ============================================================================
map("n", "<leader>qo", "<cmd>copen<cr>", { desc = "Quickfix open" })
map("n", "<leader>qc", "<cmd>cclose<cr>", { desc = "Quickfix close" })
map("n", "]q", "<cmd>cnext<cr>zz", { desc = "Next quickfix" })
map("n", "[q", "<cmd>cprev<cr>zz", { desc = "Prev quickfix" })
map("n", "]Q", "<cmd>clast<cr>zz", { desc = "Last quickfix" })
map("n", "[Q", "<cmd>cfirst<cr>zz", { desc = "First quickfix" })

-- ============================================================================
-- Built-in plugins shipped with 0.12
-- ============================================================================
map("n", "<leader>gu", function()
  vim.cmd("packadd nvim.undotree")
  vim.cmd("Undotree")
end, { desc = "Undotree (built-in)" })

map("n", "<leader>gd", function()
  vim.cmd("packadd nvim.difftool")
  vim.cmd("DiffTool")
end, { desc = "DiffTool (built-in)" })

-- ============================================================================
-- Terminal
-- ============================================================================
map("t", "<Esc><Esc>", [[<C-\><C-n>]], { desc = "Terminal: normal mode" })
map("n", "<leader>tt", function()
  vim.cmd("botright 12split | terminal")
  vim.cmd("startinsert")
end, { desc = "Open terminal split" })
map("n", "<leader>tv", function()
  vim.cmd("vertical rightbelow 80vsplit | terminal")
  vim.cmd("startinsert")
end, { desc = "Open terminal vsplit" })
map("n", "<leader>tf", function()
  local buf = vim.api.nvim_create_buf(false, true)
  local w = math.floor(vim.o.columns * 0.85)
  local h = math.floor(vim.o.lines * 0.8)
  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    style = "minimal",
    border = "rounded",
    width = w,
    height = h,
    row = math.floor((vim.o.lines - h) / 2),
    col = math.floor((vim.o.columns - w) / 2),
  })
  vim.cmd("terminal")
  vim.cmd("startinsert")
end, { desc = "Floating terminal" })

-- ============================================================================
-- LaTeX
-- ============================================================================
local function set_tex_keymaps(bufnr)
  map("n", "<localleader>lc", "<cmd>VimtexCompile<cr>", { buffer = bufnr, desc = "Start LaTeX autocompile" })
  map("n", "<localleader>ls", "<cmd>VimtexStop<cr>", { buffer = bufnr, desc = "Stop LaTeX autocompile" })
  map("n", "<localleader>lv", "<cmd>VimtexView<cr>", { buffer = bufnr, desc = "View LaTeX PDF" })
  map("n", "<localleader>le", "<cmd>VimtexErrors<cr>", { buffer = bufnr, desc = "Show LaTeX errors" })
  map("n", "<localleader>lt", "<cmd>LatexTemplate<cr>", { buffer = bufnr, desc = "Insert LaTeX template" })
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "tex",
  desc = "Set LaTeX keymaps",
  callback = function(args)
    set_tex_keymaps(args.buf)
  end,
})

if vim.bo.filetype == "tex" then
  set_tex_keymaps(vim.api.nvim_get_current_buf())
end

-- ============================================================================
-- Insert-mode helpers
-- blink.cmp owns <Tab>, <S-Tab>, <CR>, <C-Space>, <C-n>, <C-p>, <C-e>, <C-b>,
-- and <C-f> while the completion popup is active. See lua/config/plugins.lua.
-- ============================================================================

-- ============================================================================
-- Misc
-- ============================================================================
map("n", "<leader>uw", function()
  vim.opt.wrap = not vim.opt.wrap:get()
end, { desc = "Toggle wrap" })
map("n", "<leader>us", function()
  vim.opt.spell = not vim.opt.spell:get()
end, { desc = "Toggle spell" })
map("n", "<leader>ul", function()
  vim.opt.list = not vim.opt.list:get()
end, { desc = "Toggle listchars" })
