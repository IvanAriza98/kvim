<p align="center">
  <img src="assets/kvim-logo.png" alt="KVIM logo" width="140" />
</p>

<h1 align="center">KVIM</h1>

<p align="center">
  IDE modular sobre <strong>Neovim + Lua</strong>, con arquitectura por core + módulos,
  una base de UI moderna y herramientas reales para workspaces, Git, SVN y conexiones remotas.
</p>

<p align="center">
  UI cuidada · LSP · Command palette · Telescope · Neo-tree · Yazi · Workspaces · Git · SVN · Connections
</p>

---

## ¿Qué es KVIM?

KVIM es una distribución/configuración modular de Neovim construida alrededor de:

- un **core pequeño** con comandos, keymaps, acciones y utilidades compartidas;
- **módulos opcionales** para funcionalidades concretas;
- una capa de **plugins organizada por áreas** para `lazy.nvim`;
- una **suite de tests headless** para validar comportamiento real.

La idea no es acumular opciones sin criterio, sino ofrecer una base clara para:

- editar con una UI moderna;
- navegar rápido por archivos, buffers y búsquedas;
- trabajar con LSP, autocompletado y folds;
- abrir flujos de Git, SVN y conexiones remotas desde el editor;
- extender el sistema con módulos y acciones propias.

> Estado actual: KVIM ya es usable, tiene testing automatizado y una arquitectura modular real, pero sigue evolucionando y todavía hay algunas áreas en consolidación.

---

## Qué incluye hoy

### UI y experiencia base

- tema **Catppuccin**
- **Lualine**
- **Snacks dashboard** (`<leader>h`)
- **Neo-tree**
- **Yazi**
- **Telescope**
- **Noice** con command palette centrada para `:`
- **Dressing** para `vim.ui.select()` y `vim.ui.input()`
- **nvim-notify** para notificaciones
- **bufferline** con badges lógicas `Code` / `Term` en workspaces
- **Treesitter**
- folds con **nvim-ufo**
- **smartcolumn**
- **vim-visual-multi**
- **nvim-autopairs**
- soporte para **Neovide**

### Desarrollo

- LSP con:
  - `lua_ls`
  - `clangd`
  - `pyright`
  - `ts_ls`
  - `bashls`
  - `jsonls`
  - `yamlls`
- gestión de servidores con **mason.nvim** + **mason-lspconfig.nvim**
- autocompletado con **blink.cmp**

### Módulos actuales

- **workspaces**: workspaces persistentes, tabs lógicas `code` / `term`, recetas de terminal y restauración de sesión
- **git**: integración con LazyGit para repo y archivo actual
- **svn**: `svn info`, `svn status` y LazySVN
- **connections**: SSH, serie, gestión de claves SSH, conexión activa, transferencia de archivos y comando remoto

### Instaladores

- instalador y desinstalador para **Linux**
- instalador y desinstalador para **Windows**
- launcher `kvim`
- `kvim --gui` con fallback a terminal si `neovide` no está disponible

---

## Arquitectura resumida

```text
nvim/
├── init.lua
└── lua/kvim/
    ├── init.lua
    ├── config.lua
    ├── health.lua
    ├── core/
    │   ├── commands.lua
    │   ├── keymaps.lua
    │   ├── registry.lua
    │   ├── runner.lua
    │   ├── terminal.lua
    │   └── lsp/
    ├── modules/
    │   ├── workspaces/
    │   ├── git/
    │   ├── svn/
    │   └── connections/
    ├── plugins/
    │   ├── ui.lua
    │   ├── lsp.lua
    │   ├── dev.lua
    │   ├── editor.lua
    │   ├── dashboard.lua
    │   ├── navigation.lua
    │   └── completion.lua
    └── ui/
```

### Flujo real de carga

1. `nvim/init.lua` bootstrappea `lazy.nvim`.
2. Se importan plugins base desde `kvim.plugins.*`.
3. Cada módulo puede aportar también sus propios plugins.
4. `require("kvim").setup()`:
   - carga configuración global;
   - registra comandos core;
   - configura UI y tema;
   - configura LSP;
   - carga módulos habilitados;
   - registra acciones;
   - aplica keymaps globales.

---

## Instalación

