return {
  "williamboman/mason.nvim",
  dependencies = {
    "williamboman/mason-lspconfig.nvim",
    "WhoIsSethDaniel/mason-tool-installer.nvim",
  },
  build = ":MasonUpdate",
  config = function()
    -- 1) mason core
    require("mason").setup({
      ui = {
        icons = {
          package_installed   = "✓",
          package_pending     = "➜",
          package_uninstalled = "✗",
        },
      },
    })

    -- -- 2) mason-lspconfig: instalar y configurar LSPs automáticamente
    -- require("mason-lspconfig").setup({
    --   -- lista de servidores que quieres asegurar estén instalados:
    --   ensure_installed = {
    --     "html",
    --     "cssls",
    --     "tailwindcss",
    --     "svelte",
    --     "lua_ls",
    --     "graphql",
    --     "emmet_ls",
    --     "prismals",
    --     "pyright",
    --   },
    --   -- instala cualquier servidor que lspconfig configure:
    --   automatic_installation = true,
    --   -- handler por defecto para configurar cada servidor
    --   handlers = {
    --     function(server_name)  -- se llama para cada LSP instalado
    --       require("lspconfig")[server_name].setup({})
    --     end,
    --   },
    -- })
    --
    -- -- 3) mason-tool-installer: instalar herramientas CLI (formatters, linters...)
    -- require("mason-tool-installer").setup({
    --   ensure_installed = {
    --     "prettier",   -- prettier formatter
    --     "stylua",     -- lua formatter
    --     "isort",      -- python formatter
    --     "black",      -- python formatter
    --     "pylint",     -- python linter
    --     "eslint_d",   -- JS/TS linter
    --   },
    --   run_on_start = true,     -- (opcional) corre la instalación al iniciar Neovim
    --   start_delay = 3000,      -- (opcional) espera 3s antes de correr
    -- })
  end,
}

