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

map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase width" })

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
-- File explorer (built-in netrw — no plugins).
-- ============================================================================
map("n", "-", "<cmd>Explore<cr>", { desc = "Open parent directory in netrw" })
map("n", "<leader>e", "<cmd>Lexplore<cr>", { desc = "Toggle netrw side bar" })
map("n", "<leader>E", "<cmd>Explore<cr>", { desc = "Open netrw in current window" })
map("n", "<leader>eh", "<cmd>Hexplore<cr>", { desc = "netrw in horizontal split" })
map("n", "<leader>ev", "<cmd>Vexplore<cr>", { desc = "netrw in vertical split" })

-- ============================================================================
-- Fuzzy navigation (no plugins — use :find / :grep / wildmenu fuzzy).
-- 'path+=**' is set in options.lua so :find <pattern> walks the whole tree.
-- 'wildoptions=fuzzy,pum,tagfile' makes <Tab> behave like a fuzzy picker.
-- ============================================================================

-- Pretty file picker built on top of :find. Wildmenu fuzzy completion makes
-- this feel similar to fzf.vim for the common case (no preview).
map("n", "<leader>ff", ":find ", { desc = "Find file (path+=**, fuzzy wildmenu)" })
map("n", "<leader>fF", function()
  local cur = vim.fn.expand("%:p:h")
  vim.api.nvim_feedkeys(":find " .. cur .. "/", "n", false)
end, { desc = "Find file (current dir)" })

-- Buffer picker via :ls + :buffer.
map("n", "<leader>fb", function()
  vim.cmd("ls")
  local n = tonumber(vim.fn.input("buffer: "))
  if n then vim.cmd("buffer " .. n) end
end, { desc = "Switch buffer" })

-- Recent files via shada oldfiles + vim.ui.select (built-in).
map("n", "<leader>fr", function()
  local items = {}
  for _, f in ipairs(vim.v.oldfiles) do
    if vim.uv.fs_stat(f) then table.insert(items, f) end
  end
  vim.ui.select(items, { prompt = "Recent files" }, function(choice)
    if choice then vim.cmd.edit(choice) end
  end)
end, { desc = "Recent files" })

-- Live grep → quickfix. Uses 'grepprg' (rg if available, see options.lua).
map("n", "<leader>fg", function()
  local q = vim.fn.input("grep: ")
  if q == "" then return end
  vim.cmd("silent! grep! " .. vim.fn.shellescape(q))
  vim.cmd("copen")
end, { desc = "Live grep (project, → quickfix)" })

map("n", "<leader>f*", function()
  vim.cmd("silent! grep! " .. vim.fn.shellescape(vim.fn.expand("<cword>")))
  vim.cmd("copen")
end, { desc = "Grep word under cursor" })

map("n", "<leader>f/", function()
  local q = vim.fn.input("buffer grep: ")
  if q == "" then return end
  vim.cmd("silent! lgrep! " .. vim.fn.shellescape(q) .. " %")
  vim.cmd("lopen")
end, { desc = "Grep current buffer" })

-- Help / commands / keymaps via vim.ui.select (built-in popup, no plugin).
map("n", "<leader>fh", function()
  local helptags = {}
  for _, line in ipairs(vim.fn.globpath(vim.o.runtimepath, "doc/tags", true, true, true)) do
    for _, ln in ipairs(vim.fn.readfile(line)) do
      local tag = ln:match("^(%S+)\t")
      if tag then table.insert(helptags, tag) end
    end
  end
  vim.ui.select(helptags, { prompt = "Help tag" }, function(choice)
    if choice then vim.cmd.help(choice) end
  end)
end, { desc = "Help tags" })

map("n", "<leader>fc", function()
  local cmds = vim.api.nvim_get_commands({})
  local names = vim.tbl_keys(cmds)
  table.sort(names)
  vim.ui.select(names, { prompt = "Commands" }, function(choice)
    if choice then
      vim.api.nvim_feedkeys(":" .. choice .. " ", "n", false)
    end
  end)
end, { desc = "Commands" })

map("n", "<leader>fk", function()
  local maps = vim.api.nvim_get_keymap("n")
  local items = {}
  for _, m in ipairs(maps) do
    table.insert(items, string.format("%s -> %s   %s", m.lhs, m.rhs or "<lua>", m.desc or ""))
  end
  vim.ui.select(items, { prompt = "Keymaps (n)" }, function() end)
end, { desc = "Keymaps (normal mode)" })

map("n", "<leader>fd", function()
  vim.diagnostic.setqflist()
  vim.cmd("copen")
end, { desc = "Diagnostics (workspace) → quickfix" })

map("n", "<leader>fs", vim.lsp.buf.document_symbol, { desc = "Symbols (document)" })
map("n", "<leader>fS", vim.lsp.buf.workspace_symbol, { desc = "Symbols (workspace)" })

-- Resume last quickfix.
map("n", "<leader>fp", "<cmd>copen<cr>", { desc = "Reopen quickfix" })

-- Git-flavored pickers via :G commands + simple shell-outs.
map("n", "<leader>gf", function()
  if vim.fn.executable("git") == 0 then return end
  local files = vim.fn.systemlist("git ls-files")
  vim.ui.select(files, { prompt = "git files" }, function(choice)
    if choice then vim.cmd.edit(choice) end
  end)
end, { desc = "Git files" })

map("n", "<leader>gs", function()
  vim.cmd("vert botright Git")
end, { desc = "Git status (built-in :Git, requires `git` on PATH)" })

map("n", "<leader>gb", function()
  if vim.fn.executable("git") == 0 then return end
  local branches = vim.fn.systemlist("git branch --all --format='%(refname:short)'")
  vim.ui.select(branches, { prompt = "git checkout" }, function(choice)
    if choice then vim.fn.system("git checkout " .. choice) end
  end)
end, { desc = "Git branches" })

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
-- Built-in plugins shipped with 0.12 (kept intact, since they're built-in).
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
-- Insert-mode helpers — Tab/S-Tab/CR are owned by config/lsp.lua so the
-- native LSP completion popup can drive them.
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
