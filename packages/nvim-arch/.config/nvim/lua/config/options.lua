local opt = vim.opt

-- Line numbers & cursor
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.scrolloff = 10
opt.sidescrolloff = 10
opt.wrap = false

-- Indentation (2 spaces)
opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.smartindent = true
opt.autoindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true

-- UI
opt.signcolumn = "yes"
opt.colorcolumn = "100"
opt.showmatch = true
opt.cmdheight = 1
opt.showmode = false
opt.pumheight = 12
opt.pumblend = 10
opt.winblend = 0
opt.conceallevel = 0
opt.concealcursor = ""
opt.synmaxcol = 300
opt.fillchars = { eob = " ", diff = "╱" }
opt.termguicolors = true
opt.background = "dark"
opt.laststatus = 3

-- 0.12: default border for floating windows (LSP hover, signature help, diagnostic floats, ...).
opt.winborder = "rounded"

-- 0.12: clamp completion popup width.
opt.pummaxwidth = 60

-- Completion (fully built-in: omnifunc + vim.lsp.completion).
-- Leave the 0.12 `autocomplete` off and rely on:
--   * vim.lsp.completion.enable(... autotrigger = true) per LspAttach
--   * <C-Space> manual trigger
--   * <C-n>/<C-p> for buffer/dict word completion
-- This keeps the popup from appearing twice when both sources race.
opt.autocomplete = false
opt.completeopt = "menuone,noselect,popup,fuzzy,nearest"
opt.complete = ".,w,b,u,t"

-- 0.12: enable wildmenu-style completion in /, ?, :g, :v, :vimgrep, ...
opt.wildchar = vim.fn.char2nr("\t")
opt.wildmenu = true
opt.wildmode = "longest:full,full"
opt.wildoptions = "fuzzy,pum,tagfile"
opt.wildignore:append({
  "*/.git/*",
  "*/node_modules/*",
  "*/.venv/*",
  "*/__pycache__/*",
  "*/dist/*",
  "*/build/*",
  "*.o",
  "*.pyc",
})

-- Files / persistence
local undodir = vim.fn.stdpath("state") .. "/undo"
if vim.fn.isdirectory(undodir) == 0 then
  vim.fn.mkdir(undodir, "p")
end
opt.backup = false
opt.writebackup = false
opt.swapfile = false
opt.undofile = true
opt.undodir = undodir

-- Timing
opt.updatetime = 250
opt.timeoutlen = 500
opt.ttimeoutlen = 50

-- Behavior
opt.autoread = true
opt.autowrite = false
opt.hidden = true
opt.errorbells = false
opt.confirm = true
opt.backspace = "indent,eol,start"
opt.iskeyword:append("-")
opt.path:append("**")
opt.selection = "inclusive"
opt.mouse = "a"
opt.clipboard:append("unnamedplus")
opt.encoding = "utf-8"

-- 0.12: load project-local config from parent dirs too. Use :trust to allow new files.
opt.exrc = true

-- 0.12: keep shada slim; the defaults already exclude /tmp and /private now.
opt.shada = "!,'1000,<50,s10,h"

-- Cursor styling
opt.guicursor = table.concat({
  "n-v-c:block",
  "i-ci-ve:block",
  "r-cr:hor20",
  "o:hor50",
  "a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor",
  "sm:block-blinkwait175-blinkoff150-blinkon175",
}, ",")

-- Splits
opt.splitbelow = true
opt.splitright = true

-- Diff (0.12 already includes indent-heuristic + inline:char by default; add linematch).
opt.diffopt:append("linematch:60")

-- Performance
opt.redrawtime = 10000
opt.maxmempattern = 20000

-- Listchars
opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Folding via the built-in treesitter foldexpr; falls back gracefully when no parser exists.
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldtext = ""
opt.foldlevel = 99
opt.foldenable = true

-- Use ripgrep for :grep when available (rg is on the Arch package list as a
-- dependency of neovim's tree-sitter pipeline; if missing, fall back to grep).
if vim.fn.executable("rg") == 1 then
  opt.grepprg = "rg --vimgrep --smart-case --hidden --glob !.git"
  opt.grepformat = "%f:%l:%c:%m"
end

-- ============================================================================
-- Built-in netrw as the file explorer (no plugins).
-- ============================================================================
vim.g.netrw_banner = 0
vim.g.netrw_liststyle = 3
vim.g.netrw_winsize = 25
vim.g.netrw_altv = 1
vim.g.netrw_browse_split = 0
vim.g.netrw_keepdir = 0
vim.g.netrw_localcopydircmd = "cp -r"
vim.g.netrw_list_hide = [[\(^\|\s\s\)\zs\.\S\+]]

-- ============================================================================
-- Disable some legacy providers we don't use.
-- ============================================================================
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_python3_provider = 0