KVIM vive dentro de la carpeta `nvim/` del repositorio y está pensado para ejecutarse con `NVIM_APPNAME=kvim` o mediante los launchers que generan los instaladores.

### Requisitos base

- **Git**
- **Neovim moderno**

> Recomendación práctica: usa una versión reciente de Neovim. Parte de la integración UI/LSP puede depender de APIs más nuevas que las mínimas históricas del proyecto.

### Dependencias recomendadas según uso

- `ripgrep` → búsquedas con Telescope
- `yazi` → gestor de archivos
- `lazygit` → módulo Git
- `svn` y `lazysvn` → módulo SVN
- `ssh`, `scp`, `ssh-keygen`, `ssh-copy-id` → módulo Connections
- `picocom` → conexiones serie
- `neovide` → modo GUI opcional

### Linux

#### Instalación rápida

```bash
git clone https://github.com/kodvmv/kvim.git
cd kvim
bash package/linux/install.sh --yes
kvim
```

#### Activar módulos extra durante la instalación

Por defecto, el instalador Linux genera `local.lua` con **workspaces habilitado** y **git/svn/connections deshabilitados** salvo que se indiquen.

```bash
bash package/linux/install.sh --yes \
  --enable-git \
  --enable-svn \
  --enable-connections
```

#### Notas del instalador Linux

- copia la configuración a `~/.config/kvim`
- genera `~/.config/kvim/lua/kvim/local.lua`
- crea launcher `~/.local/bin/kvim`
- soporta `kvim --gui` con fallback a terminal
- en Arch Linux puede instalar dependencias opcionales soportadas

```bash
bash package/linux/install.sh --yes --skip-optional-deps
```

### Windows

#### Instalación rápida

```powershell
git clone https://github.com/kodvmv/kvim.git
cd kvim
powershell -ExecutionPolicy Bypass -File package\windows\install.ps1 --yes
kvim
```

#### Activar módulos extra durante la instalación

```powershell
powershell -ExecutionPolicy Bypass -File package\windows\install.ps1 --yes --enable-git --enable-svn --enable-connections
```

#### Notas del instalador Windows

- copia la configuración a `%LOCALAPPDATA%\kvim`
- genera `local.lua`
- crea `kvim.bat`
- añade `%LOCALAPPDATA%\kvim\bin` al `PATH` de usuario
- crea acceso directo en el menú inicio
- intenta garantizar dependencias base y detecta `neovide` como opcional

### Instalación manual / desarrollo local

Si no quieres usar instalador, el flujo típico es:

1. clonar el repo;
2. hacer que Neovim cargue `nvim/` como appname/configuración;
3. arrancar KVIM con `NVIM_APPNAME=kvim` o equivalente;
4. revisar `:checkhealth kvim`.

---

## Primer arranque

Lanzadores soportados:

```bash
kvim
kvim --gui
kvim file.lua
kvim --gui file.lua
```

En Windows y Linux, `kvim --gui` intenta usar `neovide` y, si no está disponible o falla al arrancar, hace fallback a terminal con `nvim`.

Diagnóstico recomendado:

```vim
:checkhealth kvim
```

---

## Personalización local

KVIM soporta overrides locales en:

```text
~/.config/kvim/lua/kvim/local.lua
```

Precedencia real:

1. defaults de `kvim.config`
2. `kvim.local`
3. opciones pasadas a `require("kvim").setup(...)`

Ejemplo mínimo:

```lua
return {
    modules = {
        workspaces = { enabled = true },
        git = { enabled = true },
        svn = { enabled = false },
        connections = { enabled = false },
    },
}
```

> Importante: los **defaults del repo** y los **defaults del instalador** no son exactamente lo mismo. El instalador genera un `local.lua` más conservador por defecto.

---

## Comandos principales

### Core

- `:KvimModules`
- `:KvimAction <modulo> <accion>`

### Workspaces

- `:KvimWorkspaceCreate <name>`
- `:KvimWorkspaceSave [name]`
- `:KvimWorkspaceLoad <name>`
- `:KvimWorkspaceList`
- `:KvimWorkspaceDelete <name>`
- `:KvimWorkspaceCurrent`
- `:KvimWorkspaceClear`
- `:KvimWorkspaceNext`
- `:KvimWorkspacePrev`
- `:KvimWorkspaceTerminalAdd`
- `:KvimWorkspaceTerminalList`
- `:KvimWorkspaceTerminalRemove <name>`
- `:KvimWorkspaceTerminalRestore`
- `:KvimWorkspaceTermHome`
- `:KvimWorkspaceTabCode`
- `:KvimWorkspaceTabTerm`

