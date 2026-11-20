" Vim configuration for the desktop.
set nocompatible
filetype plugin indent on
syntax enable

" Editing
set number relativenumber
set scrolloff=10 sidescrolloff=10 nowrap
set expandtab shiftwidth=4 tabstop=4 softtabstop=4
set smartindent autoindent
set ignorecase smartcase incsearch hlsearch
set showmatch ruler showcmd
set hidden backspace=indent,eol,start
set mouse=a
set splitbelow splitright
set updatetime=300 timeoutlen=500 ttimeoutlen=10
set wildmenu wildmode=longest:full,full
set signcolumn=yes
set cursorline
set laststatus=2
set list listchars=tab:»\ ,trail:·,nbsp:␣
if has('clipboard')
  set clipboard=unnamedplus
endif

" Appearance: Adwaita Dark with the desktop's orange accent (.vim/colors).
set background=dark
if has('termguicolors')
  " Vim needs the escape codes spelled out.
  if &term =~# 'xterm\|ghostty'
    let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
    let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
  endif
  set termguicolors
endif
silent! colorscheme adwaita-orange

" Cursor shape: bar in insert mode, like Ghostty's default.
let &t_SI = "\<Esc>[6 q"
let &t_SR = "\<Esc>[4 q"
let &t_EI = "\<Esc>[2 q"

" Keys
let mapleader = ' '
nnoremap <silent> <Esc> :nohlsearch<CR>
nnoremap <leader>w :write<CR>
nnoremap <leader>q :quit<CR>
" Keep selections while indenting.
xnoremap < <gv
xnoremap > >gv
" Move between splits like the Niri focus keys.
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
