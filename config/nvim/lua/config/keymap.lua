vim.g.mapleader = " "
vim.keymap.set("n", "<leader>pv",vim.cmd.Ex)

--bufferline
vim.cmd[[
nnoremap <silent><S-n> :BufferLineCycleNext<CR>
nnoremap <silent><S-b> :BufferLineCyclePrev<CR>
]]

-- tree
vim.cmd[[
nnoremap <C-n> :NvimTreeToggle<CR>
nnoremap <C-b> :NvimTreeFocus<CR>
nnoremap <leader>n :NvimTreeFindFile<CR>
]]

map = vim.api.nvim_set_keymap
local opts = {noremap = true, silent = true}

-- remove buffer
--map('n', '<leader>bd', ':bd<CR>', opts)
-- Disable rows keys
map('n', '<Up>', '<Nop>', opts)
map('n', '<Down>', '<Nop>', opts)
map('n', '<Right>', '<Nop>', opts)
map('n', '<Left>', '<Nop>', opts)

map('v', '<Up>', '<Nop>', opts)
map('v', '<Down>', '<Nop>', opts)
map('v', '<Right>', '<Nop>', opts)
map('v', '<Left>', '<Nop>', opts)


map('i', '<Up>', '<Nop>', opts)
map('i', '<Down>', '<Nop>', opts)
map('i', '<Right>', '<Nop>', opts)
map('i', '<Left>', '<Nop>', opts)

vim.keymap.set("n", "[c", function()
  require("treesitter-context").go_to_context(vim.v.count1)
end, { silent = true })
