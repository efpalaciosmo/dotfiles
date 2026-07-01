-- Adwaita 1.9 palette (slim).
-- Source of truth:
--   https://gnome.pages.gitlab.gnome.org/libadwaita/doc/1.3/css-variables.html
--
-- Surfaces follow the official dark UI-color spec:
--   --window-bg-color    = #222226
--   --view-bg-color      = #1d1d20   (text/code surface; we go a touch darker)
--   --headerbar-bg-color = #2e2e32
--   --sidebar-bg-color   = #2e2e32
--   --sidebar-backdrop   = #28282c
--   --popover-bg-color   = #36363a
--   --dialog-bg-color    = #36363a
--   --thumbnail-bg-color = #39393d
--
-- Accent colors come from the Palette section (--blue-1..-5, --orange-1..-5, etc.),
-- which is what GNOME Builder/Text Editor reach for in syntax themes.

local M = {}

local function nvim_set_hl(ns_id)
  return function(name, val)
    vim.api.nvim_set_hl(ns_id, name, val)
  end
end

M.highlight = nvim_set_hl(0)

function M.gen_colors()
  local colors = {
    -- ---------------------------------------------------------------- surfaces
    bg            = "#1a1a1d", -- editor body: slightly deeper than --view-bg
    bg_alt        = "#28282c", -- statusline / cursorline / signcolumn lift
    bg_popup      = "#2e2e32", -- popovers, blink.cmp, fzf-lua, lsp hover
    bg_view       = "#1d1d20", -- official --view-bg-color (kept for reference)
    bg_selected   = "#36363a", -- pmenu selection / visual-mode lift
    column_guide  = "#2e2025", -- ColorColumn: warm-tinted dark, visible on bg

    -- ---------------------------------------------------------------- borders
    -- Splits/terminal/oil borders use the canonical Adwaita accent orange.
    border        = "#ff7800", -- WinSeparator / VertSplit (orange-3 accent)
    border_soft   = "#3d3d44", -- FloatBorder (popups): subtle, doesn't overload

    -- ---------------------------------------------------------------- greys
    dark_1        = "#77767b",
    dark_2        = "#5e5c64",
    dark_3        = "#3d3846",
    dark_4        = "#241f31",
    dark_5        = "#000000",

    light_1       = "#ffffff",
    light_2       = "#f6f5f4",
    light_3       = "#deddda",
    light_4       = "#c0bfbc",
    light_5       = "#9a9996",

    -- ------------------------------------------------------- palette accents
    -- (verbatim from the Adwaita "Palette Colors" table)
    blue_1        = "#99c1f1",
    blue_2        = "#62a0ea",
    blue_3        = "#3584e4",
    blue_4        = "#1c71d8",
    blue_5        = "#1a5fb4",

    green_1       = "#8ff0a4",
    green_2       = "#57e389",
    green_3       = "#33d17a",
    green_4       = "#2ec27e",
    green_5       = "#26a269",

    yellow_1      = "#f9f06b",
    yellow_2      = "#f8e45c",
    yellow_3      = "#f6d32d",
    yellow_4      = "#f5c211",
    yellow_5      = "#e5a50a",

    orange_1      = "#ffbe6f",
    orange_2      = "#ffa348",
    orange_3      = "#ff7800", -- canonical GNOME accent orange
    orange_4      = "#e66100",
    orange_5      = "#c64600",

    red_1         = "#f66151",
    red_2         = "#ed333b",
    red_3         = "#e01b24",
    red_4         = "#c01c28",
    red_5         = "#a51d2d",

    purple_1      = "#dc8add",
    purple_2      = "#c061cb",
    purple_3      = "#9141ac",
    purple_4      = "#813d9c",
    purple_5      = "#613583",

    -- ------------------------------------------------------- standalone-dark
    -- Per the spec these are "lighter than bg, designed for vibrant fg use on
    -- dark backgrounds". Great for accent text without losing legibility.
    s_blue        = "#81d0ff",
    s_teal        = "#7bdff4",
    s_green       = "#8de698",
    s_yellow      = "#ffc057",
    s_orange      = "#ff9c5b",
    s_red         = "#ff888c",
    s_pink        = "#ffa0d8",
    s_purple      = "#fba7ff",
  }

  if vim.g.adwaita_transparent then
    colors.bg = "NONE"
  end

  return colors
end

return M
