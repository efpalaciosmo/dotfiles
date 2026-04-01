-- =============================================================================
-- ===  BASIC UI AND NAVIGATION                                              ===
-- =============================================================================

-- Enable line numbers and highlight the current line for better orientation.
-- Relative numbers show the distance to other lines, which is useful for
-- jump commands.
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true

-- Control text wrapping and scrolling behavior.
-- `wrap = false` prevents lines from wrapping, while `scrolloff` and
-- `sidescrolloff` keep the cursor centered when scrolling.
vim.opt.wrap = false
vim.opt.scrolloff = 10
vim.opt.sidescrolloff = 8


-- =============================================================================
-- ===  INDENTATION SETTINGS                                                 ===
-- =============================================================================

-- Configure how tabs and indentation work. Using `expandtab` is a common
-- practice that ensures code consistency by converting tabs to spaces.
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 4
vim.opt.expandtab = true

-- Enable smart indentation to automatically align code as you type.
vim.opt.smartindent = true
vim.opt.autoindent = true


-- =============================================================================
-- ===  SEARCH BEHAVIOR                                                      ===
-- =============================================================================

-- Set up intelligent search. By default, searches are case-insensitive, but
-- `smartcase` makes them case-sensitive if you include any uppercase letters.
-- `incsearch` shows matches as you type.
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = false
vim.opt.incsearch = true


-- =============================================================================
-- ===  VISUAL AND THEME SETTINGS                                            ===
-- =============================================================================

-- Enable true color support and configure the appearance of the UI.
-- `termguicolors` is essential for modern themes.
vim.opt.termguicolors = true

-- Display a column for signs (e.g., from linters or Git plugins) and a
-- color column to mark the 100-character line limit.
vim.opt.signcolumn = "yes"
vim.opt.colorcolumn = "100"

-- Configure the behavior of UI elements like the command line and popups.
-- `completeopt` and `pumheight` control the completion menu.
vim.opt.showmatch = true
vim.opt.matchtime = 2
vim.opt.cmdheight = 1
vim.opt.completeopt = "menuone,noinsert,noselect"
vim.opt.showmode = false
vim.opt.pumheight = 10
vim.opt.pumblend = 10
vim.opt.winblend = 0

-- Other visual settings. `lazyredraw` improves performance during macros,
-- and `synmaxcol` prevents syntax highlighting on excessively long lines.
vim.opt.conceallevel = 0
vim.opt.concealcursor = ""
vim.opt.lazyredraw = true
vim.opt.synmaxcol = 300


-- =============================================================================
-- ===  FILE HANDLING AND UNDO                                               ===
-- =============================================================================

-- Disable legacy backup, swap, and write files to keep the directory clean.
-- `undofile` enables persistent undo history, and `undodir` specifies where
-- to store it.
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false
vim.opt.undofile = true
vim.opt.undodir = vim.fn.expand("~/.vim/undodir")

-- Configure file updates and timeouts.
-- `updatetime` affects when `CursorHold` events trigger (e.g., for LSP),
-- and `autoread` automatically reloads files if they change on disk.
vim.opt.updatetime = 300
vim.opt.timeoutlen = 500
vim.opt.ttimeoutlen = 0
vim.opt.autoread = true
vim.opt.autowrite = false


-- =============================================================================
-- ===  GENERAL BEHAVIOR                                                     ===
-- =============================================================================

-- Configure general editor behavior.
-- `hidden` allows buffers to stay open without being visible, and
-- `errorbells` disables the annoying terminal bell.
vim.opt.hidden = true
vim.opt.errorbells = false

-- `backspace` improves backspace functionality, and `iskeyword` treats a dash
-- as part of a word, which is useful for programming.
vim.opt.backspace = "indent,eol,start"
vim.opt.autochdir = false
vim.opt.iskeyword:append("-")
vim.opt.path:append("**")

-- Enable full mouse support and use the system clipboard for copy/paste.
vim.opt.selection = "exclusive"
vim.opt.mouse = "a"
vim.opt.clipboard:append("unnamedplus")

-- Other general settings.
vim.opt.modifiable = true
vim.opt.encoding = "UTF-8"


-- =============================================================================
-- ===  CURSOR AND FOLDING (from previous prompt)                            ===
-- =============================================================================

-- Configure the cursor shape and blink behavior for different modes.
vim.opt.guicursor = "n-v-c:block,i-ci-ve:block,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor,sm:block-blinkwait175-blinkoff150-blinkon175"

-- Set up code folding using Treesitter, which is more accurate than simple
-- indentation-based folding. `foldlevel = 99` keeps all folds open by default.
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevel = 99


-- =============================================================================
-- ===  WINDOW SPLIT BEHAVIOR (from previous prompt)                         ===
-- =============================================================================

-- Control how horizontal and vertical splits are created.
-- New horizontal windows appear below the current one, and new vertical
-- windows appear to the right.
vim.opt.splitbelow = true
vim.opt.splitright = true
