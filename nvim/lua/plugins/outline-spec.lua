return {
  "simrat39/symbols-outline.nvim",
  config = function()
    -- Example mapping to toggle outline
    vim.keymap.set("n", "<leader>o", ":SymbolsOutline<CR>")

    require("symbols-outline").setup {
      -- Your setup opts here (leave empty to use defaults)
    }
  end,
}
