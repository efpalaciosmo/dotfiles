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
nnoremap <leader>r :NvimTreeRefresh<CR>
nnoremap <leader>n :NvimTreeFindFile<CR>
]]

map = vim.api.nvim_set_keymap
local opts = {noremap = true, silent = true}

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
