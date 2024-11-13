local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  -- bootstrap lazy.nvim
  -- stylua: ignore
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end

vim.opt.rtp:prepend(vim.env.LAZY or lazypath)

require("lazy").setup({
  {
    "nvim-tree/nvim-tree.lua"},
    version = "*",
    lazy = false,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    {
      "nvim-lualine/lualine.nvim",
      event = "VeryLazy",
    },
    {
      'stevearc/conform.nvim',
      opts = {},
      event = { "BufReadPre", "BufNewFile" },
    },
    {
      "zbirenbaum/copilot.lua",
      dependencies = {
        "zbirenbaum/copilot-cmp",
      }
    },
    {
      'akinsho/bufferline.nvim',
      version = "*",
      dependencies = 'nvim-tree/nvim-web-devicons'
    },
    {
      "nvim-treesitter/nvim-treesitter",
      dependencies = {
        "nvim-treesitter/nvim-treesitter-context",
        "windwp/nvim-ts-autotag"
      },
      opts = {
        ensure_installed = {
          "bash",
          "typescript",
          "javascript",
          "python",
          "go"
        }
      },
    },
    {
      'windwp/nvim-autopairs',
      event = "InsertEnter",
      opts = {} -- this is equivalent to setup({}) function
    },
    {
      "iamcco/markdown-preview.nvim",
      cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
      ft = { "markdown" },
      build = function() vim.fn["mkdp#util#install"]() end,
    },
    {
      "hrsh7th/nvim-cmp",
      dependencies = {
        "hrsh7th/cmp-nvim-lsp",
        "neovim/nvim-lspconfig",
        "hrsh7th/cmp-nvim-lua",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-cmdline",
        "saadparwaiz1/cmp_luasnip",
        "L3MON4D3/LuaSnip",
      },
    },
    {
      'nvim-telescope/telescope.nvim', tag = '0.1.4',
      dependencies = { 'nvim-lua/plenary.nvim' }
    },
    {
      "lewis6991/gitsigns.nvim",
    },
    {
      "ellisonleao/glow.nvim",
      config = true,
      cmd = "Glow"
    },
    {
      "folke/twilight.nvim",
      opts = {
        -- your configuration comes here
        -- or leave it empty to use the default settings
        -- refer to the configuration section below
      }
    },
    {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "neovim/nvim-lspconfig",
      "Hoffs/omnisharp-extended-lsp.nvim"
    }
  }
)

