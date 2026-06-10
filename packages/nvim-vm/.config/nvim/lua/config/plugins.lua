-- Plugins managed by Neovim 0.12's built-in vim.pack.
-- Repos are cloned to stdpath('data')/site/pack/core/opt and added to runtimepath.
-- Update them with :lua vim.pack.update()

vim.pack.add({
  { src = "https://github.com/stevearc/oil.nvim" },
  -- Pin blink.cmp to the v1 line; 2.x splits the fuzzy lib into a separate package.
  { src = "https://github.com/saghen/blink.cmp",                       version = vim.version.range("1") },
  { src = "https://github.com/neovim/nvim-lspconfig" },
  { src = "https://github.com/ibhagwan/fzf-lua" },
  { src = "https://github.com/nvim-tree/nvim-web-devicons" },
  { src = "https://github.com/nvim-lualine/lualine.nvim" },
  -- Tooling: install / manage LSP servers, formatters, linters from one place.
  { src = "https://github.com/mason-org/mason.nvim" },
  { src = "https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim" },
  -- In-buffer markdown rendering (headings, code blocks, lists, checkboxes...).
  { src = "https://github.com/MeanderingProgrammer/render-markdown.nvim" },
})

-- ============================================================================
-- mason.nvim — package manager for LSP servers, formatters, linters, DAPs.
-- Must run BEFORE lua/config/lsp.lua so $MASON/bin is on $PATH when we probe
-- vim.fn.executable() to decide which servers to enable.
-- ============================================================================
require("mason").setup({
  ui = {
    border = "rounded",
    width = 0.8,
    height = 0.8,
    icons = {
      package_installed = "✓",
      package_pending = "➜",
      package_uninstalled = "✗",
    },
  },
  -- Keep Python package installs isolated under stdpath('data')/mason.
  -- Node tooling is installed by Ansible with pnpm instead of Mason's npm backend.
  pip = { upgrade_pip = false },
  max_concurrent_installers = 6,
})

-- mason-tool-installer keeps a declarative list of tools in sync.
-- New tools installed automatically; existing ones updated on demand.
require("mason-tool-installer").setup({
  ensure_installed = {
    -- LSP servers (names are Mason package names, not lspconfig names).
    "basedpyright",
    "ruff",
    "lua-language-server",
    "vtsls",
    "clangd",
    "zls",
    "rust-analyzer",
    "julia-lsp",
    "marksman",
    "sqls",
    "bash-language-server",
    "json-lsp",
    "yaml-language-server",
    "html-lsp",
    "css-lsp",
    "tailwindcss-language-server",
    "tinymist",

    -- Extra CLI tools.
    "prettier",
    "stylua",
    "typstyle",
    "sqlfluff",
    "shfmt",
    "shellcheck",
  },
  auto_update = false,
  run_on_start = true,
  start_delay = 3000,
  -- Do not debounce installs: a failed run (for example, a provider missing from PATH)
  -- otherwise blocks retries until the debounce window expires.
  debounce_hours = nil,
})

-- ============================================================================
-- oil.nvim — edit your filesystem like a buffer.
-- ============================================================================
require("oil").setup({
  default_file_explorer = true,
  delete_to_trash = true,
  skip_confirm_for_simple_edits = true,
  watch_for_changes = true,
  view_options = {
    show_hidden = true,
    natural_order = true,
    is_always_hidden = function(name)
      return name == ".." or name == ".git"
    end,
  },
  win_options = {
    wrap = false,
    signcolumn = "no",
    cursorcolumn = false,
    foldcolumn = "0",
    spell = false,
    list = false,
    conceallevel = 3,
    concealcursor = "nvic",
  },
  float = {
    padding = 2,
    max_width = 100,
    max_height = 30,
    border = "rounded",
    win_options = { winblend = 0 },
    preview_split = "auto",
  },
  preview_win = {
    update_on_cursor_moved = true,
    win_options = { number = false, signcolumn = "no" },
  },
  confirmation = { border = "rounded" },
  progress = { border = "rounded" },
  ssh = { border = "rounded" },
  keymaps_help = { border = "rounded" },
  keymaps = {
    ["g?"] = { "actions.show_help", mode = "n" },
    ["<CR>"] = "actions.select",
    ["<C-s>"] = { "actions.select", opts = { vertical = true } },
    ["<C-h>"] = { "actions.select", opts = { horizontal = true } },
    ["<C-t>"] = { "actions.select", opts = { tab = true } },
    ["<C-p>"] = "actions.preview",
    ["<C-c>"] = { "actions.close", mode = "n" },
    ["<C-l>"] = "actions.refresh",
    ["-"] = { "actions.parent", mode = "n" },
    ["_"] = { "actions.open_cwd", mode = "n" },
    ["`"] = { "actions.cd", mode = "n" },
    ["~"] = { "actions.cd", opts = { scope = "tab" }, mode = "n" },
    ["gs"] = { "actions.change_sort", mode = "n" },
    ["gx"] = "actions.open_external",
    ["g."] = { "actions.toggle_hidden", mode = "n" },
    ["g\\"] = { "actions.toggle_trash", mode = "n" },
  },
})

