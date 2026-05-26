# KVIM Workspaces Module

Módulo MVP para guardar y restaurar workspaces de proyecto.

## Alcance del MVP

- Guardar workspace actual.
- Capturar automáticamente terminales abiertas reproducibles al guardar.
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
- `:KvimWorkspaceNext`
- `:KvimWorkspacePrev`
- `:KvimWorkspaceTerminalAdd`
- `:KvimWorkspaceTerminalList`
- `:KvimWorkspaceTerminalRemove <name>`
- `:KvimWorkspaceTerminalRestore`

## Keymaps (prefijo por defecto `<leader>w`)

- `<leader>ws` guardar workspace actual
- `<leader>wl` listar workspaces
- `<leader>wc` mostrar workspace actual
- `<leader>wn` cargar siguiente workspace
- `<leader>wp` cargar workspace anterior
- `<leader>wt` listar recetas de terminal
- `<leader>wr` restaurar recetas de terminal

Navegación rápida por tabs de workspace:

- `<leader>1` ir a tab `code`
- `<leader>2` ir a tab `term`

## Integración opcional con Connections

Las recetas de terminal tipo `ssh` pueden usar:

- `connection = "Nombre de conexión"` para resolver contra el módulo `connections`.
- `command = "ssh user@host"` como fallback opcional.

Si `connections` no está disponible o la conexión no existe, se usa `command` si está definido.

## Nota sobre captura automática de terminales

`KvimWorkspaceSave` intenta capturar las terminales abiertas y guardar recetas restaurables.

- Si una terminal no tiene comando recuperable de forma fiable, no se guarda.
- No se guardan procesos vivos; solo metadatos reproducibles (comando/cwd/tipo).

## Layout por defecto

Cada workspace usa por defecto dos tabs lógicas:

- `code`
- `term`

Al cargar un workspace, KVIM restaura el contenido y deja el foco final en `code`.

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