### Git

- `:KvimGit`
- `:KvimGitFile`
- `:KvimGitConfig`

### SVN

- `:KvimLazySvn`
- `:KvimSvnInfo`
- `:KvimSvnStatus`

### Connections

- `:KvimConnections`
- `:KvimSshConnections`
- `:KvimSerialConnections`
- `:KvimConnectionsReload`
- `:KvimConnectionsReconnect <name>`
- `:KvimConnectionsList`
- `:KvimConnectionsAdd`
- `:KvimConnectionsDel [name]`
- `:KvimConnectionsGenerateKey`
- `:KvimConnectionsInstallKey`
- `:KvimConnectionsSetupSshKey`
- `:KvimConnectionsTestSsh`
- `:KvimConnectionSetActive`
- `:KvimSSHConnectionSetActive`
- `:KvimConnectionShowActive`
- `:KvimConnectionClearActive`
- `:KvimSSHRun [comando]`
- `:KvimSSHUploadCurrent`
- `:KvimSSHUploadPath [ruta_local]`
- `:KvimSSHDownloadPath [ruta_remota]`

---

## Keymaps destacados

### Globales

- `s` → guardar
- `qq` → cerrar buffer/ventana
- `qe` → salir
- `<Esc>` → limpiar búsqueda
- `da` → borrar todas las líneas del buffer

### Dashboard / navegación

- `<leader>h` → abrir dashboard
- `<leader>e` → Neo-tree toggle
- `<leader>E` → Neo-tree focus
- `<leader>fe` → Neo-tree reveal
- `<leader>ec` → Neo-tree close
- `<leader>eg` → Neo-tree git status
- `<leader>eb` → Neo-tree buffers
- `<leader>ff` → Telescope find files
- `<leader>fg` → Telescope live grep
- `<leader>fb` → Telescope buffers
- `<leader>fr` → archivos recientes
- `<leader>fh` → help tags
- `<leader>y` → Yazi
- `<leader>Y` → Yazi en cwd

### Terminal

- `<C-t>h` / `<C-t>j` / `<C-t>k` / `<C-t>l` → abrir terminal por posición
- `<C-x>` en terminal → volver a modo normal

### Workspaces y buffers

- `<leader>ws` → guardar workspace
- `<leader>wl` → listar workspaces
- `<leader>wc` → mostrar workspace actual
- `<leader>wx` → salir del workspace actual
- `<leader>wn` / `<leader>wp` → siguiente / anterior
- `<leader>wt` → listar recetas de terminal
- `<leader>wa` → añadir receta de terminal
- `<leader>wr` → restaurar terminales
- `<leader>wh` → ir al hub `Term`
- `<leader>1` → tab `Code`
- `<leader>2` → tab `Term`
- `[b` / `]b` → buffer anterior / siguiente dentro del rol actual
- `<Tab>` / `<S-Tab>` → ciclo rápido de buffers por rol

### Git

- `<leader>g` → LazyGit
- `<leader>f` → LazyGit del archivo actual

### SVN

- `<leader>sv` → LazySVN
- `<leader>si` → SVN info
- `<leader>ss` → SVN status

### Connections

- `<leader>cc` → picker general
- `<leader>cs` → picker SSH
- `<leader>cu` → picker serie
- `<leader>cr` → recargar config
- `<leader>cl` → listar conexiones
- `<leader>ca` → añadir conexión
- `<leader>cd` → borrar conexión

### LSP

- `gd` → definición
- `gD` → declaración
- `gr` → referencias
- `gi` → implementación
- `K` → hover / peek fold si aplica
- `<leader>rn` → rename
- `<leader>ca` → code action
- `<leader>lf` → format
- `<leader>ld` → diagnósticos de línea
- `[d` / `]d` → diagnóstico anterior / siguiente

### Folds

- `zR` → abrir todos los folds
- `zM` → cerrar todos los folds
- `zr` → abrir folds por niveles
- `zm` → cerrar folds por niveles

---

## Módulos principales

