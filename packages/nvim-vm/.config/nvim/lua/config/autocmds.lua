local augroup = vim.api.nvim_create_augroup("UserConfig", { clear = true })

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup,
  callback = function()
    vim.hl.on_yank()
  end,
})

-- Reload buffer on external change
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = augroup,
  command = "checktime",
})

-- Restore last cursor position
vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup,
  desc = "Restore last cursor position",
  callback = function(ev)
    if vim.o.diff then
      return
    end
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    local lcount = vim.api.nvim_buf_line_count(ev.buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Trim trailing whitespace on save (skip non-file buffers)
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup,
  callback = function(ev)
    if vim.bo[ev.buf].buftype ~= "" then
      return
    end
    local view = vim.fn.winsaveview()
    vim.cmd([[keeppatterns %s/\s\+$//e]])
    vim.fn.winrestview(view)
  end,
})

-- Markdown / text: prose-friendly defaults
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "markdown", "text", "gitcommit" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.spell = true
  end,
})

-- Close utility filetypes with q
vim.api.nvim_create_autocmd("FileType", {
  group = augroup,
  pattern = { "help", "qf", "man", "checkhealth", "lspinfo", "netrw" },
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = ev.buf, silent = true })
  end,
})

-- Auto-create parent directories on save (also handled by ':write ++p',
-- but kept for plain :w / external writes).
vim.api.nvim_create_autocmd("BufWritePre", {
  group = augroup,
  callback = function(ev)
    if ev.match:match("^%w+://") then
      return
    end
    local dir = vim.fn.fnamemodify(vim.uv.fs_realpath(ev.match) or ev.match, ":p:h")
    if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, "p")
    end
  end,
})

-- Terminal: no numbers / sign column
vim.api.nvim_create_autocmd("TermOpen", {
  group = augroup,
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
  end,
})

-- Auto-close terminal buffer when shell exits cleanly.
-- 0.12 also surfaces the exit code in the statusline via 'busy'/term events.
vim.api.nvim_create_autocmd("TermClose", {
  group = augroup,
  callback = function(ev)
    if vim.v.event.status == 0 then
      pcall(vim.api.nvim_buf_delete, ev.buf, {})
    end
  end,
})

-- ============================================================================
-- Treesitter: enable highlighting wherever a parser is available.
-- nvim-treesitter (see lua/config/plugins.lua) handles indent + ensure_installed
-- for the configured languages; this autocmd is a safety net so any other
-- filetype with a parser registered via the init.lua bootstrap (system
-- /usr/lib64/tree-sitter parsers) still gets highlights.
--
-- IMPORTANT: do NOT set indentexpr here. Neovim core does not expose
-- vim.treesitter.indent(); setting it caused E5108 every time indent was
-- computed (e.g. opening / editing a Python file).
-- ============================================================================
vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("UserTreesitter", { clear = true }),
  callback = function(ev)
    local ft = vim.bo[ev.buf].filetype
    if ft == "" then
      return
    end
    local lang = vim.treesitter.language.get_lang(ft) or ft
    pcall(vim.treesitter.start, ev.buf, lang)
  end,
})

-- ============================================================================
-- A friendly first-time message if the user is on an old Neovim.
-- ============================================================================
if vim.fn.has("nvim-0.12") == 0 then
  vim.api.nvim_create_autocmd("VimEnter", {
    once = true,
    callback = function()
      vim.notify("Neovim 0.12+ recommended for this config", vim.log.levels.WARN)
    end,
  })
end
