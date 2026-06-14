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

### Ejemplo de instalación manual

```bash
git clone https://github.com/kodvmv/kvim.git ~/kvim
mkdir -p ~/.config/kvim
cp -r ~/kvim/nvim/* ~/.config/kvim/
NVIM_APPNAME=kvim nvim
```

El instalador intenta preinstalar los plugins de `lazy.nvim` durante la instalación.
Si esa fase falla, KVIM seguirá bootstrappeando plugins en el primer arranque.

> El contrato del instalador Linux vive en `package/linux/install.sh`.

Instalador Windows v1 disponible en:

```text
package/windows/install.ps1
package/windows/uninstall.ps1
```

En Windows, la implementación real del instalador/desinstalador vive ahora en PowerShell:

- `package/windows/install.ps1`
- `package/windows/uninstall.ps1`

Este entrypoint Windows actual hace:

1. garantiza `nvim >= 0.10.0` usando `winget` si falta o es demasiado antiguo
2. garantiza `node` y `npm` usando `winget` si faltan
3. verifica `git`
4. detecta `neovide` como opcional e intenta instalarlo automáticamente si falta
5. copia la configuración `nvim/`
6. genera `local.lua`
7. genera `kvim.bat`
8. instala `FiraCode Nerd Font Mono` globalmente en Windows si tiene permisos suficientes
9. crea un perfil específico `KVIM` en Windows Terminal
10. añade `%LOCALAPPDATA%\kvim\bin` al `PATH` de usuario
11. crea acceso directo en el menú inicio del usuario
12. copia el icono de KVIM
13. escribe `install-state`

Importante:

- `%LOCALAPPDATA%\kvim` no se crea al principio, sino después de validar dependencias obligatorias.
- Si `winget` instala Neovim o Node.js pero el binario todavía no queda usable en la sesión actual, el instalador aborta antes de copiar KVIM.
- En ese caso puedes ver el paquete como instalado por `winget` y aun así no tener todavía launcher, config ni `install-state` de KVIM.

En Windows, `kvim --gui` intenta usar `neovide` y, si no está disponible o falla al arrancar, hace fallback a terminal con `nvim`.

Fuentes actuales:

- KVIM configura `neovide` para usar `FiraCode Nerd Font Mono` tanto en Windows como en Linux.
- En Linux, el instalador instala esa familia para el usuario actual y configura `foot` para usarla.
- En Windows, el instalador intenta instalar esa familia globalmente en el sistema y crea un perfil específico `KVIM` en Windows Terminal con esa fuente.
- En Windows, si `neovide` falta, el instalador intenta instalarlo con `winget`.
- En Linux, si `neovide` falta, el instalador intenta instalarlo automáticamente solo en Arch Linux.
- No existe un mecanismo universal para cambiar la fuente solo para el proceso `kvim` en cualquier terminal; la integración TUI actual es específica para `foot` y `Windows Terminal`.

Diagnóstico recomendado si falla la instalación en Windows:

1. revisa la salida con prefijos `[kvim-windows-installer]`
2. comprueba el último paso mostrado con `step:<nombre-del-paso>`
3. revisa `%LOCALAPPDATA%\kvim\logs\install.log` si existe
4. si el fallo ocurrió justo después de `winget`, abre una terminal nueva y vuelve a ejecutar `package\windows\install.ps1`

Además, el uninstall Windows v1 retirará `Neovim`, `Node.js` y `neovide` solo si `install-state` indica que fueron instalados por KVIM.
También retirará las fuentes gestionadas por KVIM y el perfil específico `KVIM` de Windows Terminal cuando el estado indique que fueron configurados por KVIM.

Todavía no cubre:

1. instalación automática de dependencias por módulo
2. accesos directos de Windows más avanzados que el menú inicio
3. integración avanzada de uninstall fuera de `%LOCALAPPDATA%\kvim`

En la fase actual, ese script ya puede:

1. preparar `~/.config/kvim`
2. copiar el contenido de `nvim/`
3. generar `~/.config/kvim/lua/kvim/local.lua`
4. seleccionar módulos básicos para la instalación
5. verificar dependencias requeridas y advertir dependencias opcionales por módulo
6. generar `~/.local/bin/kvim` para ejecutar KVIM en terminal
7. soportar `kvim --gui` para abrir KVIM con `neovide`
8. generar `~/.local/share/applications/kvim.desktop`
9. instalar `FiraCode Nerd Font Mono` para el usuario actual
10. configurar `foot` para usar esa familia
11. intentar instalar `neovide` automáticamente en Arch Linux si falta
12. advertir si `~/.local/bin` no está en `PATH` y ofrecer añadirlo al shell del usuario

En Arch Linux instala por defecto las dependencias soportadas de los módulos seleccionados.

Si quieres omitir ese comportamiento:

```bash
bash package/linux/install.sh --skip-optional-deps
```

También puedes forzarlo explícitamente con:

```bash
bash package/linux/install.sh --install-optional-deps
```

Actualmente:

1. `lazygit` se instala con `pacman`
2. `subversion` se instala con `pacman`
3. `openssh` y `picocom` se instalan con `pacman` cuando se habilita `connections`
4. `lazysvn` se descarga como binario release a `~/.local/bin/lazysvn`

Desinstalación:

```bash
bash package/linux/uninstall.sh
bash package/linux/uninstall.sh --purge --yes
```

En Windows, el uninstall v1 se ejecuta directamente sin confirmación interactiva:

```powershell
powershell -ExecutionPolicy Bypass -File package\windows\uninstall.ps1
```

Notas:

1. el desinstalador elimina launcher, desktop entry y estado de KVIM en rutas de usuario
2. `~/.config/kvim` se elimina por defecto como parte de la desinstalación gestionada
3. en Windows, `Neovim` y `Node.js` se desinstalan automáticamente solo si `install-state` indica que los instaló KVIM
4. en Windows, `neovide` se desinstala automáticamente solo si `install-state` indica que lo instaló KVIM
5. en Windows, las fuentes globales gestionadas por KVIM y el perfil `KVIM` de Windows Terminal se retiran si `install-state` indica que fueron configurados por KVIM
6. en Linux, las fuentes de usuario de KVIM y la inclusión gestionada de `foot` se retiran si `install-state` indica que fueron configuradas por KVIM
7. en Linux, `neovide` se desinstala automáticamente solo si `install-state` indica que lo instaló KVIM
8. `lazygit` se desinstala automáticamente si `install-state` indica que lo instaló KVIM
9. `lazysvn` se elimina si `install-state` indica que lo instaló KVIM o si se usa `--remove-lazysvn`
10. el icono del escritorio se instala en `~/.local/share/icons/hicolor/256x256/apps/kvim.png`
11. el instalador registra estado en `~/.local/share/kvim/install-state`

Uso del launcher:

```bash
kvim
kvim --gui
kvim file.lua
kvim --gui file.lua
```

Diagnóstico recomendado tras instalar:

```vim
:checkhealth kvim
```

### Override local de instalación

KVIM puede cargar un archivo opcional de override local en:

```text
~/.config/kvim/lua/kvim/local.lua
```

Ese archivo permite personalizar una instalación sin modificar los defaults del repo.
La precedencia de configuración es:

1. defaults de `kvim.config`
2. override local `kvim.local`
3. `opts` pasados a `require("kvim").setup(...)`

Ejemplo mínimo para controlar módulos:

```lua
return {
    modules = {
        workspaces = { enabled = true },
        git = { enabled = false },
        svn = { enabled = false },
        connections = { enabled = false },
    },
}
```

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
`~/.config/kvim/lua/kvim/connections.lua`
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
