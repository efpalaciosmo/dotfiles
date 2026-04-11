local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  {
    "stevearc/oil.nvim",
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local oil_clipboard_cut = false

      require("oil").setup({
        default_file_explorer = true,
        columns = { "icon", "size", "mtime" },
        skip_confirm_for_simple_edits = true,
        float = {
          padding = 2,
          max_width = 80,
          max_height = 35,
          border = "rounded",
          win_options = {
            winblend = 0,
          },
        },
        lsp_file_methods = {
          enabled = true,
          autosave_changes = "unmodified",
        },
        keymaps = {
          ["<C-h>"]   = false,
          ["<CR>"]    = { "actions.select", opts = { close = true } },
          ["<Tab>"]   = "actions.select",
          ["<S-Tab>"] = "actions.parent",
          ["a"]       = {
            desc = "Create new file/folder",
            mode = "n",
            callback = function()
              vim.cmd("normal! o")
              vim.cmd("startinsert!")
            end,
          },
          ["yy"]      = "actions.copy_to_system_clipboard",
          ["dd"]      = {
            desc = "Cut entry",
            callback = function()
              require("oil.actions").copy_to_system_clipboard.callback()
              oil_clipboard_cut = true
            end,
          },
          ["p"]       = {
            desc = "Paste entry",
            callback = function()
              local opts = oil_clipboard_cut and { delete_original = true } or nil
              require("oil.actions").paste_from_system_clipboard.callback(opts)
              oil_clipboard_cut = false
            end,
          },
        },
        view_options = {
          show_hidden = true,
          is_always_hidden = function(name)
            return name == ".git"
          end,
        },
      })
    end,
  },
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    config = function()
      require("nvim-treesitter").setup({
        ensure_installed = {
          "astro",
          "bash",
          "c",
          "css",
          "go",
          "html",
          "javascript",
          "json",
          "lua",
          "luadoc",
          "markdown",
          "markdown_inline",
          "python",
          "query",
          "sql",
          "tsx",
          "typescript",
          "typst",
          "vim",
          "vimdoc",
          "zig",
        },
      })
    end,
  },
  { "mason-org/mason.nvim",           lazy = false },
  { "mason-org/mason-lspconfig.nvim", lazy = false },
  { "neovim/nvim-lspconfig",          lazy = false },
  {
    "saghen/blink.cmp",
    version = "v1",
    lazy = false,
    config = function()
      require("blink.cmp").setup({
        keymap = {
          preset = "none",
          ["<Tab>"]     = { "snippet_forward", "select_next", "fallback" },
          ["<S-Tab>"]   = { "snippet_backward", "select_prev", "fallback" },
          ["<CR>"]      = { "accept", "fallback" },
          ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
          ["<C-e>"]     = { "hide", "fallback" },
        },
        appearance = {
          nerd_font_variant = "mono",
        },
        completion = {
          documentation = { auto_show = false },
        },
        signature = {
          enabled = true,
        },
        sources = {
          default = { "lsp", "path", "snippets", "buffer" },
          providers = {
            lsp = {
              fallbacks = {},
            },
          },
        },
        fuzzy = {
          implementation = "rust",
        },
      })
    end,
  },
  { "nvim-tree/nvim-web-devicons", lazy = false },
  {
    "nvim-lualine/lualine.nvim",
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local c = require("config.theme").palette()
      local is_dark = vim.o.background == "dark"
      local bg = is_dark and c.libadwaita_dark_alt or c.light_3
      local fg = is_dark and c.light_4 or c.dark_3

      local theme = {
        normal = {
          a = { fg = bg, bg = c.teal_5, gui = "bold" },
          b = { fg = c.teal_5, bg = is_dark and c.dark_4 or c.light_4 },
          c = { fg = fg, bg = bg },
        },
        insert = {
          a = { fg = bg, bg = c.orange_4, gui = "bold" },
          b = { fg = c.orange_1, bg = is_dark and c.dark_4 or c.light_4 },
          c = { fg = fg, bg = bg },
        },
        visual = {
          a = { fg = bg, bg = c.blue_5, gui = "bold" },
          b = { fg = c.blue_5, bg = is_dark and c.dark_4 or c.light_4 },
          c = { fg = fg, bg = bg },
        },
        replace = {
          a = { fg = bg, bg = is_dark and c.purple_3 or c.purple_2, gui = "bold" },
          b = { fg = c.purple_2, bg = is_dark and c.dark_4 or c.light_4 },
          c = { fg = fg, bg = bg },
        },
        command = {
          a = { fg = bg, bg = c.yellow_4, gui = "bold" },
          b = { fg = c.yellow_6, bg = is_dark and c.dark_4 or c.light_4 },
          c = { fg = fg, bg = bg },
        },
        inactive = {
          a = { fg = fg, bg = bg, gui = "bold" },
          b = { fg = fg, bg = bg },
          c = { fg = fg, bg = bg },
        },
      }

      require("lualine").setup({
        options = {
          theme = theme,
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
          globalstatus = true,
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch", "diff", "diagnostics" },
          lualine_c = { { "filename", path = 1 } },
          lualine_x = { "encoding", "fileformat", "filetype" },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { "filename" },
          lualine_x = { "location" },
          lualine_y = {},
          lualine_z = {},
        },
      })
    end,
  },
  {
    "akinsho/bufferline.nvim",
    lazy = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("bufferline").setup({
        options = {
          mode = "buffers",
          diagnostics = "nvim_lsp",
          diagnostics_indicator = function(_, _, diag)
            local icons = { error = " ", warning = " ", info = " " }
            local result = {}
            for sev, icon in pairs(icons) do
              if diag[sev] then
                table.insert(result, icon .. diag[sev])
              end
            end
            return table.concat(result, " ")
          end,
          show_buffer_close_icons = false,
          show_close_icon = false,
          separator_style = "thin",
          always_show_bufferline = true,
          offsets = {
            {
              filetype = "oil",
              text = "File Explorer",
              highlight = "BufferLineOffsetSeparator",
              separator = true,
            },
          },
        },
      })
    end,
  },
  -- Markdown: in-buffer rendering
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    config = function()
      require("render-markdown").setup({
        heading = { sign = false },
        code = {
          sign = false,
          width = "block",
          right_pad = 1,
        },
      })
    end,
  },
  -- Markdown: browser preview
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    ft = { "markdown" },
    build = function()
      local app = vim.fn.stdpath("data") .. "/lazy/markdown-preview.nvim/app"
      local pkg = vim.fn.executable("pnpm") == 1 and "pnpm" or "npm"
      vim.fn.system(pkg .. " install --prefix " .. app)
    end,
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
      vim.g.mkdp_auto_close = 1
    end,
  },
  -- Formatters
  {
    "stevearc/conform.nvim",
    lazy = false,
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          javascript      = { "prettier" },
          javascriptreact = { "prettier" },
          typescript      = { "prettier" },
          typescriptreact = { "prettier" },
          astro           = { "prettier" },
          css             = { "prettier" },
          scss            = { "prettier" },
          html            = { "prettier" },
          json            = { "prettier" },
          markdown        = { "prettier" },
          lua             = { "stylua" },
          python          = { "ruff_format" },
          go              = { "goimports" },
          zig             = { "zigfmt" },
          c               = { "clang_format" },
        },
        format_on_save = {
          timeout_ms = 500,
          lsp_fallback = true,
        },
        formatters = {
          prettier = {
            prepend_args = { "--prose-wrap", "always" },
          },
        },
      })
    end,
  },
  -- Auto-install formatters via Mason
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    lazy = false,
    dependencies = { "mason-org/mason.nvim" },
    config = function()
      require("mason-tool-installer").setup({
        ensure_installed = {
          "prettier",
          "stylua",
          "ruff",
          "goimports",
          "zls",
          "clang-format",
        },
        auto_update = false,
        run_on_start = true,
      })
    end,
  },
}, {
  ui = {
    border = "rounded",
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
