local opt = vim.opt
local undo_dir = vim.fn.stdpath("state") .. "/undo"

if vim.fn.isdirectory(undo_dir) == 0 then
  vim.fn.mkdir(undo_dir, "p")
end

vim.g.transparent_background = true

opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.wrap = false
opt.linebreak = true
opt.scrolloff = 10
opt.sidescrolloff = 8
opt.colorcolumn = "100"

opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.expandtab = true
opt.smartindent = true
opt.autoindent = true

opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = false
opt.incsearch = true
opt.grepprg = "rg --vimgrep --no-messages --smart-case"
opt.path:append("**")
opt.wildoptions:append("fuzzy")

opt.termguicolors = true
opt.signcolumn = "yes:1"
opt.showmode = false
opt.showmatch = true
opt.matchtime = 2
opt.completeopt = { "menu", "menuone", "noinsert", "noselect", "popup" }
opt.pumheight = 10
opt.conceallevel = 0
opt.concealcursor = ""
opt.smoothscroll = true
opt.winborder = "rounded"

opt.backup = false
opt.writebackup = false
opt.swapfile = false
opt.undofile = true
opt.undodir = undo_dir
opt.confirm = true
opt.autoread = true
opt.updatetime = 250
opt.timeoutlen = 400
opt.ttimeoutlen = 0

opt.errorbells = false
opt.backspace = "indent,eol,start"
opt.iskeyword:append("-")
opt.mouse = "a"
opt.clipboard:append("unnamedplus")

opt.guicursor =
  "n-v-c:block,i-ci-ve:block,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor,sm:block-blinkwait175-blinkoff150-blinkon175"
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel = 99
opt.splitbelow = true
opt.splitright = true
