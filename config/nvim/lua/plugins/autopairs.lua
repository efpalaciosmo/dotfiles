require'nvim-treesitter.configs'.setup {
  autotag = {
    enable = true,
    enable_rename = true,
    enable_close = true,
    enable_close_on_slash = true,
    filetypes = {
      'html', 'javascript', 'typescript', 'python', 'bash', 'jsx',
      'xml', 'json',
      'markdown',
      'c_sharp', 
    }
  }
}
