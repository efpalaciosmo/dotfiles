local M = {}

local function highlight(group, spec)
  vim.api.nvim_set_hl(0, group, spec)
end

local function link(from, to)
  highlight(from, { link = to })
end

function M.palette()
  if vim.o.background == "dark" then
    return {
      blue_1 = "#99C1F1",
      blue_2 = "#62A0EA",
      blue_3 = "#3584E4",
      blue_4 = "#1C71D8",
      blue_5 = "#1A5FB4",
      blue_7 = "#193D66",
      chameleon_3 = "#4E9A06",
      dark_1 = "#777777",
      dark_2 = "#5E5E5E",
      dark_3 = "#505050",
      dark_4 = "#3D3D3D",
      green_1 = "#8FF0A4",
      green_2 = "#57E389",
      green_3 = "#33D17A",
      libadwaita_dark = "#1D1D20",
      libadwaita_dark_alt = "#242428",
      libadwaita_popup = "#36363A",
      light_1 = "#FFFFFF",
      light_3 = "#F6F5F4",
      light_4 = "#DEDDDA",
      light_5 = "#C0BFBC",
      light_7 = "#9A9996",
      orange_1 = "#FFBE6F",
      orange_2 = "#FFA348",
      orange_3 = "#FF7800",
      orange_4 = "#E66100",
      purple_1 = "#DC8ADD",
      purple_2 = "#C061CB",
      purple_3 = "#9141AC",
      red_1 = "#F66151",
      red_2 = "#ED333B",
      red_3 = "#E01B24",
      teal_1 = "#93DDC2",
      teal_2 = "#5BC8AF",
      teal_3 = "#33B2A4",
      teal_5 = "#218787",
      violet_2 = "#7D8AC7",
      violet_4 = "#4E57BA",
      yellow_2 = "#F8E45C",
      yellow_4 = "#F5C211",
      yellow_6 = "#D38B09",
      split_and_borders = "#2E2E32",
      menu_selected = "#4A4A4D",
      search_bg = "#F5C211",
      search_fg = "#3D3D3D",
    }
  end

  return {
    blue_1 = "#99C1F1",
    blue_2 = "#62A0EA",
    blue_3 = "#3584E4",
    blue_4 = "#1C71D8",
    blue_5 = "#1A5FB4",
    chameleon_3 = "#4E9A06",
    dark_1 = "#77767B",
    dark_2 = "#5E5C64",
    dark_3 = "#504E55",
    dark_4 = "#3D3846",
    green_3 = "#33D17A",
    light_1 = "#FFFFFF",
    light_2 = "#FCFCFC",
    light_3 = "#F6F5F4",
    light_4 = "#DEDDDA",
    light_5 = "#C0BFBC",
    light_6 = "#B0AFAC",
    light_7 = "#9A9996",
    orange_1 = "#FFBE6F",
    orange_3 = "#FF7800",
    orange_4 = "#E66100",
    orange_5 = "#C64600",
    purple_1 = "#DC8ADD",
    purple_2 = "#C061CB",
    red_1 = "#F66151",
    red_2 = "#ED333B",
    red_3 = "#E01B24",
    teal_2 = "#5BC8AF",
    teal_5 = "#218787",
    violet_3 = "#6362C8",
    violet_4 = "#4E57BA",
    yellow_2 = "#F8E45C",
    yellow_4 = "#F5C211",
    yellow_6 = "#D38B09",
    search_bg = "#FCF7B5",
    search_fg = "#3D3846",
  }
end

local function set_terminal_colors(c, is_dark)
  vim.g.terminal_color_0 = is_dark and c.libadwaita_dark or c.light_2
  vim.g.terminal_color_1 = c.red_2
  vim.g.terminal_color_2 = is_dark and c.green_2 or c.green_3
  vim.g.terminal_color_3 = is_dark and c.orange_3 or c.orange_3
  vim.g.terminal_color_4 = c.blue_2
  vim.g.terminal_color_5 = is_dark and c.purple_3 or c.purple_2
  vim.g.terminal_color_6 = c.teal_2
  vim.g.terminal_color_7 = is_dark and c.light_4 or c.light_4
  vim.g.terminal_color_8 = is_dark and c.light_7 or c.light_7
  vim.g.terminal_color_9 = c.red_1
  vim.g.terminal_color_10 = is_dark and c.green_1 or c.green_3
  vim.g.terminal_color_11 = is_dark and c.orange_2 or c.yellow_2
  vim.g.terminal_color_12 = is_dark and c.blue_1 or c.blue_1
  vim.g.terminal_color_13 = is_dark and c.purple_1 or c.purple_1
  vim.g.terminal_color_14 = is_dark and c.teal_1 or c.teal_2
  vim.g.terminal_color_15 = is_dark and c.light_3 or c.light_3
