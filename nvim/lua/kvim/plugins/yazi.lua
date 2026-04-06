---@type LazySpec
-- yazi.nvim: Gestor de archivos rápido escrito en Rust
-- Integración con Yazi (alternativa a netrw/ranger)
return {
  "mikavilpas/yazi.nvim",
  version = "*",                             -- Usa la última versión estable
  event = "VeryLazy",                        -- Se carga después de iniciar (no bloquea)
  dependencies = {
    { "nvim-lua/plenary.nvim", lazy = true }, -- Dependencia para comandos async
  },
  lazy = true,                              -- Carga perezosa (keymaps la activan)
  keys = {
    -- <Leader>fp = Abre Yazi en la carpeta del archivo actual
    {
      "<leader>fp",
      mode = { "n", "v" },
      "<cmd>Yazi<cr>",
      desc = "Open yazi at the current file",
    },
    -- <Leader>cw = Abre Yazi en el directorio de trabajo actual de Neovim
    {
      "<leader>cw",
      "<cmd>Yazi cwd<cr>",
      desc = "Open the file manager in nvim's working directory",
    },
    -- Ctrl+Up = Reanuda la última sesión de Yazi
    {
      "<c-up>",
      "<cmd>Yazi toggle<cr>",
      desc = "Resume the last yazi session",
    },
  },
  opts = {
    open_for_directories = false,           -- No abre directorios directamente (usa netrw/yazi)
    keymaps = {
      show_help = "<f1>",                   -- Muestra ayuda en Yazi
    },
  },
  init = function()
    -- Desactiva netrw para que Yazi sea el único gestor de archivos
    vim.g.loaded_netrwPlugin = 1
  end,
}
