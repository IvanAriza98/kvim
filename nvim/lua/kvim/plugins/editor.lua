return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },

    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "lua",
          "vim",
          "vimdoc",
          "c",
          "cpp",
          "python",
          "json",
          "yaml",
          "markdown",
          "markdown_inline",
        },

        highlight = {
            enable = true,
            disable = { "bash" },
        },

        indent = {
            enable = true,
            disable = { "bash" },
        },
      })
    end,
  },
}
