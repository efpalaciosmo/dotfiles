" Aeon host Vim config. Keep this compatible with vim-small:
" no plugins, no Lua, no Neovim APIs.

scriptencoding utf-8

let mapleader = " "
let maplocalleader = " "

set nocompatible
set encoding=utf-8
set fileencoding=utf-8

" Files and persistence.
set autoread
set confirm
set hidden
set nobackup
set nowritebackup
set noswapfile
if has('persistent_undo')
  let s:undodir = expand('~/.vim/undo')
  if !isdirectory(s:undodir)
    silent! call mkdir(s:undodir, 'p', 0700)
  endif
  if isdirectory(s:undodir)
    let &undodir = s:undodir
    set undofile
  endif
endif

" Indentation.
set expandtab
set shiftwidth=2
set softtabstop=2
set tabstop=2
set autoindent
set smartindent

" Search.
set ignorecase
set smartcase
set incsearch
set hlsearch
nnoremap <silent> <leader>c :nohlsearch<CR>

" Display.
syntax enable
filetype plugin indent on
set background=dark
silent! colorscheme default
set ruler
set showcmd
set showmatch
set wildmenu
set wildmode=longest:full,full
set scrolloff=8
set sidescrolloff=8
set nowrap
if exists('+cursorline')
  set cursorline
endif
if exists('+number')
  set number
endif
if exists('+relativenumber')
  set relativenumber
endif
if exists('+colorcolumn')
  set colorcolumn=100
endif
if exists('+signcolumn')
  set signcolumn=yes
endif
if exists('+listchars')
  set list
  set listchars=tab:>\ ,trail:.,nbsp:+
endif

" Completion and path discovery.
set complete=.,w,b,u,t
set path+=**
set wildignore+=*/.git/*,*/node_modules/*,*/.venv/*,*/__pycache__/*,*/dist/*,*/build/*,*.o,*.pyc
if executable('rg')
  set grepprg=rg\ --vimgrep\ --smart-case\ --hidden\ --glob\ !.git
  set grepformat=%f:%l:%c:%m
endif

" Netrw basics.
let g:netrw_banner = 0
let g:netrw_liststyle = 3
let g:netrw_winsize = 25
let g:netrw_altv = 1
let g:netrw_browse_split = 0
let g:netrw_keepdir = 0
let g:netrw_localcopydircmd = 'cp -r'
nnoremap <silent> - :Explore<CR>
nnoremap <silent> <leader>e :Explore<CR>

" Movement and editing ergonomics.
nnoremap <expr> j v:count == 0 ? 'gj' : 'j'
nnoremap <expr> k v:count == 0 ? 'gk' : 'k'
nnoremap n nzzzv
nnoremap N Nzzzv
nnoremap <C-d> <C-d>zz
nnoremap <C-u> <C-u>zz
xnoremap <leader>p "_dP
nnoremap <leader>x "_d
xnoremap <leader>x "_d
nnoremap <S-l> :bnext<CR>
nnoremap <S-h> :bprevious<CR>
nnoremap <leader>bn :bnext<CR>
nnoremap <leader>bp :bprevious<CR>
nnoremap <leader>bd :bdelete<CR>
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l
nnoremap <leader>sv :vsplit<CR>
nnoremap <leader>sh :split<CR>
nnoremap <A-j> :m .+1<CR>==
nnoremap <A-k> :m .-2<CR>==
xnoremap <A-j> :m '>+1<CR>gv=gv
xnoremap <A-k> :m '<-2<CR>gv=gv
xnoremap < <gv
xnoremap > >gv
nnoremap J mzJ`z

" File commands.
nnoremap <leader>w :write<CR>
nnoremap <leader>W :wall<CR>
nnoremap <leader>Q :quit<CR>
nnoremap <leader>pa :let @"=expand('%:p')<CR>

" Toggles.
nnoremap <leader>uw :set wrap!<CR>
nnoremap <leader>us :set spell!<CR>
nnoremap <leader>ul :set list!<CR>
