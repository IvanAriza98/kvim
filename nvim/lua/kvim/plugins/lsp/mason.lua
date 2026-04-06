return {
  "williamboman/mason.nvim",
  lazy = false,
  dependencies = {
    {
      "williamboman/mason-lspconfig.nvim",
      lazy = false,
      config = function()
        require("mason-lspconfig").setup({
          ensure_installed = {
            "pyright",
            "clangd",
            "lua_ls",
            "bashls",
          },
          automatic_installation = true,
        })
      end,
    },
    {
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      lazy = false,
      config = function()
        require("mason-tool-installer").setup({
          ensure_installed = {
            "pyright",
            "clangd",
            "lua-language-server",
            "bash-language-server",
            "black",
            "clang-format",
            "stylua",
            "shfmt",
            "ruff",
            "luacheck",
            "shellcheck",
            "debugpy",
            "codelldb",
            "bash-debug-adapter",
          },
          auto_update = false,
          run_on_start = true,
        })
      end,
    },
  },
  build = ":MasonUpdate",
  config = function()
    -- Configuración de mason (solo mason.nvim)
    require("mason").setup({
      ui = {
        icons = {
          package_installed   = "✓",
          package_pending     = "➜",
          package_uninstalled = "✗",
        },
      },
    })
  end,
}
