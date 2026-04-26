local group = vim.api.nvim_create_augroup("minimal_nvim", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.api.nvim_create_autocmd("VimEnter", {
  group = group,
  callback = function()
    vim.o.insertmode = false
    vim.cmd("stopinsert")
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  callback = function(args)
    pcall(vim.treesitter.start, args.buf)
  end,
})
