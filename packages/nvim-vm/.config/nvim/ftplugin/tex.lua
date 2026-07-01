local ft = require("config.ft")

ft.indent(2)

local bufnr = vim.api.nvim_get_current_buf()
local o = vim.opt_local
o.textwidth = 88
o.wrap = true
o.linebreak = true
o.spell = true
o.conceallevel = 2
o.concealcursor = "nc"
o.suffixesadd:prepend(".tex")

local template_path = vim.fn.stdpath("config") .. "/templates/latex.tex"

local function is_empty_buffer()
  return vim.api.nvim_buf_line_count(bufnr) == 1 and vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] == ""
end

local function read_template()
  local lines = vim.fn.readfile(template_path)
  if vim.v.shell_error ~= 0 or #lines == 0 then
    vim.notify("LaTeX template not found: " .. template_path, vim.log.levels.WARN)
    return nil
  end
  return lines
end

local function insert_template(force)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" or not name:match("%.tex$") then
    return
  end
  if not force and not is_empty_buffer() then
    return
  end

  local lines = read_template()
  if not lines then
    return
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.api.nvim_win_set_cursor(0, { #lines - 2, 0 })
end

insert_template(false)

vim.api.nvim_buf_create_user_command(bufnr, "LatexTemplate", function()
  insert_template(true)
end, { desc = "Insert the default LaTeX mathematics template" })

vim.schedule(function()
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name ~= "" and vim.fn.executable("latexmk") == 1 then
    vim.cmd("silent! VimtexCompile")
  end
end)