| Módulo | Estado | Qué hace |
|---|---|---|
| `workspaces` | usable / MVP ampliado | guarda y restaura workspaces, tabs lógicas `code`/`term`, bufferline por rol y recetas de terminal |
| `git` | usable | integra LazyGit para repo y archivo actual |
| `svn` | usable | abre LazySVN y ejecuta `svn info/status` en terminal flotante |
| `connections` | usable | SSH, serie, conexión activa, SCP, claves SSH y reconexión |

### Workspaces

- persiste workspaces con soporte de sesión;
- crea tabs lógicas `code` y `term`;
- separa buffers de edición y buffers terminales por rol;
- puede restaurar terminales reproducibles;
- se integra con `resession.nvim`;
- puede usar recetas SSH del módulo `connections`.

Persistencia real:

```text
stdpath("state")/kvim/workspaces
```

### Connections

- define conexiones del usuario en `~/.config/kvim/connections.lua`;
- soporta pickers para todas, SSH y serie;
- soporta conexión activa en memoria de sesión;
- permite generar/instalar/probar claves SSH;
- permite ejecutar comandos remotos y transferir archivos.

> KVIM migra automáticamente desde la ruta legacy si existe, pero la configuración real de usuario ya no debe vivir dentro del árbol versionado.

---

## Testing

KVIM incluye suite automatizada con:

- **Neovim headless**
- **plenary.nvim**
- **busted**

### Comando recomendado

```bash
./scripts/test.sh
```

### Comando alternativo

```bash
nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests" -c "qa!"
```

Cobertura actual visible en el árbol de tests:

- `tests/core/*`
- `tests/core/lsp/*`
- `tests/ui/*`
- `tests/workspaces/*`
- `tests/connections/*`

---

## Estado actual y limitaciones conocidas

### Qué está sólido ya

- arquitectura modular sobre Lua
- bootstrap con `lazy.nvim`
- UI base y navegación moderna
- LSP y autocompletado
- módulos `workspaces`, `git`, `svn` y `connections`
- instaladores Linux/Windows
- testing automatizado en headless

### Qué conviene saber hoy

- KVIM está activo, pero no completamente cerrado a nivel de APIs internas;
- parte de la experiencia está más madura en Linux/terminal;
- el README intenta reflejar el estado real actual, no una hoja de ruta idealizada.

### Limitaciones visibles actuales

- en `core/keymaps.lua` existen mappings hacia `KvimRun`, `KvimTest`, `KvimBuild`, `KvimFormat` y `KvimLint`, pero esos comandos no están definidos actualmente en `core/commands.lua`;
- `config.lsp.servers` no representa todavía toda la realidad del cableado interno del LSP;
- hay defaults del repo que difieren de lo que los instaladores generan en `local.lua`;
- la documentación secundaria de algunos módulos puede ir algo por detrás del código real.

---

## Documentación relacionada

- `CHANGELOG.md`
- `AGENTS.md`
- `nvim/lua/kvim/plugins/README.md`
- `nvim/lua/kvim/modules/workspaces/README.md`
- `nvim/lua/kvim/modules/git/README.md`
- `nvim/lua/kvim/modules/svn/README.md`
- `nvim/lua/kvim/modules/connections/README.md`
- `docs/specs/0001-linux-installer.md`
- `docs/specs/0002-windows-installer.md`
- `docs/specs/0004-term-tab-code-explorer-separation.md`

---

## Contribuir

Las contribuciones son bienvenidas, especialmente en:

- documentación de usuario
- screenshots reales
- endurecimiento de módulos
- mejoras de DX y keymaps
- cobertura de tests
- pulido de instaladores

### Flujo recomendado

1. revisa el estado real del módulo afectado
2. evita documentar features no implementadas
3. si cambias comportamiento público, actualiza README o README del módulo
4. ejecuta la suite de tests antes de proponer cambios

---

## TL;DR

KVIM ya ofrece una base seria para usar Neovim como IDE modular, con una combinación real de:

- **UI moderna**
- **command palette y selectores mejorados**
- **workspaces con tabs lógicas `Code` / `Term`**
- **Git / SVN / conexiones remotas**
- **testing headless**
- **arquitectura extensible**

Si buscas una base modular sobre Neovim con identidad propia y no solo una colección de plugins, KVIM ya tiene una dirección técnica bastante clara.

---