end

function M.load()
  local c = M.palette()
  local is_dark = vim.o.background == "dark"
  local transparent = vim.g.transparent_background == true
  local normal_bg = transparent and "NONE" or (is_dark and c.libadwaita_dark or c.light_1)
  local alt_bg = transparent and "NONE" or (is_dark and c.libadwaita_dark_alt or c.light_3)
  local float_bg = transparent and "NONE" or (is_dark and c.libadwaita_popup or c.light_3)
  local fg = is_dark and c.light_4 or c.dark_3

  vim.g.colors_name = "minimal_adwaita"
  set_terminal_colors(c, is_dark)

  highlight("Normal", { fg = fg, bg = normal_bg })
  highlight("NormalNC", { fg = fg, bg = normal_bg })
  highlight("EndOfBuffer", { fg = transparent and "NONE" or normal_bg, bg = normal_bg })
  highlight("NormalFloat", { fg = fg, bg = float_bg })
  highlight("FloatBorder", { fg = is_dark and c.light_3 or c.dark_3, bg = float_bg })
  highlight("ColorColumn", { bg = alt_bg })
  highlight("CursorLine", { bg = alt_bg })
  highlight("CursorColumn", { bg = alt_bg })
  highlight("CursorLineNr", { fg = is_dark and c.light_7 or c.light_7, bg = alt_bg, bold = true })
  highlight("LineNr", { fg = is_dark and c.dark_2 or c.light_6, bg = normal_bg })
  highlight("SignColumn", { fg = is_dark and c.dark_2 or c.dark_2, bg = normal_bg })
  highlight("Folded", { fg = is_dark and c.dark_1 or c.dark_1, bg = normal_bg })
  highlight("Directory", { fg = is_dark and c.light_1 or c.dark_4, bg = normal_bg, bold = not is_dark })
  highlight("StatusLine", { fg = fg, bg = alt_bg })
  highlight("StatusLineNC", { fg = fg, bg = is_dark and normal_bg or c.light_4 })
  highlight("Pmenu", { fg = fg, bg = float_bg })
  highlight("PmenuSel", { fg = fg, bg = is_dark and c.menu_selected or c.light_5 })
  highlight("PmenuSbar", { bg = is_dark and c.dark_3 or c.dark_1 })
  highlight("PmenuThumb", { bg = is_dark and c.dark_1 or c.light_5 })
  highlight("Visual", { bg = is_dark and c.blue_7 or c.blue_1 })
  highlight("Search", { fg = c.search_fg, bg = c.search_bg })
  highlight("IncSearch", { fg = c.search_fg, bg = c.search_bg })
  highlight("WinSeparator", { fg = is_dark and c.split_and_borders or c.light_5, bg = normal_bg })
  highlight("NonText", { fg = is_dark and c.dark_4 or c.dark_1 })
  highlight("Title", { fg = is_dark and c.teal_2 or c.teal_5, bold = true })

  highlight("Comment", { fg = is_dark and c.dark_2 or c.dark_1 })
  highlight("Constant", { fg = is_dark and c.violet_2 or c.violet_4 })
  highlight("String", { fg = is_dark and c.teal_2 or c.teal_5 })
  highlight("Number", { fg = is_dark and c.violet_4 or c.violet_4 })
  highlight("Boolean", { fg = is_dark and c.purple_2 or c.violet_4, bold = true })
  highlight("Identifier", { fg = is_dark and c.orange_2 or c.orange_5 })
  highlight("Function", { fg = is_dark and c.chameleon_3 or c.chameleon_3 })
  highlight("Statement", { fg = is_dark and c.orange_2 or c.purple_2, bold = true })
  highlight("Conditional", { fg = is_dark and c.orange_2 or c.orange_5, bold = true })
  highlight("Repeat", { fg = is_dark and c.orange_2 or c.purple_1, bold = true })
  highlight("Operator", { fg = is_dark and c.purple_2 or c.dark_3 })
  highlight("Keyword", { fg = is_dark and c.orange_2 or c.orange_5, bold = true })
  highlight("Type", { fg = is_dark and c.light_4 or c.teal_5, bold = not is_dark })
  highlight("Special", { fg = is_dark and c.blue_2 or c.red_2 })
  highlight("Delimiter", { fg = is_dark and c.teal_2 or c.dark_3 })

  highlight("DiagnosticError", { fg = c.red_2 })
  highlight("DiagnosticWarn", { fg = c.yellow_6 })
  highlight("DiagnosticHint", { fg = c.blue_4 })
  highlight("DiagnosticInfo", { fg = is_dark and c.teal_5 or c.teal_5 })

  link("@comment", "Comment")
  link("@constant", "Constant")
  link("@string", "String")
  link("@function", "Function")
  link("@keyword", "Keyword")
  link("@type", "Type")
  link("@variable", "Identifier")
  link("@property", "Identifier")
  link("@field", "Identifier")
  link("@parameter", "Identifier")
  link("@tag", "Type")
  link("@tag.attribute", "Identifier")
  link("@tag.delimiter", "Delimiter")

  link("@lsp.type.class", "@type")
  link("@lsp.type.decorator", "@function")
  link("@lsp.type.enum", "@type")
  link("@lsp.type.enumMember", "@property")
  link("@lsp.type.function", "@function")
  link("@lsp.type.interface", "@type")
  link("@lsp.type.macro", "Macro")
  link("@lsp.type.method", "@function")
  link("@lsp.type.namespace", "@type")
  link("@lsp.type.parameter", "@parameter")
  link("@lsp.type.property", "@property")
  link("@lsp.type.struct", "@type")
  link("@lsp.type.type", "@type")
  link("@lsp.type.typeParameter", "@type")
  link("@lsp.type.variable", "@variable")
  link("@lsp.type.keyword", "@keyword")

  link("BlinkCmpMenu", "Pmenu")
  link("BlinkCmpMenuBorder", "FloatBorder")
  link("BlinkCmpMenuSelection", "PmenuSel")
  link("BlinkCmpScrollBarThumb", "PmenuThumb")
  link("BlinkCmpScrollBarGutter", "PmenuSbar")
  highlight("BlinkCmpLabel", { fg = fg, bg = "NONE" })
  highlight("BlinkCmpLabelMatch", { fg = is_dark and c.blue_3 or c.red_2, bg = "NONE", bold = true })

  highlight("OilDir", { fg = is_dark and c.light_1 or c.dark_4, bold = true })
  highlight("OilFile", { fg = fg })
  highlight("OilLink", { fg = is_dark and c.blue_2 or c.blue_4 })
  highlight("OilCopy", { fg = is_dark and c.teal_3 or c.teal_5 })
  highlight("OilMove", { fg = is_dark and c.orange_1 or c.orange_4 })
  highlight("OilChange", { fg = is_dark and c.yellow_2 or c.yellow_6 })
  highlight("OilDelete", { fg = c.red_2 })
  highlight("OilCreate", { fg = is_dark and c.green_2 or c.green_3 })

  local bufline_bg = is_dark and c.libadwaita_dark or c.light_4
  local bufline_inactive_fg = is_dark and c.dark_2 or c.light_7
  highlight("BufferLineFill", { bg = bufline_bg })
  highlight("BufferLineBackground", { fg = bufline_inactive_fg, bg = bufline_bg })
  highlight("BufferLineBufferSelected", { fg = fg, bg = normal_bg, bold = true, italic = false })
  highlight("BufferLineBufferVisible", { fg = fg, bg = alt_bg })
  highlight("BufferLineSeparator", { fg = bufline_bg, bg = bufline_bg })
  highlight("BufferLineSeparatorSelected", { fg = bufline_bg, bg = normal_bg })
  highlight("BufferLineSeparatorVisible", { fg = bufline_bg, bg = alt_bg })
  highlight("BufferLineIndicatorSelected", { fg = c.teal_5, bg = normal_bg })
  highlight("BufferLineModified", { fg = c.yellow_6, bg = bufline_bg })
  highlight("BufferLineModifiedSelected", { fg = c.yellow_6, bg = normal_bg })
  highlight("BufferLineModifiedVisible", { fg = c.yellow_6, bg = alt_bg })
  highlight("BufferLineCloseButton", { fg = bufline_inactive_fg, bg = bufline_bg })
  highlight("BufferLineCloseButtonSelected", { fg = c.red_2, bg = normal_bg })
  highlight("BufferLineTab", { fg = bufline_inactive_fg, bg = bufline_bg })
  highlight("BufferLineTabSelected", { fg = fg, bg = normal_bg, bold = true })
  highlight("BufferLineTabSeparator", { fg = bufline_bg, bg = bufline_bg })
  highlight("BufferLineTabSeparatorSelected", { fg = bufline_bg, bg = normal_bg })
  highlight("BufferLineOffsetSeparator", { fg = bufline_bg, bg = bufline_bg })
  highlight("BufferLineDiagnostic", { fg = bufline_inactive_fg, bg = bufline_bg })
  highlight("BufferLineDiagnosticSelected", { fg = fg, bg = normal_bg })
end

return M
