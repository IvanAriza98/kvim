# KVIM Reference

Referencia rápida de comandos y keymaps públicos de KVIM en el estado actual del repositorio.

---

## 1. Comandos

### 1.1. Core

- `:KvimModules`
- `:KvimAction <module> <action>`

> Nota: en `core/keymaps.lua` existen referencias a `KvimRun`, `KvimTest`, `KvimBuild`, `KvimFormat` y `KvimLint`, pero esos comandos no están definidos actualmente en `core/commands.lua`.

### 1.2. Workspaces

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

### 1.3. Git

- `:KvimGit`
- `:KvimGitFile`
- `:KvimGitConfig`

### 1.4. SVN

- `:KvimLazySvn`
- `:KvimSvnInfo`
- `:KvimSvnStatus`

### 1.5. Connections

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

## 2. Keymaps

### 2.1. Personales / globales

- `s` → guardar (`:w!`)
- `qq` → cerrar buffer/ventana (`:q!`)
- `qe` → salir de Neovim (`:qa!`)
- `<Esc>` → limpiar búsqueda (`:noh`)
- `da` → borrar todas las líneas del buffer

### 2.2. Core

- `<leader>km` → `:KvimModules`
- `<leader>ka` → `:KvimAction`

> Existen mappings preparados para `KvimRun`, `KvimTest`, `KvimBuild`, `KvimFormat` y `KvimLint`, pero no tienen comando real asociado en el estado actual.

### 2.3. Exploración y búsqueda

#### Neo-tree

- `<leader>e` → abrir/cerrar explorador
- `<leader>E` → enfocar explorador
- `<leader>fe` → revelar archivo actual
- `<leader>ec` → cerrar explorador
- `<leader>eg` → vista de estado Git
- `<leader>eb` → vista de buffers

#### Yazi

- `<leader>y` → `Yazi`
- `<leader>Y` → `Yazi cwd`

#### Telescope

- `<leader>ff` → buscar archivos
- `<leader>fg` → búsqueda por texto
- `<leader>fb` → listar buffers
- `<leader>fr` → archivos recientes
- `<leader>fh` → ayuda/tags

### 2.4. Terminal

- `<C-x>` → salir de terminal mode
- `<C-t>l` → abrir terminal a la derecha
- `<C-t>h` → abrir terminal a la izquierda
- `<C-t>k` → abrir terminal arriba
- `<C-t>j` → abrir terminal abajo

### 2.5. Workspaces

- `<leader>ws` → guardar workspace actual
- `<leader>wl` → listar workspaces
- `<leader>wc` → mostrar workspace actual
- `<leader>wx` → limpiar workspace actual
- `<leader>wn` → siguiente workspace
- `<leader>wp` → workspace anterior
- `<leader>wt` → listar recetas de terminal
- `<leader>wa` → añadir receta de terminal
- `<leader>wr` → restaurar terminales del workspace
- `<leader>wh` → ir al hub `Term`
- `<leader>1` → ir a tab `Code`
- `<leader>2` → ir a tab `Term`
- `]b` → siguiente buffer según rol
- `[b` → buffer anterior según rol
- `<Tab>` → siguiente buffer rápido
- `<S-Tab>` → buffer anterior rápido

### 2.6. Git

- `<leader>g` → abrir LazyGit
- `<leader>f` → abrir LazyGit sobre archivo actual

### 2.7. SVN

- `<leader>sv` → abrir LazySVN
- `<leader>si` → `svn info`
- `<leader>ss` → `svn status`

### 2.8. Connections

- `<leader>cc` → picker general de conexiones
- `<leader>cs` → picker SSH
- `<leader>cu` → picker serie
- `<leader>cr` → recargar configuración
- `<leader>cl` → listar conexiones
- `<leader>ca` → añadir conexión
- `<leader>cd` → borrar conexión
- `<leader>ckg` → generar clave SSH
- `<leader>cki` → instalar clave SSH
- `<leader>cks` → setup completo de clave SSH
- `<leader>ckt` → probar conexión SSH
- `<leader>cA` → mostrar conexión activa

### 2.9. LSP

- `gd` → ir a definición
- `gD` → ir a declaración
- `gr` → referencias
- `gi` → implementación
- `K` → hover/documentación
- `<leader>rn` → renombrar
- `<leader>ca` → code action
- `<leader>lf` → formatear buffer
- `<leader>ld` → diagnósticos de línea
- `[d` → diagnóstico anterior
- `]d` → diagnóstico siguiente

### 2.10. Folds

- `zR` → abrir todos los folds
- `zM` → cerrar todos los folds
- `zr` → abrir folds parcialmente
- `zm` → cerrar folds parcialmente

---

## 3. Nota final

Esta referencia resume el estado real del repositorio. Si KVIM evoluciona con nuevos módulos, comandos o keymaps, este fichero debería actualizarse junto con `README.md` y `TFM.md`.
