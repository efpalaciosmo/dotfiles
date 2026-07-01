-- Lualine palette derived from the Adwaita 1.9 dark UI palette.
-- Mode pill (section a) uses a vibrant accent; section b sits on the popover
-- tone (#2e2e32); section c blends with the editor surface for a clean,
-- minimal look. Inactive windows fade to a single grey-on-bg line.

local u = require("config.theme.util")
local c = u.gen_colors()

local theme = {
  normal = {
    a = { fg = c.bg, bg = c.orange_3,  gui = "bold" },
    b = { fg = c.orange_1, bg = c.bg_popup },
    c = { fg = c.light_3, bg = c.bg_alt },
  },
  insert = {
    a = { fg = c.bg, bg = c.green_3,   gui = "bold" },
    b = { fg = c.green_1,  bg = c.bg_popup },
    c = { fg = c.light_3,  bg = c.bg_alt },
  },
  visual = {
    a = { fg = c.bg, bg = c.purple_2,  gui = "bold" },
    b = { fg = c.purple_1, bg = c.bg_popup },
    c = { fg = c.light_3,  bg = c.bg_alt },
  },
  replace = {
    a = { fg = c.bg, bg = c.red_2,     gui = "bold" },
    b = { fg = c.red_1,    bg = c.bg_popup },
    c = { fg = c.light_3,  bg = c.bg_alt },
  },
  command = {
    a = { fg = c.bg, bg = c.s_yellow,  gui = "bold" },
    b = { fg = c.yellow_2, bg = c.bg_popup },
    c = { fg = c.light_3,  bg = c.bg_alt },
  },
  terminal = {
    a = { fg = c.bg, bg = c.orange_3,  gui = "bold" },
    b = { fg = c.orange_1, bg = c.bg_popup },
    c = { fg = c.light_3,  bg = c.bg_alt },
  },
  inactive = {
    a = { fg = c.dark_1, bg = c.bg, gui = "bold" },
    b = { fg = c.dark_1, bg = c.bg },
    c = { fg = c.dark_1, bg = c.bg },
  },
}

return theme
