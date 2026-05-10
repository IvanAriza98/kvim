return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
  },

  {
    "akinsho/bufferline.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
  },

  {
    "nvim-lualine/lualine.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
  },
}