-- ============================================================================
-- blink.cmp — completion engine with rich UI.
-- ============================================================================
require("blink.cmp").setup({
  keymap = {
    -- Custom map: Tab / S-Tab navigate the menu, <CR> accepts, arrows are
    -- intentionally NOT bound so they keep their normal cursor behavior even
    -- while the popup is open.
    preset = "none",
    ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
    ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
    ["<CR>"] = { "accept", "fallback" },
    ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
    ["<C-e>"] = { "cancel", "hide", "fallback" },
    ["<C-n>"] = { "select_next", "show" },
    ["<C-p>"] = { "select_prev", "show" },
    ["<C-b>"] = { "scroll_documentation_up", "fallback" },
    ["<C-f>"] = { "scroll_documentation_down", "fallback" },
    ["<C-k>"] = { "show_signature", "hide_signature", "fallback" },
  },

  appearance = {
    nerd_font_variant = "mono",
    use_nvim_cmp_as_default = false,
    -- Short labels next to LSP "kind" icons in the menu.
    kind_icons = {
      Text = "󰉿",
      Method = "󰊕",
      Function = "󰊕",
      Constructor = "󰒓",
      Field = "󰜢",
      Variable = "󰆦",
      Property = "󰖷",
      Class = "󱡠",
      Interface = "󱡠",
      Struct = "󱡠",
      Module = "󰅩",
      Unit = "󰪚",
      Value = "󰦨",
      Enum = "󰦨",
      EnumMember = "󰦨",
      Keyword = "󰻾",
      Constant = "󰏿",
      Snippet = "󱄽",
      Color = "󰏘",
      File = "󰈔",
      Reference = "󰬲",
      Folder = "󰉋",
      Event = "󱐋",
      Operator = "󰪚",
      TypeParameter = "󰬛",
    },
  },

  completion = {
    accept = { auto_brackets = { enabled = true } },

    list = {
      selection = { preselect = false, auto_insert = true },
    },

    menu = {
      border = "rounded",
      winblend = 0,
      scrolloff = 2,
      scrollbar = false,
      draw = {
        treesitter = { "lsp" },
        padding = { 0, 1 },
        gap = 1,
        columns = {
          { "kind_icon", "label",       gap = 1 },
          { "label_description" },
          { "kind",      "source_name", gap = 1 },
        },
        components = {
          kind_icon = {
            text = function(ctx) return ctx.kind_icon .. " " end,
          },
          source_name = {
            width = { max = 30 },
            text = function(ctx) return "[" .. ctx.source_name:lower():sub(1, 3) .. "]" end,
            highlight = "BlinkCmpSource",
          },
        },
      },
    },

    documentation = {
      auto_show = true,
      -- Show the doc popup almost instantly while Tab-cycling so users get
      -- parameter / return-type info as they navigate.
      auto_show_delay_ms = 50,
      update_delay_ms = 50,
      treesitter_highlighting = true,
      window = {
        border = "rounded",
        winblend = 0,
        min_width = 20,
        max_width = 80,
        max_height = 20,
      },
    },

    ghost_text = { enabled = true, show_with_menu = true },
  },

  -- Signature help: shown automatically when typing `(` after a function name
  -- (e.g. `pd.read_csv(`). The doc panel inside this window is what surfaces
  -- the parameter list / return type for the active call.
  signature = {
    enabled = true,
    trigger = {
      enabled = true,
      show_on_keyword = false,
      show_on_trigger_character = true,
      show_on_insert_on_trigger_character = true,
    },
    window = {
      border = "rounded",
      winblend = 0,
      show_documentation = true,
      treesitter_highlighting = true,
    },
  },

  sources = {
    default = { "lsp", "path", "snippets", "buffer" },
    providers = {
      lsp = { score_offset = 90 },
      snippets = { score_offset = 80 },
      path = { score_offset = 25 },
      buffer = { score_offset = 5 },
    },
  },

  cmdline = {
    enabled = true,
    keymap = { preset = "cmdline" },
    completion = {
      menu = { auto_show = true },
      ghost_text = { enabled = true },
    },
  },

  fuzzy = {
    implementation = "prefer_rust_with_warning",
  },
})

