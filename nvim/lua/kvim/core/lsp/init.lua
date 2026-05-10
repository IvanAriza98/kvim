local M = {}

function M.setup()
  local ok_mason, mason = pcall(require, "mason")
  if not ok_mason then
    vim.notify("KVIM LSP: mason.nvim not found", vim.log.levels.WARN)
    return
  end

  local ok_mason_lspconfig, mason_lspconfig = pcall(require, "mason-lspconfig")
  if not ok_mason_lspconfig then
    vim.notify("KVIM LSP: mason-lspconfig.nvim not found", vim.log.levels.WARN)
    return
  end

  require("kvim.core.lsp.diagnostics").setup()
  require("kvim.core.lsp.keymaps").setup()
  require("kvim.core.lsp.servers").setup()

  mason.setup()

  mason_lspconfig.setup({
    ensure_installed = {
      "lua_ls",
      "clangd",
      "pyright",
      "ts_ls",
      "bashls",
      "jsonls",
      "yamlls",
    },

    automatic_enable = true,
  })
end

return M
