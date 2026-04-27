-- Adwaita Dark (vibrant). Highlights only.
-- Surfaces follow the official UI-color spec, syntax leans into the
-- vibrant tier of the GNOME palette (--*_2 / --*_3 colors).

local u = require("config.theme.util")
local hl = u.highlight

local M = {}

local function set_terminal_colors(c)
  vim.g.terminal_color_0  = c.bg
  vim.g.terminal_color_1  = c.red_2
  vim.g.terminal_color_2  = c.green_3
  vim.g.terminal_color_3  = c.orange_3
  vim.g.terminal_color_4  = c.blue_2
  vim.g.terminal_color_5  = c.purple_2
  vim.g.terminal_color_6  = c.s_teal
  vim.g.terminal_color_7  = c.light_3
  vim.g.terminal_color_8  = c.dark_1
  vim.g.terminal_color_9  = c.red_1
  vim.g.terminal_color_10 = c.green_1
  vim.g.terminal_color_11 = c.orange_1
  vim.g.terminal_color_12 = c.blue_1
  vim.g.terminal_color_13 = c.purple_1
  vim.g.terminal_color_14 = c.s_teal
  vim.g.terminal_color_15 = c.light_2
end

function M.set()
  local c = u.gen_colors()
  set_terminal_colors(c)

  -- ===========================================================================
  -- Core UI
  -- ===========================================================================
  hl("Normal",         { fg = c.light_3, bg = c.bg })
  hl("NormalNC",       { fg = c.light_3, bg = c.bg })
  hl("NormalFloat",    { fg = c.light_3, bg = c.bg_popup })
  hl("FloatBorder",    { fg = c.border_soft, bg = c.bg_popup })
  hl("FloatTitle",     { fg = c.orange_3,    bg = c.bg_popup, bold = true })
  hl("WinBar",         { fg = c.light_4,     bg = c.bg })
  hl("WinBarNC",       { fg = c.dark_1,      bg = c.bg })

  -- Split / terminal / oil-split borders → vibrant Adwaita orange (everywhere).
  hl("WinSeparator",   { fg = c.border, bg = "NONE", bold = true })
  hl("VertSplit",      { link = "WinSeparator" })

  hl("ColorColumn",    { bg = c.column_guide })
  hl("Cursor",         { fg = c.bg, bg = c.light_2 })
  hl("CursorLine",     { bg = c.bg_alt })
  hl("CursorColumn",   { bg = c.bg_alt })
  hl("LineNr",         { fg = c.dark_2, bg = c.bg })
  hl("CursorLineNr",   { fg = c.orange_3, bg = c.bg_alt, bold = true })
  hl("SignColumn",     { fg = c.dark_2, bg = c.bg })
  hl("FoldColumn",     { fg = c.dark_1, bg = c.bg })
  hl("Folded",         { fg = c.dark_1, bg = c.bg_alt })

  hl("EndOfBuffer",    { fg = c.bg, bg = c.bg })
  hl("NonText",        { fg = c.dark_3 })
  hl("Whitespace",     { fg = c.dark_3 })
  hl("SpecialKey",     { fg = c.dark_2, bg = c.bg })

  hl("MatchParen",     { fg = c.orange_3, bold = true, underline = true })
  hl("ModeMsg",        { fg = c.light_3 })
  hl("MoreMsg",        { fg = c.light_3 })
  hl("Question",       { fg = c.s_blue })
  hl("ErrorMsg",       { fg = c.red_2, bold = true })
  hl("WarningMsg",     { fg = c.yellow_4, bold = true })

  -- Visual: Adwaita selection feels like a translucent accent on top of bg.
  hl("Visual",         { bg = "#2a3a5e" })
  hl("VisualNOS",      { bg = "#2a3a5e" })
  hl("Search",         { fg = c.bg, bg = c.yellow_4, bold = true })
  hl("IncSearch",      { fg = c.bg, bg = c.orange_3, bold = true })
  hl("CurSearch",      { fg = c.bg, bg = c.orange_2, bold = true })
  hl("Substitute",     { fg = c.bg, bg = c.purple_2, bold = true })

  hl("Pmenu",          { fg = c.light_3, bg = c.bg_popup })
  hl("PmenuSel",       { fg = c.light_1, bg = c.bg_selected, bold = true })
  hl("PmenuSbar",      { bg = c.bg_alt })
  hl("PmenuThumb",     { bg = c.dark_1 })
  hl("WildMenu",       { fg = c.bg, bg = c.orange_3, bold = true })

  hl("StatusLine",     { fg = c.light_3, bg = c.bg_alt })
  hl("StatusLineNC",   { fg = c.dark_1, bg = c.bg })
  hl("TabLine",        { fg = c.dark_1, bg = c.bg_alt })
  hl("TabLineFill",    { fg = c.dark_1, bg = c.bg_alt })
  hl("TabLineSel",     { fg = c.orange_3, bg = c.bg, bold = true })

  hl("Title",          { fg = c.orange_3, bold = true })
  hl("Directory",      { fg = c.blue_2, bold = true })
  hl("Underlined",     { underline = true })
  hl("Conceal",        { fg = c.dark_1 })
  hl("QuickFixLine",   { bg = c.bg_alt, bold = true })

  hl("DiffAdd",        { fg = c.green_2,  bg = "#1a2a1f" })
  hl("DiffChange",     { fg = c.orange_2, bg = "#2a201a" })
  hl("DiffDelete",     { fg = c.red_1,    bg = "#2a1a1d" })
  hl("DiffText",       { fg = c.s_yellow, bg = "#3a2e1a", bold = true })

  -- ===========================================================================
  -- Syntax (legacy groups) — vibrant tier
  -- ===========================================================================
  hl("Comment",        { fg = c.dark_1, italic = true })
  hl("Constant",       { fg = c.purple_1 })
  hl("String",         { fg = c.green_3 })
  hl("Character",      { fg = c.green_2 })
  hl("Number",         { fg = c.purple_1 })
  hl("Boolean",        { fg = c.purple_2, bold = true })
  hl("Float",          { fg = c.purple_1 })
  hl("Identifier",     { fg = c.light_3 })
  hl("Function",       { fg = c.blue_2,   bold = true })
  hl("Statement",      { fg = c.orange_3, bold = true })
  hl("Conditional",    { fg = c.orange_3, bold = true })
  hl("Repeat",         { fg = c.orange_3, bold = true })
  hl("Label",          { fg = c.purple_2 })
  hl("Operator",       { fg = c.s_orange })
  hl("Keyword",        { fg = c.orange_3, bold = true })
  hl("Exception",      { fg = c.red_1,    bold = true })
  hl("PreProc",        { fg = c.orange_2 })
  hl("Include",        { fg = c.orange_3, bold = true })
  hl("Define",         { fg = c.orange_3, bold = true })
  hl("Macro",          { fg = c.orange_2 })
  hl("PreCondit",      { fg = c.orange_3, bold = true })
  hl("Type",           { fg = c.orange_1 })
  hl("StorageClass",   { fg = c.orange_3, bold = true })
  hl("Structure",      { fg = c.orange_1, bold = true })
  hl("TypeDef",        { fg = c.orange_1, bold = true })
  hl("Special",        { fg = c.s_teal })
  hl("SpecialChar",    { fg = c.s_teal })
  hl("Tag",            { fg = c.green_3 })
  hl("Delimiter",      { fg = c.light_4 })
  hl("SpecialComment", { fg = c.s_blue, bold = true })
  hl("Debug",          { fg = c.s_yellow })
  hl("Todo",           { fg = c.yellow_2, bg = c.bg, bold = true })
  hl("Error",          { fg = c.red_2, underline = true })
  hl("SpellBad",       { sp = c.red_2,    undercurl = true })
  hl("SpellCap",       { sp = c.yellow_4, undercurl = true })
  hl("SpellRare",      { sp = c.purple_2, undercurl = true })
  hl("SpellLocal",     { sp = c.s_teal,   undercurl = true })

  -- ===========================================================================
  -- Treesitter
  -- ===========================================================================
  hl("@comment",                 { link = "Comment" })
  hl("@comment.todo",            { fg = c.yellow_2, bold = true })
  hl("@comment.note",            { fg = c.green_3,  bold = true })
  hl("@comment.warning",         { fg = c.orange_2, bold = true })
  hl("@comment.error",           { fg = c.red_2,    bold = true })

  hl("@punctuation",             { fg = c.light_4 })
  hl("@punctuation.bracket",     { fg = c.light_4 })
  hl("@punctuation.delimiter",   { fg = c.light_4 })
  hl("@punctuation.special",     { fg = c.s_teal })

  hl("@constant",                { fg = c.purple_1 })
  hl("@constant.builtin",        { fg = c.purple_2, bold = true })
  hl("@constant.macro",          { fg = c.orange_2, bold = true })

  hl("@string",                  { fg = c.green_3 })
  hl("@string.documentation",    { fg = c.green_3, italic = true })
  hl("@string.escape",           { fg = c.s_teal })
  hl("@string.special",          { fg = c.s_teal })
  hl("@string.regexp",           { fg = c.purple_2 })
  hl("@character",               { fg = c.green_2 })
  hl("@character.special",       { fg = c.s_teal })
  hl("@number",                  { fg = c.purple_1 })
  hl("@boolean",                 { fg = c.purple_2, bold = true })
  hl("@float",                   { fg = c.purple_1 })

  hl("@function",                { fg = c.blue_2, bold = true })
  hl("@function.builtin",        { fg = c.s_blue, bold = true })
  hl("@function.call",           { fg = c.blue_2 })
  hl("@function.macro",          { fg = c.s_blue, bold = true })
  hl("@function.method",         { fg = c.blue_2 })
  hl("@function.method.call",    { fg = c.blue_2 })
  hl("@constructor",             { fg = c.orange_1, bold = true })

  hl("@keyword",                 { fg = c.orange_3, bold = true })
  hl("@keyword.function",        { fg = c.orange_3, bold = true })
  hl("@keyword.operator",        { fg = c.s_orange })
  hl("@keyword.return",          { fg = c.red_1,    bold = true })
  hl("@keyword.import",          { fg = c.orange_3, bold = true })
  hl("@keyword.exception",       { fg = c.red_1,    bold = true })
  hl("@keyword.conditional",     { fg = c.orange_3, bold = true })
  hl("@keyword.repeat",          { fg = c.orange_3, bold = true })
  hl("@keyword.modifier",        { fg = c.purple_2 })

  hl("@operator",                { fg = c.s_orange })
  hl("@label",                   { fg = c.purple_2 })

  hl("@variable",                { fg = c.light_3 })
  hl("@variable.builtin",        { fg = c.purple_2, italic = true })
  hl("@variable.parameter",      { fg = c.s_orange })
  hl("@variable.member",         { fg = c.blue_1 })
  hl("@property",                { fg = c.blue_1 })
  hl("@field",                   { fg = c.blue_1 })

  hl("@type",                    { fg = c.orange_1 })
  hl("@type.builtin",            { fg = c.orange_1, italic = true })
  hl("@type.definition",         { fg = c.orange_1, bold = true })
  hl("@module",                  { fg = c.s_yellow })
  hl("@namespace",               { fg = c.s_yellow })
  hl("@attribute",               { fg = c.purple_1 })

  hl("@tag",                     { fg = c.green_3 })
  hl("@tag.builtin",             { fg = c.green_3, bold = true })
  hl("@tag.attribute",           { fg = c.s_orange })
  hl("@tag.delimiter",           { fg = c.light_4 })

  hl("@markup",                  { fg = c.light_3 })
  hl("@markup.heading",          { fg = c.orange_3, bold = true })
  hl("@markup.heading.1",        { fg = c.orange_3, bold = true })
  hl("@markup.heading.2",        { fg = c.s_orange, bold = true })
  hl("@markup.heading.3",        { fg = c.s_yellow, bold = true })
  hl("@markup.heading.4",        { fg = c.green_3,  bold = true })
  hl("@markup.heading.5",        { fg = c.s_blue,   bold = true })
  hl("@markup.heading.6",        { fg = c.purple_2, bold = true })
  hl("@markup.strong",           { fg = c.light_2,  bold = true })
  hl("@markup.italic",           { fg = c.light_3,  italic = true })
  hl("@markup.strikethrough",    { fg = c.dark_1,   strikethrough = true })
  hl("@markup.link",             { fg = c.blue_2 })
  hl("@markup.link.url",         { fg = c.s_blue,   underline = true })
  hl("@markup.link.label",       { fg = c.green_2 })
  hl("@markup.raw",              { fg = c.green_3 })
  hl("@markup.list",             { fg = c.orange_2 })
  hl("@markup.list.checked",     { fg = c.green_3 })
  hl("@markup.list.unchecked",   { fg = c.dark_1 })
  hl("@markup.quote",            { fg = c.dark_1, italic = true })

  hl("@diff.plus",               { fg = c.green_2 })
  hl("@diff.minus",              { fg = c.red_1 })
  hl("@diff.delta",              { fg = c.orange_2 })

  -- ===========================================================================
  -- LSP semantic tokens (link to treesitter equivalents)
  -- ===========================================================================
  hl("@lsp.type.class",         { link = "@type" })
  hl("@lsp.type.decorator",     { link = "@function" })
  hl("@lsp.type.enum",          { link = "@type" })
  hl("@lsp.type.enumMember",    { link = "@constant" })
  hl("@lsp.type.function",      { link = "@function" })
  hl("@lsp.type.interface",     { link = "@type" })
  hl("@lsp.type.macro",         { link = "@function.macro" })
  hl("@lsp.type.method",        { link = "@function.method" })
  hl("@lsp.type.namespace",     { link = "@namespace" })
  hl("@lsp.type.parameter",     { link = "@variable.parameter" })
  hl("@lsp.type.property",      { link = "@property" })
  hl("@lsp.type.struct",        { link = "@type" })
  hl("@lsp.type.type",          { link = "@type" })
  hl("@lsp.type.typeParameter", { link = "@type" })
  hl("@lsp.type.variable",      { link = "@variable" })
  hl("@lsp.type.keyword",       { link = "@keyword" })
  hl("@lsp.mod.deprecated",     { strikethrough = true })

  -- ===========================================================================
  -- Native diagnostics (Neovim 0.12)
  -- ===========================================================================
  hl("DiagnosticError",            { fg = c.red_2 })
  hl("DiagnosticWarn",             { fg = c.s_yellow })
  hl("DiagnosticInfo",             { fg = c.s_teal })
  hl("DiagnosticHint",             { fg = c.s_blue })
  hl("DiagnosticOk",               { fg = c.green_3 })

  hl("DiagnosticVirtualTextError", { fg = c.red_2,    bg = "NONE" })
  hl("DiagnosticVirtualTextWarn",  { fg = c.s_yellow, bg = "NONE" })
  hl("DiagnosticVirtualTextInfo",  { fg = c.s_teal,   bg = "NONE" })
  hl("DiagnosticVirtualTextHint",  { fg = c.s_blue,   bg = "NONE" })

  hl("DiagnosticUnderlineError",   { sp = c.red_2,    undercurl = true })
  hl("DiagnosticUnderlineWarn",    { sp = c.s_yellow, undercurl = true })
  hl("DiagnosticUnderlineInfo",    { sp = c.s_teal,   undercurl = true })
  hl("DiagnosticUnderlineHint",    { sp = c.s_blue,   undercurl = true })

  hl("LspReferenceText",  { bg = "#2a3a5e" })
  hl("LspReferenceRead",  { bg = "#2a3a5e" })
  hl("LspReferenceWrite", { bg = "#2a3a5e" })
  hl("LspInlayHint",      { fg = c.dark_1, bg = c.bg, italic = true })
  hl("LspSignatureActiveParameter", { fg = c.orange_3, bold = true })

  -- ===========================================================================
  -- blink.cmp
  -- ===========================================================================
  hl("BlinkCmpMenu",                  { link = "Pmenu" })
  hl("BlinkCmpMenuBorder",            { link = "FloatBorder" })
  hl("BlinkCmpMenuSelection",         { link = "PmenuSel" })
  hl("BlinkCmpScrollBarThumb",        { bg = c.dark_1 })
  hl("BlinkCmpScrollBarGutter",       { bg = c.bg_popup })
  hl("BlinkCmpLabel",                 { fg = c.light_3 })
  hl("BlinkCmpLabelDeprecated",       { fg = c.dark_1, strikethrough = true })
  hl("BlinkCmpLabelMatch",            { fg = c.orange_3, bold = true })
  hl("BlinkCmpLabelDescription",      { fg = c.dark_1 })
  hl("BlinkCmpKind",                  { fg = c.s_blue })
  hl("BlinkCmpSource",                { fg = c.dark_1 })
  hl("BlinkCmpDoc",                   { link = "NormalFloat" })
  hl("BlinkCmpDocBorder",             { link = "FloatBorder" })
  hl("BlinkCmpSignatureHelp",         { link = "NormalFloat" })
  hl("BlinkCmpSignatureHelpBorder",   { link = "FloatBorder" })
  hl("BlinkCmpGhostText",             { fg = c.dark_1, italic = true })

  -- ===========================================================================
  -- oil.nvim
  -- ===========================================================================
  hl("OilDir",            { fg = c.blue_2,  bold = true })
  hl("OilDirIcon",        { fg = c.blue_2 })
  hl("OilLink",           { fg = c.s_teal })
  hl("OilLinkTarget",     { fg = c.s_teal,  italic = true })
  hl("OilFile",           { fg = c.light_3 })
  hl("OilCreate",         { fg = c.green_3 })
  hl("OilDelete",         { fg = c.red_2 })
  hl("OilMove",           { fg = c.orange_3 })
  hl("OilCopy",           { fg = c.purple_2 })
  hl("OilChange",         { fg = c.s_yellow })
  hl("OilRestore",        { fg = c.green_3 })
  hl("OilTrash",          { fg = c.red_2 })
  hl("OilPurge",          { fg = c.red_3 })

  -- ===========================================================================
  -- fzf-lua
  -- ===========================================================================
  hl("FzfLuaNormal",         { link = "NormalFloat" })
  hl("FzfLuaBorder",         { link = "FloatBorder" })
  hl("FzfLuaTitle",          { fg = c.orange_3, bg = c.bg_popup, bold = true })
  hl("FzfLuaPreviewNormal",  { link = "NormalFloat" })
  hl("FzfLuaPreviewBorder",  { link = "FloatBorder" })
  hl("FzfLuaPreviewTitle",   { fg = c.s_blue,   bg = c.bg_popup, bold = true })
  hl("FzfLuaCursor",         { link = "Cursor" })
  hl("FzfLuaCursorLine",     { link = "CursorLine" })
  hl("FzfLuaCursorLineNr",   { link = "CursorLineNr" })
  hl("FzfLuaSearch",         { link = "IncSearch" })
  hl("FzfLuaScrollBorderEmpty", { fg = c.border_soft, bg = c.bg_popup })
  hl("FzfLuaScrollBorderFull",  { fg = c.dark_1,      bg = c.bg_popup })
  hl("FzfLuaBackdrop",       { bg = "#000000" })
  hl("FzfLuaHeaderText",     { fg = c.orange_3 })
  hl("FzfLuaHeaderBind",     { fg = c.purple_2 })
  hl("FzfLuaPathColNr",      { fg = c.s_teal })
  hl("FzfLuaPathLineNr",     { fg = c.green_3 })
  hl("FzfLuaBufNr",          { fg = c.s_yellow })
  hl("FzfLuaBufFlagCur",     { fg = c.orange_3 })
  hl("FzfLuaBufFlagAlt",     { fg = c.blue_2 })
  hl("FzfLuaTabTitle",       { fg = c.orange_3, bold = true })
  hl("FzfLuaTabMarker",      { fg = c.purple_2 })

  -- ===========================================================================
  -- Custom: terminal floats → orange border (windowed via TermOpen autocmd)
  -- ===========================================================================
  hl("TermFloatBorder", { fg = c.border, bg = c.bg_popup, bold = true })
end

return M
