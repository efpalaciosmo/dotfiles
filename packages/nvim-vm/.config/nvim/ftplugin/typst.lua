local ft = require("config.ft")

ft.indent(2)
ft.format_on_save({ lsp = "tinymist", formatprg = false })

local bufnr = vim.api.nvim_get_current_buf()
local o = vim.opt_local
o.textwidth = 88
o.wrap = true
o.linebreak = true
o.spell = true
o.conceallevel = 2
o.concealcursor = "nc"
o.commentstring = "// %s"
o.suffixesadd:prepend(".typ")

local template = {
  "#set document(title: \"Mathematics Notes\", author: \"Author\")",
  "#set page(paper: \"us-letter\", margin: (x: 1in, y: 1in), numbering: \"1\")",
  "#set text(font: \"Libertinus Serif\", size: 11pt, lang: \"en\")",
  "#set par(justify: true, leading: 0.65em)",
  "#set heading(numbering: \"1.1\")",
  "",
  "#let theorem(title, body) = block(",
  "  fill: luma(248),",
  "  inset: 10pt,",
  "  radius: 3pt,",
  "  stroke: 0.5pt + luma(180),",
  ")[",
  "  *Theorem: #title.* #body",
  "]",
  "",
  "#let definition(title, body) = block(",
  "  inset: 10pt,",
  "  radius: 3pt,",
  "  stroke: 0.5pt + luma(200),",
  ")[",
  "  *Definition: #title.* #body",
  "]",
  "",
  "#let proof(body) = block[",
  "  _Proof._ #body",
  "  #align(right)[$square$]",
  "]",
  "",
  "#align(center)[",
  [[  #text(20pt, weight: "bold")[Mathematics Notes] \]],
  "  #text(11pt)[Author]",
  "]",
  "",
  "#pagebreak()",
  "",
  "= Introduction",
  "",
  "#theorem(\"Sample theorem\")[",
  "  If $a, b in RR$, then $a + b = b + a$.",
  "]",
  "",
  "#proof[",
  "  This follows from commutativity of addition on $RR$.",
  "]",
  "",
  "== Notes",
  "",
}

local function is_empty_buffer()
  return vim.api.nvim_buf_line_count(bufnr) == 1 and vim.api.nvim_buf_get_lines(bufnr, 0, 1, false)[1] == ""
end

local function insert_template(force)
  local name = vim.api.nvim_buf_get_name(bufnr)
  if name == "" or not name:match("%.typ$") then
    return
  end
  if not force and not is_empty_buffer() then
    return
  end

  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, template)
  vim.api.nvim_win_set_cursor(0, { #template, 0 })
end

insert_template(false)

vim.api.nvim_buf_create_user_command(bufnr, "TypstTemplate", function()
  insert_template(true)
end, { desc = "Insert the default Typst mathematics template" })

local function typst_client()
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr, name = "tinymist" })) do
    return client
  end
end

local function should_skip(filepath)
  return filepath == ""
    or not filepath:match("%.typ$")
    or filepath:match("/typst/packages/")
    or filepath:match("/Library/Application Support/typst/packages/")
end

local function compile_pdf()
  local filepath = vim.api.nvim_buf_get_name(bufnr)
  if should_skip(filepath) then
    return
  end

  local client = typst_client()
  if client then
    client:exec_cmd({
      title = "Export Pdf",
      command = "tinymist.exportPdf",
      arguments = { filepath },
    }, { bufnr = bufnr })
    return
  end

  if vim.fn.executable("typst") == 1 then
    vim.system({ "typst", "compile", filepath }, { text = true }, function(obj)
      if obj.code ~= 0 then
        vim.schedule(function()
          vim.notify(obj.stderr, vim.log.levels.WARN)
        end)
      end
    end)
    return
  end

  if not vim.b[bufnr].typst_compile_warned then
    vim.b[bufnr].typst_compile_warned = true
    vim.notify("Typst autocompile needs tinymist LSP or typst CLI", vim.log.levels.WARN)
  end
end

local group_name = "UserTypstAutocompile." .. bufnr

local function enable_autocompile()
  local group = vim.api.nvim_create_augroup(group_name, { clear = true })
  vim.api.nvim_create_autocmd("BufWritePost", {
    group = group,
    buffer = bufnr,
    desc = "Autocompile Typst to PDF on save",
    callback = compile_pdf,
  })
  vim.b[bufnr].typst_autocompile = true
end

local function disable_autocompile()
  pcall(vim.api.nvim_del_augroup_by_name, group_name)
  vim.b[bufnr].typst_autocompile = false
end

enable_autocompile()

vim.keymap.set("n", "<localleader>tx", function()
  if vim.b[bufnr].typst_autocompile then
    disable_autocompile()
    vim.notify("Typst autocompile stopped", vim.log.levels.INFO)
  else
    enable_autocompile()
    vim.notify("Typst autocompile started", vim.log.levels.INFO)
  end
end, { buffer = bufnr, desc = "Toggle Typst autocompile" })

vim.keymap.set("n", "<localleader>tp", compile_pdf, { buffer = bufnr, desc = "Compile Typst PDF" })
