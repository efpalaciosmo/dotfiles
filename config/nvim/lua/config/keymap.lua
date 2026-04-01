-- =============================================================================
-- ===  GENERAL CONFIGURATIONS                                               ===
-- =============================================================================

-- Disable arrow key mappings to enforce the use of `h`, `j`, `k`, `l`, which
-- is a standard Vim practice for efficient movement.
-- `opts` is a reusable table for keymap options.
local opts = { noremap = true, silent = true }
local map = vim.keymap.set

-- Disable arrow keys in different modes
map('n', '<Up>', '<Nop>', opts)
map('n', '<Down>', '<Nop>', opts)
map('n', '<Left>', '<Nop>', opts)
map('n', '<Right>', '<Nop>', opts)
map('v', '<Up>', '<Nop>', opts)
map('v', '<Down>', '<Nop>', opts)
map('v', '<Left>', '<Nop>', opts)
map('v', '<Right>', '<Nop>', opts)
map('i', '<Up>', '<Nop>', opts)
map('i', '<Down>', '<Nop>', opts)
map('i', '<Left>', '<Nop>', opts)
map('i', '<Right>', '<Nop>', opts)


-- =============================================================================
-- ===  THEME AND UI SETTINGS                                                ===
-- =============================================================================

-- Make the background of the main window and non-active buffers transparent.
-- This allows Neovim to use the same background color as your terminal.
vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
vim.api.nvim_set_hl(0, "NormalNC", { bg = "none" })
vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })


-- =============================================================================
-- ===  KEY MAPPINGS                                                         ===
-- =============================================================================

-- Set the `<leader>` key to the spacebar. This key is a prefix for many
-- custom and plugin-related shortcuts.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Use a local function to simplify keymap creation. This function
-- automatically adds options and a description.
local function map_set(mode, lhs, rhs, desc)
    map(mode, lhs, rhs, { noremap = true, silent = true, desc = desc })
end

--- NORMAL MODE MAPPINGS ---
--- File Explorer Navigation
map_set("n", "<leader>pv", vim.cmd.Ex, "Open file explorer (builtin)")

--- Search and Highlights
map_set("n", "<leader>c", ":nohlsearch<CR>", "Clear search highlights")
map_set("n", "n", "nzzzv", "Next search result (centered)")
map_set("n", "N", "Nzzzv", "Previous search result (centered)")

--- Screen Scrolling
map_set("n", "<C-d>", "<C-d>zz", "Scroll down half a page (centered)")
map_set("n", "<C-u>", "<C-u>zz", "Scroll up half a page (centered)")

--- Delete without Yanking (copying)
map_set({ "n", "v" }, "<leader>d", '"_d', "Delete without yanking")

--- Buffer Navigation
map_set("n", "<leader>bn", ":bnext<CR>", "Next buffer")
map_set("n", "<leader>bp", ":bprevious<CR>", "Previous buffer")

--- Window Navigation
map_set("n", "<C-h>", "<C-w>h", "Move to left window")
map_set("n", "<C-j>", "<C-w>j", "Move to bottom window")
map_set("n", "<C-k>", "<C-w>k", "Move to top window")
map_set("n", "<C-l>", "<C-w>l", "Move to right window")

--- Splitting and Resizing Windows
map_set("n", "<leader>sv", ":vsplit<CR>", "Split window vertically")
map_set("n", "<leader>sh", ":split<CR>", "Split window horizontally")
map_set("n", "<C-Up>", ":resize +2<CR>", "Increase window height")
map_set("n", "<C-Down>", ":resize -2<CR>", "Decrease window height")
map_set("n", "<C-Left>", ":vertical resize -2<CR>", "Decrease window width")
map_set("n", "<C-Right>", ":vertical resize +2<CR>", "Increase window width")

--- Move Lines/Selections Up/Down
map_set("n", "<A-j>", ":m .+1<CR>==", "Move line down")
map_set("n", "<A-k>", ":m .-2<CR>==", "Move line up")
map_set("v", "<A-j>", ":m '>+1<CR>gv=gv", "Move selection down")
map_set("v", "<A-k>", ":m '<-2<CR>gv=gv", "Move selection up")

--- --- VISUAL MODE MAPPINGS ---
--- Better Indentation
map_set("v", "<", "<gv", "Indent left and reselect")
map_set("v", ">", ">gv", "Indent right and reselect")

--- --- Nvim tree ---
vim.cmd[[
nnoremap <C-n> :NvimTreeToggle<CR>
nnoremap <C-b> :NvimTreeFocus<CR>
nnoremap <leader>n :NvimTreeFindFile<CR>
]]
