# KVIM Plugins

Este directorio define las especificaciones de plugins para `lazy.nvim`.

Archivo agregador:

- `init.lua`: importa los grupos de plugins:
  - `kvim.plugins.ui`
  - `kvim.plugins.lsp`
  - `kvim.plugins.dev`
  - `kvim.plugins.editor`
  - `kvim.plugins.dashboard`
  - `kvim.plugins.navigation`
  - `kvim.plugins.completion`

## Propósito por archivo

### `ui.lua`
Plugins de interfaz:

- `catppuccin/nvim` (tema)
- `akinsho/bufferline.nvim` (bufferline)
- `nvim-lualine/lualine.nvim` (statusline)
- `sphamba/smear-cursor.nvim` (efecto visual de cursor)

### `lsp.lua`
Base de LSP:

- `neovim/nvim-lspconfig`
- dependencias:
  - `mason-org/mason.nvim`
  - `mason-org/mason-lspconfig.nvim`

### `dev.lua`
Dependencia común para utilidades y tests:

- `nvim-lua/plenary.nvim`

### `editor.lua`
Edición y estructura de código:

- `nvim-treesitter/nvim-treesitter`
- `kevinhwang91/nvim-ufo` (+ `kevinhwang91/promise-async`) para folds
- `shellRaining/hlchunk.nvim` para indent/chunks
- `m4xshen/smartcolumn.nvim` para columna guía dinámica

### `dashboard.lua`
Dashboard inicial con `folke/snacks.nvim`.

### `navigation.lua`
Navegación y exploración:

- `nvim-neo-tree/neo-tree.nvim`
- `mikavilpas/yazi.nvim`
- `nvim-telescope/telescope.nvim`

### `completion.lua`
Autocompletado con:

- `saghen/blink.cmp`
- snippets opcionales: `rafamadriz/friendly-snippets`

---

## Dependencias opcionales de sistema

Estas herramientas externas no siempre son obligatorias para arrancar KVIM, pero sí para funcionalidades concretas:

- `ripgrep` → `Telescope live_grep`
- `yazi` → integración de `yazi.nvim`
- Nerd Font → iconos correctos en UI
- `git` → requerido por lazy.nvim y flujos Git
- `lazygit` → comandos del módulo Git
- `svn` y `lazysvn` → módulo SVN
- `ssh`, `scp`, `picocom` → módulo Connections

## Nota de compatibilidad

Las specs están escritas para `lazy.nvim`.
Si se cambia un plugin o su evento de carga, actualizar también la documentación del módulo/feature afectado.
