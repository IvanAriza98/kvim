# KVIM

KVIM es un IDE modular sobre Neovim y Lua.
Su arquitectura está basada en un core pequeño (`core/`) y módulos funcionales autocontenidos (`modules/`) que registran acciones, comandos y keymaps.

Este README documenta el estado **real actual** del repositorio.

---

## Arquitectura actual

Estructura principal:

```text
.
├── nvim/
│   ├── init.lua
│   ├── lazy-lock.json
│   └── lua/kvim/
│       ├── init.lua
│       ├── config.lua
│       ├── health.lua
│       ├── connections.lua
│       ├── core/
│       │   ├── commands.lua
│       │   ├── keymaps.lua
│       │   ├── registry.lua
│       │   ├── runner.lua
│       │   ├── terminal.lua
│       │   └── lsp/
│       ├── modules/
│       │   ├── connections/
│       │   ├── git/
│       │   └── svn/
│       ├── plugins/
│       └── ui/
├── tests/
├── scripts/test.sh
├── README.md
└── CHANGELOG.md
```

### Flujo de carga

1. `nvim/init.lua` inicializa `lazy.nvim` e importa plugins.
2. `require("kvim").setup()`:
   - carga configuración global (`kvim.config`);
   - registra comandos core;
   - configura UI y tema;
   - configura LSP;
   - carga módulos habilitados en `config.modules` y los registra en el registry;
   - aplica keymaps globales.

---

## Instalación

> Este repositorio contiene la configuración dentro de `nvim/`, no en la raíz.

### Requisitos mínimos

- Neovim (recomendado: versión reciente con soporte `vim.system`)
- Git

### Dependencias recomendadas/optativas

- `ripgrep` (Telescope live_grep)
- `yazi` (file manager externo)
- `lazygit` (módulo Git)
- `svn` y `lazysvn` (módulo SVN)
- `ssh`, `scp` (módulo Connections)
- `picocom` (conexiones serie)

### Ejemplo de instalación

```bash
git clone https://github.com/kodvmv/kvim.git ~/kvim
mkdir -p ~/.config/nvim
cp -r ~/kvim/nvim/* ~/.config/nvim/
nvim
```

En el primer arranque, `lazy.nvim` instalará plugins automáticamente.

---

## Comandos disponibles (estado actual)

### Core

- `:KvimModules`
  Lista módulos registrados.
- `:KvimAction <modulo> <accion>`
  Ejecuta una acción registrada en el módulo.

> Nota: en keymaps core existen referencias a `KvimRun`, `KvimTest`, `KvimBuild`, `KvimFormat`, `KvimLint`, pero esos comandos no están definidos actualmente en `core/commands.lua`.

### Módulo `connections`

- `:KvimConnections`
- `:KvimSshConnections`
- `:KvimSerialConnections`
- `:KvimConnectionsReload`
- `:KvimConnectionsGenerateKey`
- `:KvimConnectionsInstallKey`
- `:KvimConnectionsTestSsh`
- `:KvimConnectionSetActive`
- `:KvimSSHConnectionSetActive`
- `:KvimConnectionShowActive`
- `:KvimConnectionClearActive`
- `:KvimSSHRun [comando]`
- `:KvimSSHUploadCurrent`
- `:KvimSSHUploadPath [ruta_local]`
- `:KvimSSHDownloadPath [ruta_remota]`

### Módulo `git`

- `:KvimGit`
- `:KvimGitFile`
- `:KvimGitConfig`

### Módulo `svn`

- `:KvimLazySvn`
- `:KvimSvnInfo`
- `:KvimSvnStatus`

---

## Keymaps principales actuales

## Globales (config por defecto)

### Personales (`config.keymaps.mappings.personal`)

- `s` → guardar (`:w!`)
- `qq` → cerrar buffer/ventana (`:q!`)
- `qe` → salir de Neovim (`:qa!`)
- `<Esc>` → limpiar búsqueda (`:noh`)
- `da` → borrar todas las líneas (`:%delete _`)

### UI / navegación

- `<leader>e` → Neo-tree toggle
- `<leader>E` → Neo-tree focus
- `<leader>fe` → Neo-tree reveal
- `<leader>ec` → Neo-tree close
- `<leader>eg` → Neo-tree git status
- `<leader>eb` → Neo-tree buffers
- `<leader>y` / `<leader>Y` → Yazi / Yazi cwd
- `<leader>ff` → Telescope find_files
- `<leader>fg` → Telescope live_grep
- `<leader>fb` → Telescope buffers
- `<leader>fr` → Telescope oldfiles
- `<leader>fh` → Telescope help_tags

### Terminal core

- `<C-t>h` `<C-t>j` `<C-t>k` `<C-t>l` → abrir terminal (left/bottom/top/right)
- `<C-x>` (modo terminal) → salir a modo normal

### LSP (al adjuntar servidor)

- `gd`, `gD`, `gr`, `gi`, `K`
- `<leader>rn`, `<leader>ca`
- `<leader>lf`, `<leader>ld`
- `[d`, `]d`

## Keymaps de módulos

### Connections (prefix por defecto: `<leader>c`)

- `<leader>cc` → `:KvimConnections`
- `<leader>cs` → `:KvimSshConnections`
- `<leader>cu` → `:KvimSerialConnections`
- `<leader>cr` → `:KvimConnectionsReload`
- `<leader>ckg` → `:KvimConnectionsGenerateKey`
- `<leader>cki` → `:KvimConnectionsInstallKey`
- `<leader>ckt` → `:KvimConnectionsTestSsh`

### Git

- `<leader>g` → abrir LazyGit
- `<leader>f` → LazyGit current file
- `<leader>c` → LazyGit config

### SVN (prefix interno por defecto `<leader>s`)

- `<leader>sv` → LazySVN
- `<leader>si` → SVN info
- `<leader>ss` → SVN status

---

## Módulos actuales

### `git`
Integración con LazyGit mediante acciones/comandos/keymaps.
Incluye `plugins.lua` propio para declarar plugin(s) del módulo.

### `svn`
Comandos SVN y LazySVN en terminal flotante (`svn info`, `svn status`, `lazysvn`), con validaciones de binarios y de working copy SVN.

### `connections`
Gestión de conexiones SSH/serial:
- selección por picker;
- conexión activa en memoria;
- ejecución remota (`KvimSSHRun`);
- transferencias SCP (subida/bajada de archivos o directorios).

Archivo de configuración por defecto de conexiones:
`~/.config/nvim/lua/kvim/connections.lua`
(debe devolver una tabla Lua).

---

## Testing

Comando recomendado:

```bash
./scripts/test.sh
```

El script ejecuta Neovim headless con `tests/minimal_init.lua` y corre toda la suite en `tests/` usando `PlenaryBustedDirectory`, además de resumir:
- Success
- Failed
- Errors
- Total

Comando alternativo directo:

```bash
nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests" -c "qa!"
```

---

## Licencia

MIT