-- ============================================================================
-- fzf-lua — fuzzy finder. Polished borders/preview/colors.
-- ============================================================================
local fzf = require("fzf-lua")

fzf.setup({
  "default-title",

  fzf_colors = true,

  winopts = {
    height = 0.85,
    width = 0.85,
    row = 0.5,
    col = 0.5,
    border = "rounded",
    backdrop = 60,
    title_pos = "center",
    preview = {
      border = "rounded",
      layout = "flex",
      flip_columns = 120,
      scrollbar = "float",
      scrolloff = -1,
      delay = 60,
      winopts = { number = false, relativenumber = false, cursorline = false },
    },
  },

  fzf_opts = {
    ["--info"] = "inline-right",
    ["--layout"] = "reverse",
    ["--marker"] = "▌",
    ["--pointer"] = "▌",
    ["--prompt"] = "  ",
    ["--padding"] = "0,1",
  },

  hls = {
    normal = "Normal",
    border = "FloatBorder",
    title = "FloatTitle",
    preview_normal = "Normal",
    preview_border = "FloatBorder",
    preview_title = "FloatTitle",
    cursor = "Cursor",
    cursorline = "CursorLine",
    cursorlinenr = "CursorLineNr",
    search = "IncSearch",
    backdrop = "FzfLuaBackdrop",
  },

  keymap = {
    fzf = {
      true,
      ["ctrl-q"] = "select-all+accept",
      ["ctrl-d"] = "preview-page-down",
      ["ctrl-u"] = "preview-page-up",
      ["ctrl-a"] = "toggle-all",
    },
    builtin = {
      true,
      ["<C-d>"] = "preview-page-down",
      ["<C-u>"] = "preview-page-up",
      ["<C-f>"] = "preview-page-down",
      ["<C-b>"] = "preview-page-up",
      ["<F1>"] = "toggle-help",
    },
  },

  oldfiles = {
    -- include buffers visited in the current session (was missing in default fzf-lua, like Telescope)
    include_current_session = true,
    prompt = "  ",
  },

  previewers = {
    builtin = {
      -- Skip treesitter highlighting on huge minified files; keeps the previewer snappy.
      syntax_limit_b = 1024 * 100, -- 100KB
    },
  },

  grep = {
    -- Allow live_grep to filter by globs after a ' --' separator.
    -- Example: > enable --*/plugins/*
    rg_glob = true,
    glob_flag = "--iglob",
    glob_separator = "%s%-%-",
    prompt = "  ",
    rg_opts = "--column --line-number --no-heading --color=always --smart-case --max-columns=4096",
  },

  files = {
    prompt = "  ",
    git_icons = true,
    file_icons = true,
    color_icons = true,
  },

  buffers = {
    prompt = "  ",
    sort_lastused = true,
  },

  git = {
    files = { prompt = "  " },
    status = { prompt = " 󰊢 " },
    commits = { prompt = " 󰜘 " },
    bcommits = { prompt = " 󰜘 " },
    branches = { prompt = " 󰘬 " },
  },

  lsp = {
    prompt_postfix = "  ",
    code_actions = {
      prompt = " 󰌵 ",
      previewer = "codeaction",
      winopts = { relative = "cursor", row = 1, col = 0, height = 0.4, width = 0.6 },
    },
  },

  diagnostics = {
    prompt = "  ",
    cwd_only = false,
  },
})

-- Use fzf-lua for vim.ui.select (LSP code actions etc).
fzf.register_ui_select()

-- ============================================================================
-- nvim-web-devicons — filetype glyphs used by lualine + fzf-lua + oil.
-- ============================================================================
require("nvim-web-devicons").setup({ default = true })

-- ============================================================================
-- lualine — minimal but beautiful statusline.
--
-- Visual idea (Adwaita pill, powerline transition):
--   [   N ][   main ][ src/foo.lua  ●          ][  E1 ][ lua-language-server ][ 42:7  20% ]
--
-- - mode is rendered as a single letter inside an orange/green/purple pill
-- - separators are powerline triangles for the colored chunks; nothing in c
-- - filename uses path = 1 (relative) with subtle modified/readonly glyphs
-- - LSP/filetype/location live on the right
-- ============================================================================
local function lsp_names()
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients == 0 then return "" end
  local names = {}
  for _, client in ipairs(clients) do
    table.insert(names, client.name)
  end
  return "󰒋 " .. table.concat(names, ",")
end

local mode_letter = {
  n = "N", i = "I", v = "V", V = "V", ["\22"] = "B",
  c = "C", s = "S", S = "S", ["\19"] = "B",
  R = "R", r = "R", ["!"] = "!", t = "T",
}

require("lualine").setup({
  options = {
    theme = require("config.theme.lualine"),
    component_separators = "",
    section_separators = { left = "", right = "" },
    globalstatus = true,
    refresh = { statusline = 250, tabline = 1000, winbar = 1000 },
    disabled_filetypes = {
      statusline = { "alpha", "dashboard" },
      winbar = {},
    },
  },
  sections = {
    lualine_a = {
      {
        "mode",
        fmt = function() return " " .. (mode_letter[vim.fn.mode()] or "?") .. " " end,
        padding = 0,
      },
    },
    lualine_b = {
      { "branch", icon = "" },
    },
    lualine_c = {
      {
        "filename",
        path = 1,
        symbols = { modified = " ●", readonly = "  ", unnamed = "[No Name]" },
      },
      {
        "diff",
        symbols = { added = " ", modified = " ", removed = " " },
        diff_color = {
          added    = { fg = "#33d17a" },
          modified = { fg = "#ffa348" },
          removed  = { fg = "#f66151" },
        },
      },
    },
    lualine_x = {
      {
        "diagnostics",
        sources = { "nvim_diagnostic" },
        symbols = { error = " ", warn = " ", info = " ", hint = " " },
        update_in_insert = false,
      },
      { lsp_names, color = { fg = "#9a9996" } },
      { "filetype", icon_only = false, colored = true },
    },
    lualine_y = {
      { "progress", padding = { left = 1, right = 1 } },
    },
    lualine_z = {
      {
        "location",
        icon = { "", align = "left" },
        padding = { left = 1, right = 1 },
      },
    },
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = { { "filename", path = 1 } },
    lualine_x = { "location" },
    lualine_y = {},
    lualine_z = {},
  },
  extensions = { "oil", "fzf", "quickfix", "man" },
})

-- ============================================================================
-- render-markdown.nvim — pretty in-buffer rendering of markdown.
-- This is the "preview" you get without leaving Neovim: headings get pill
-- backgrounds, code fences get borders, bullets get dot icons, checkboxes
-- get rendered glyphs, links/quotes/tables look styled. Toggle with
-- :RenderMarkdown toggle (mapped to <leader>um in keymaps.lua).
-- ============================================================================
require("render-markdown").setup({
  enabled = true,
  -- Render only outside of insert mode so editing stays predictable.
  render_modes = { "n", "c", "t" },
  anti_conceal = { enabled = true },

  heading = {
    enabled = true,
    sign = true,
    position = "overlay",
    width = "block",
    min_width = 60,
    icons = { "󰉫  ", "󰉬  ", "󰉭  ", "󰉮  ", "󰉯  ", "󰉰  " },
    backgrounds = {
      "RenderMarkdownH1Bg", "RenderMarkdownH2Bg", "RenderMarkdownH3Bg",
      "RenderMarkdownH4Bg", "RenderMarkdownH5Bg", "RenderMarkdownH6Bg",
    },
    foregrounds = {
      "RenderMarkdownH1", "RenderMarkdownH2", "RenderMarkdownH3",
      "RenderMarkdownH4", "RenderMarkdownH5", "RenderMarkdownH6",
    },
  },

  code = {
    enabled = true,
    sign = false,
    style = "full",
    width = "block",
    min_width = 60,
    border = "thick",
    above = "▄",
    below = "▀",
    highlight = "RenderMarkdownCode",
    highlight_inline = "RenderMarkdownCodeInline",
  },

  bullet = {
    enabled = true,
    icons = { "●", "○", "◆", "◇" },
  },

  checkbox = {
    enabled = true,
    unchecked = { icon = "󰄱 ", highlight = "RenderMarkdownUnchecked" },
    checked = { icon = "󰱒 ", highlight = "RenderMarkdownChecked", scope_highlight = "@markup.strikethrough" },
    custom = {
      todo = { raw = "[-]", rendered = "󰥔 ", highlight = "RenderMarkdownTodo" },
    },
  },

  quote = { enabled = true, icon = "▍" },

  pipe_table = {
    enabled = true,
    style = "full",
    cell = "padded",
    border = {
      "┌", "┬", "┐",
      "├", "┼", "┤",
      "└", "┴", "┘",
      "│", "─",
    },
  },

  link = {
    enabled = true,
    image = "󰥶 ",
    email = "󰀓 ",
    hyperlink = "󰌹 ",
    wiki = { icon = "󰌹 ", highlight = "RenderMarkdownLink" },
  },

  sign = { enabled = true },
  file_types = { "markdown", "markdown.mdx", "Avante" },
})
