# KVIM Workspaces Module

Módulo MVP para guardar y restaurar workspaces de proyecto.

## Alcance del MVP

- Guardar workspace actual.
- Cargar workspace por nombre.
- Listar workspaces.
- Borrar workspace.
- Consultar workspace actual en memoria.
- Guardar/restaurar sesión de Neovim con `resession.nvim`.

## Comandos

- `:KvimWorkspaceSave [name]`
- `:KvimWorkspaceLoad <name>`
- `:KvimWorkspaceList`
- `:KvimWorkspaceDelete <name>`
- `:KvimWorkspaceCurrent`

## Keymaps (prefijo por defecto `<leader>w`)

- `<leader>ws` guardar workspace actual
- `<leader>wl` listar workspaces
- `<leader>wc` mostrar workspace actual

## Storage

Ruta de persistencia:

```text
vim.fn.stdpath("state") .. "/kvim/workspaces"
```

Formato v1:

```lua
{
    name = "kvim",
    root = "/ruta/al/proyecto",
    session = "kvim",
    version = 1,
    connections = { active = nil },
    terminals = {},
    tasks = {},
}
```

## Limitaciones actuales

- No restaura procesos interactivos vivos.
- No integra picker visual.
- No implementa auto-save ni auto-restore.
- No integra restauración profunda con `connections`.
