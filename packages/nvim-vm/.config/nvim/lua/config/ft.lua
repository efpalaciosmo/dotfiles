-- Tiny helpers shared by every ftplugin/<lang>.lua.
-- Keeps each ftplugin file focused on what makes that language unique.

local M = {}

--- Set expandtab + shiftwidth/tabstop/softtabstop in one call.
--- @param sw integer  number of spaces per indent step
--- @param expandtab? boolean  default true; pass false for tab-indented filetypes
function M.indent(sw, expandtab)
  local o = vim.opt_local
  o.expandtab = expandtab ~= false
  o.shiftwidth = sw
  o.tabstop = sw
  o.softtabstop = sw
end

--- Configure 'formatprg' (used by `gq`) only if the binary is on $PATH.
--- @param bin string         executable name to probe
--- @param command string     full command, including args
function M.formatprg(bin, command)
  if vim.fn.executable(bin) == 1 then
    vim.opt_local.formatprg = command
  end
end

local function as_list(value)
  if value == nil or value == true then
    return nil
  end
  if type(value) == "string" then
    return { value }
  end
  return value
end

local function list_contains(list, value)
  if not list then
    return true
  end
  for _, item in ipairs(list) do
    if item == value then
      return true
    end
  end
  return false
end

local function action_kind_matches(kind, only)
  if not only then
    return true
  end
  for _, prefix in ipairs(only) do
    if kind == prefix or vim.startswith(kind or "", prefix .. ".") then
      return true
    end
  end
  return false
end

local function apply_code_actions(bufnr, opts)
  local only = as_list(opts.code_actions)
  if not only then
    return
  end

  local clients = vim.lsp.get_clients({ bufnr = bufnr })
  for _, client in ipairs(clients) do
    if list_contains(as_list(opts.clients), client.name) and client:supports_method("textDocument/codeAction") then
      local params = vim.lsp.util.make_range_params(0, client.offset_encoding)
      params.context = {
        diagnostics = vim.diagnostic.get(bufnr),
        only = only,
      }

      local response = client:request_sync("textDocument/codeAction", params, opts.timeout_ms or 2000, bufnr)
      for _, action in ipairs((response and response.result) or {}) do
        if action_kind_matches(action.kind, only) then
          if not action.edit and action.data and client:supports_method("codeAction/resolve") then
            local resolved = client:request_sync("codeAction/resolve", action, opts.timeout_ms or 2000, bufnr)
            action = (resolved and resolved.result) or action
          end
          if action.edit then
            vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
          end
          if action.command then
            pcall(vim.lsp.buf.execute_command, action.command)
          end
        end
      end
    end
  end
end

local function lsp_format(bufnr, opts)
  local names = as_list(opts.lsp)
  local has_formatter = false

  for _, client in ipairs(vim.lsp.get_clients({ bufnr = bufnr })) do
    if list_contains(names, client.name) and client:supports_method("textDocument/formatting") then
      has_formatter = true
      break
    end
  end
  if not has_formatter then
    return false
  end

  local ok = pcall(vim.lsp.buf.format, {
    bufnr = bufnr,
    async = false,
    timeout_ms = opts.timeout_ms or 2000,
    filter = function(client)
      return list_contains(names, client.name)
    end,
  })
  return ok
end

local function format_with_formatprg(bufnr)
  local formatprg = vim.bo[bufnr].formatprg
  if formatprg == "" then
    return false
  end

  local input = table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n") .. "\n"
  local output = vim.fn.system(formatprg, input)
  if vim.v.shell_error ~= 0 then
    vim.notify("formatprg failed: " .. formatprg, vim.log.levels.WARN)
    return false
  end

  local lines = vim.split(output, "\n", { plain = true })
  if lines[#lines] == "" then
    table.remove(lines)
  end
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  return true
end

--- Format the current buffer before save.
--- @param opts? {lsp?: boolean|string|string[], formatprg?: boolean, code_actions?: string|string[], clients?: string|string[], timeout_ms?: integer}
function M.format_on_save(opts)
  opts = opts or {}
  local bufnr = vim.api.nvim_get_current_buf()
  local group = vim.api.nvim_create_augroup("UserFormatOnSave." .. bufnr, { clear = true })

  vim.api.nvim_create_autocmd("BufWritePre", {
    group = group,
    buffer = bufnr,
    desc = "Format on save",
    callback = function()
      if vim.bo[bufnr].buftype ~= "" or not vim.bo[bufnr].modifiable then
        return
      end

      local view = vim.fn.winsaveview()
      apply_code_actions(bufnr, opts)
      local formatted = false
      if opts.lsp ~= false then
        formatted = lsp_format(bufnr, opts)
      end
      if not formatted and opts.formatprg ~= false then
        format_with_formatprg(bufnr)
      end
      vim.fn.winrestview(view)
    end,
  })
end

--- Append filetype-specific suffixes to 'suffixesadd' for `gf` / find.
--- @param suffixes string[]
function M.suffixes(suffixes)
  for _, s in ipairs(suffixes) do
    vim.opt_local.suffixesadd:prepend(s)
  end
end

return M
