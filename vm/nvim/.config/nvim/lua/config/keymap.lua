local map = vim.keymap.set
local opts = { noremap = true, silent = true }

local function set(mode, lhs, rhs, desc)
  map(mode, lhs, rhs, { noremap = true, silent = true, desc = desc })
end

local function toggle_oil()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "oil" then
      require("oil").close()
      return
    end
  end
  require("oil").open_float()
end

local function open_buffer_dir()
  local name = vim.api.nvim_buf_get_name(0)
  local dir = name ~= "" and vim.fn.fnamemodify(name, ":p:h") or vim.uv.cwd()
  require("oil").open_float(dir)
end

-- Disable arrow keys
map({ "n", "v", "i" }, "<Up>", "<Nop>", opts)
map({ "n", "v", "i" }, "<Down>", "<Nop>", opts)
map({ "n", "v", "i" }, "<Left>", "<Nop>", opts)
map({ "n", "v", "i" }, "<Right>", "<Nop>", opts)

-- File explorer
set("n", "<C-n>",      toggle_oil,      "Toggle file explorer")
set("n", "<C-b>",      open_buffer_dir, "Focus explorer on current file")
set("n", "<leader>n",  open_buffer_dir, "Find current file in explorer")
set("n", "<leader>pv", toggle_oil,      "Toggle file explorer")
set("n", "-",          toggle_oil,      "Toggle file explorer")

-- Markdown preview (only meaningful in markdown buffers)
set("n", "<leader>mp", "<cmd>MarkdownPreviewToggle<CR>", "Toggle Markdown browser preview")

-- Search
set("n", "<leader>c", "<cmd>nohlsearch<CR>", "Clear search highlights")
set("n", "n", "nzzzv", "Next search result (centered)")
set("n", "N", "Nzzzv", "Previous search result (centered)")

-- Scrolling
set("n", "<C-d>", "<C-d>zz", "Scroll down half a page (centered)")
set("n", "<C-u>", "<C-u>zz", "Scroll up half a page (centered)")

-- Editing
set({ "n", "v" }, "<leader>d", '"_d', "Delete without yanking")
set("n", "<A-j>", "<cmd>m .+1<CR>==", "Move line down")
set("n", "<A-k>", "<cmd>m .-2<CR>==", "Move line up")
set("v", "<A-j>", ":m '>+1<CR>gv=gv", "Move selection down")
set("v", "<A-k>", ":m '<-2<CR>gv=gv", "Move selection up")
set("v", "<", "<gv", "Indent left and reselect")
set("v", ">", ">gv", "Indent right and reselect")

-- Buffer navigation
set("n", "<Tab>",   "<cmd>BufferLineCycleNext<CR>", "Next buffer")
set("n", "<S-Tab>", "<cmd>BufferLineCyclePrev<CR>", "Previous buffer")
set("n", "<leader>bd", "<cmd>bdelete<CR>", "Delete buffer")

-- Window navigation
set("n", "<C-h>", "<C-w>h", "Move to left window")
set("n", "<C-j>", "<C-w>j", "Move to bottom window")
set("n", "<C-k>", "<C-w>k", "Move to top window")
set("n", "<C-l>", "<C-w>l", "Move to right window")

-- Window splits and resize
set("n", "<leader>sv", "<cmd>vsplit<CR>", "Split window vertically")
set("n", "<leader>sh", "<cmd>split<CR>", "Split window horizontally")
set("n", "<C-Up>", "<cmd>resize +2<CR>", "Increase window height")
set("n", "<C-Down>", "<cmd>resize -2<CR>", "Decrease window height")
set("n", "<C-Left>", "<cmd>vertical resize -2<CR>", "Decrease window width")
set("n", "<C-Right>", "<cmd>vertical resize +2<CR>", "Increase window width")

-- LSP keymaps (buffer-local, applied when an LSP server attaches)
vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local buf = args.buf
    local lmap = function(lhs, rhs, desc)
      vim.keymap.set("n", lhs, rhs, { buffer = buf, silent = true, desc = desc })
    end

    lmap("K", vim.lsp.buf.hover, "LSP hover")
    lmap("gd", vim.lsp.buf.definition, "Go to definition")
    lmap("gD", vim.lsp.buf.declaration, "Go to declaration")
    lmap("gr", vim.lsp.buf.references, "List references")
    lmap("gi", vim.lsp.buf.implementation, "Go to implementation")
    lmap("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
    lmap("<leader>ca", vim.lsp.buf.code_action, "Code action")
    lmap("<leader>f", function()
      require("conform").format({ async = true, lsp_fallback = true })
    end, "Format buffer")
    lmap("[d", vim.diagnostic.goto_prev, "Previous diagnostic")
    lmap("]d", vim.diagnostic.goto_next, "Next diagnostic")
    lmap("<leader>e", vim.diagnostic.open_float, "Line diagnostics")
  end,
})
