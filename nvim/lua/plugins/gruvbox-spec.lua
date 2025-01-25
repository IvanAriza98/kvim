return {
  {
    "morhetz/gruvbox",
    config = function()
      vim.cmd [[colorscheme gruvbox]]
      vim.opt.background = "dark"
      vim.opt.termguicolors = true
      vim.opt.guifont = "FiraCode Nerd Font:h11"
    end,
  },
}
