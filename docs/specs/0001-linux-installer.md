# 0001 - Linux Installer

## Objetivo

Definir un instalador Linux para KVIM que prepare un perfil aislado de Neovim usando `NVIM_APPNAME=kvim`, sin sobrescribir la configuración normal del usuario en `~/.config/nvim`.

La intención original se mantiene: instalar KVIM en rutas de usuario, generar un launcher propio y dejar el entorno listo para arrancar tanto en terminal como en GUI con Neovide.

## Alcance

Esta spec cubre únicamente el instalador Linux actual ubicado en:

```text
package/linux/install.sh
```

No cubre:

- instalador Windows;
- AppImage;
- paquetes `.deb`, `.rpm` o `.pkg.tar.zst`;
- actualizador automático;
- desinstalador completo;
- gestión avanzada de versiones;
- instalación de toolchains complejas de lenguajes.

## Estado actual

El instalador ya está implementado y funcional para una instalación local por usuario, y ahora se complementa con un desinstalador Linux específico.

Actualmente hace lo siguiente:

- verifica dependencias requeridas (`nvim`, `git`);
- exige `Neovim >= 0.10.0`;
- advierte dependencias opcionales según módulos habilitados;
- copia `nvim/` a `~/.config/kvim`;
- genera `~/.config/kvim/lua/kvim/local.lua` con selección local de módulos;
- genera el launcher `~/.local/bin/kvim`;
- soporta `kvim --gui` usando `neovide`;
- genera `~/.local/share/applications/kvim.desktop`;
- instala `FiraCode Nerd Font Mono` en `~/.local/share/fonts/kvim`;
- configura `foot` para usar esa familia mediante un include gestionado;
- intenta instalar `neovide` automáticamente en Arch Linux si falta;
- comprueba si `~/.local/bin` está en `PATH` y puede añadirlo al shell del usuario;
- intenta preinstalar plugins de `lazy.nvim` en modo headless;
- instala por defecto en Arch Linux las dependencias soportadas de los módulos seleccionados, salvo que se desactive explícitamente;
- registra estado de instalación en `~/.local/share/kvim/install-state`;
- expone un desinstalador en `package/linux/uninstall.sh`.

Si la precarga headless de plugins falla, KVIM sigue bootstrappeando `lazy.nvim` en el primer arranque desde `nvim/init.lua`.

## Rutas utilizadas

El instalador usa estas rutas:

```text
~/.config/kvim
~/.config/kvim/lua/kvim/local.lua
~/.local/share/kvim
~/.local/share/kvim/install-state
~/.local/bin/kvim
~/.local/bin/lazysvn
~/.local/share/icons/hicolor/256x256/apps/kvim.png
~/.local/share/applications/kvim.desktop
~/.local/share/fonts/kvim
~/.config/foot/foot.ini
~/.config/foot/kvim.ini
```

Notas:

- `~/.config/kvim` contiene la copia del árbol `nvim/` del repositorio.
- `~/.local/share/kvim` se prepara, pero en el estado actual no recibe contenido adicional del instalador.
- `~/.config/nvim` no se toca.

## Desinstalación

El desinstalador actual vive en:

```text
package/linux/uninstall.sh
```

Uso básico:

```bash
bash package/linux/uninstall.sh
```

Purga completa sin preguntas:

```bash
bash package/linux/uninstall.sh --purge --yes
```

Flags públicos actuales:

- `--yes`
- `--purge`
- `--remove-path`
- `--remove-lazysvn`
- `-h`, `--help`

Comportamiento actual:

- elimina `~/.local/bin/kvim`;
- elimina `~/.local/share/applications/kvim.desktop`;
- elimina `~/.local/share/kvim`;
- elimina `~/.config/kvim` por defecto;
- elimina `~/.local/share/icons/hicolor/256x256/apps/kvim.png`;
- elimina `~/.local/share/fonts/kvim` si fue gestionado por KVIM;
- elimina la inclusión gestionada de `foot` si fue gestionada por KVIM;
- desinstala `neovide` si el manifiesto indica que KVIM lo instaló;
- quita el bloque de `PATH` si el manifiesto indica que KVIM lo añadió;
- desinstala `lazygit` si el manifiesto indica que KVIM lo instaló;
- puede eliminar `~/.local/bin/lazysvn` si fue instalado por KVIM o si se fuerza con `--remove-lazysvn`;
- usa `install-state` como fuente de verdad cuando existe.

## Interfaz actual del instalador

Uso actual:

```bash
bash package/linux/install.sh [options]
```

Opciones públicas actuales:

- `--yes`
- `--enable-workspaces`
- `--disable-workspaces`
- `--enable-git`
- `--disable-git`
- `--enable-svn`
- `--disable-svn`
- `--enable-connections`
- `--disable-connections`
- `--install-optional-deps`
- `--skip-optional-deps`
- `-h`, `--help`

Valores por defecto actuales:

- `workspaces = true`
- `git = false`
- `svn = false`
- `connections = false`

Si no se usa `--yes` y hay TTY interactivo, el script pregunta qué módulos habilitar.
Con `--yes` usa los valores por defecto o los fijados explícitamente por flags.

## Flujo real de instalación

Orden real del script:

1. parsea argumentos;
2. resuelve selección de módulos;
3. valida dependencias requeridas y opcionales;
4. crea directorios de usuario;
5. instala dependencias de módulos soportadas por defecto en Arch Linux, salvo que se desactive;
6. copia la configuración KVIM a `~/.config/kvim`;
7. escribe `local.lua`;
8. intenta preinstalar plugins de `lazy.nvim` en modo headless;
9. instala fuentes de usuario para KVIM;
10. configura `foot` para usar esa familia;
11. intenta instalar `neovide` automáticamente en Arch Linux si falta;
12. escribe el launcher `kvim`;
13. escribe el `desktop entry`;
14. comprueba `PATH` y ofrece añadir `~/.local/bin`;
15. escribe `install-state`;
16. imprime resumen final.

## Dependencias

### Requeridas

- `nvim`
- `git`

Además, `nvim` debe cumplir `>= 0.10.0`.

### Opcionales generales

- `neovide`: recomendado para `kvim --gui` y para el lanzador de escritorio; en Arch Linux el instalador intenta provisionarlo automáticamente.
- `fc-cache`: recomendado para refrescar la caché de fuentes tras instalar `FiraCode Nerd Font Mono`.

### Opcionales por módulo

#### Git

- `lazygit`

#### SVN

- `svn`
- `lazysvn`

#### Connections

- `ssh`
- `scp`
- `ssh-keygen`
- `ssh-copy-id`
- `picocom`

### Dependencias extra para `--install-optional-deps`

La instalación automática de dependencias por módulos solo está soportada en Arch Linux.

Para Git:

- `sudo`
- `pacman`

Para SVN:

- `sudo`
- `pacman`
- `subversion`
- `curl`
- `tar`
- `find`

Para Connections:

- `sudo`
- `pacman`
- `openssh`
- `picocom`

## Soporte actual de instalación opcional en Arch Linux

Comportamiento actual:

- si el módulo Git está habilitado, el instalador instala `lazygit` por defecto;
- si el módulo SVN está habilitado, el instalador instala `subversion` y luego `lazysvn`;
- si el módulo Connections está habilitado, el instalador instala `openssh` y `picocom`;
- si se quiere omitir esa fase, puede usarse `--skip-optional-deps`.

También se puede invocar explícitamente con:

```bash
bash package/linux/install.sh --install-optional-deps
```

El flag `--install-optional-deps` se mantiene por compatibilidad y fuerza el comportamiento por defecto actual.

El soporte actual de arquitectura para LazySVN release está limitado a:

- `x86_64` -> `amd64`
- `aarch64` / `arm64` -> `arm64`

## Comportamiento real del launcher `kvim`

El launcher generado en `~/.local/bin/kvim`:

- exporta siempre `NVIM_APPNAME=kvim`;
- ejecuta `nvim` por defecto;
- acepta `--gui` para ejecutar `neovide`;
- acepta `--help`;
- reenvía el resto de argumentos al binario final.

Ejemplos válidos:

```bash
kvim
kvim file.lua
kvim --gui
kvim --gui file.lua
```

Si se usa `kvim --gui` y `neovide` no existe en `PATH`, el launcher termina con error.

## Fuentes y terminal soportado

La instalación Linux actual usa como familia común:

- `FiraCode Nerd Font Mono`

Comportamiento actual:

- las fuentes se copian a `~/.local/share/fonts/kvim`;
- si existe `fc-cache`, el instalador intenta refrescar la caché de fuentes;
- `neovide` puede usar esa familia a través de la configuración Lua de KVIM;
- `foot` se configura mediante `~/.config/foot/kvim.ini` y una línea `include=` gestionada en `~/.config/foot/foot.ini`.
- si `neovide` falta y el sistema es Arch Linux, el instalador intenta instalarlo con `pacman`;
- si la instalación de `neovide` falla, KVIM sigue instalándose sin GUI.

Límite importante:

- no existe un mecanismo universal para cambiar la fuente solo para el proceso `kvim` en cualquier terminal TUI;
- la integración actual de terminal está implementada específicamente para `foot`.

## Uso de `NVIM_APPNAME=kvim`

La ejecución aislada de KVIM depende de `NVIM_APPNAME=kvim`.

Consecuencias reales:

- `vim.fn.stdpath("config")` apunta a `~/.config/kvim` cuando se arranca mediante el launcher;
- `lazy.nvim` se bootstrappea dentro del perfil `kvim` en lugar del perfil normal de Neovim;
- la comprobación `:checkhealth kvim` avisa si `NVIM_APPNAME` no es `kvim`.

## Configuración local generada

El instalador escribe:

```text
~/.config/kvim/lua/kvim/local.lua
```

Ese archivo devuelve una tabla Lua con el estado de módulos habilitados para esa instalación.

Ejemplo real generado:

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

Precedencia real de configuración en KVIM:

1. defaults de `kvim.config`;
2. override local cargado desde `kvim.local`;
3. `opts` pasados a `require("kvim").setup(...)`.

## Integración de escritorio

El instalador genera:

```text
~/.local/share/applications/kvim.desktop
```

Contenido funcional actual:

- `Type=Application`
- `Name=KVIM`
- `Exec=~/.local/bin/kvim --gui %F`
- `Icon=kvim`
- `Terminal=false`
- `Categories=Development;IDE;TextEditor;`

Comportamiento real:

- el acceso de escritorio abre KVIM en modo GUI, no terminal;
- depende del launcher `kvim`;
- si `neovide` no está disponible, el launcher fallará;
- no se define `Icon` en el estado actual.

## PATH y shell local

El instalador comprueba si `~/.local/bin` ya está en `PATH`.

Si no lo está:

- muestra una advertencia;
- ofrece añadirlo automáticamente al RC del shell actual.

Resolución actual de archivo RC:

- `zsh` -> `~/.zshrc`
- `bash` -> `~/.bashrc`
- `fish` -> `~/.config/fish/config.fish`
- resto -> `~/.profile`

Línea añadida:

- shells POSIX: `export PATH="$HOME/.local/bin:$PATH"`
- fish: `set -gx PATH "$HOME/.local/bin" $PATH`

El desinstalador puede eliminar ese bloque cuando:

- el manifiesto indica que KVIM actualizó el `PATH`;
- se usa `--remove-path`;
- o se ejecuta `--purge`.

## Checks de salud y validación posterior

El instalador no ejecuta `:checkhealth kvim`, pero KVIM ya expone un health check general en runtime.

Validación recomendada tras instalar:

```vim
:checkhealth kvim
```

Ese check revisa actualmente:

- `NVIM_APPNAME`;
- `git`;
- `neovide`;
- dependencias de módulos habilitados;
- health adicional del módulo `connections` si está activo.

## Manifiesto de instalación

El instalador escribe un manifiesto shell-friendly en:

```text
~/.local/share/kvim/install-state
```

Ese archivo registra el estado mínimo necesario para desinstalar con seguridad:

- rutas instaladas;
- ruta del icono instalado;
- estado de módulos seleccionados;
- si se instaló `lazygit` desde KVIM;
- si se instaló `lazysvn` desde KVIM;
- si la precarga de plugins `lazy.nvim` se completó;
- si se modificó `PATH`;
- qué archivo RC fue tocado.

El manifiesto se usa para decidir qué artefactos y dependencias puede retirar el desinstalador sin borrar cosas preexistentes del usuario.

## Limitaciones actuales

- no hay soporte para Windows ni empaquetado distributivo;
- `lazy.nvim` no se instala durante el script; se bootstrappea al primer arranque;
- `~/.config/kvim` se copia directamente desde el repo y puede sobrescribir archivos previos de ese perfil;
- `~/.local/share/kvim` se crea pero no tiene uso funcional relevante dentro del instalador actual;
- `--install-optional-deps` solo soporta Arch Linux;
- la instalación automática de opcionales cubre `lazygit`, `subversion`, `openssh`, `picocom` y `lazysvn`, no el resto de binarios opcionales;
- el launcher solo entiende explícitamente `--gui` y `--help`;
- el desktop entry depende de `neovide` y no define icono;
- no hay mecanismo de actualización incremental del perfil instalado;
- si falta `install-state`, el uninstall entra en modo best-effort y no puede garantizar la retirada de todas las dependencias instaladas previamente por KVIM.

## Changelog interno de la spec

### Implementado hasta la fecha

- adopción de `NVIM_APPNAME=kvim` como base del perfil aislado;
- generación de `~/.config/kvim/lua/kvim/local.lua` para overrides locales de instalación;
- creación del launcher `~/.local/bin/kvim`;
- soporte de `kvim --gui` para arrancar con `neovide`;
- generación de `~/.local/share/applications/kvim.desktop`;
- checks de dependencias requeridas y opcionales por módulo;
- validación de versión mínima de Neovim (`0.10.0`);
- advertencia y ayuda para añadir `~/.local/bin` al `PATH`;
- instalación automática por defecto en Arch Linux de dependencias por módulo seleccionado;
- instalación en Arch Linux de `lazygit`, `subversion`, `openssh` y `picocom` vía `pacman`;
- instalación en Arch Linux de `lazysvn` descargando release binaria;
- soporte de detección de arquitectura para LazySVN (`amd64`, `arm64`);
- instalación del icono de escritorio desde `assets/kvim-logo.png` al tema `hicolor` del usuario;
- health check general de KVIM disponible con `:checkhealth kvim`;
- precarga headless de plugins de `lazy.nvim` durante la instalación;
- manifiesto de instalación en `~/.local/share/kvim/install-state`;
- desinstalador `package/linux/uninstall.sh` con eliminación por defecto de todo lo gestionado por KVIM según `install-state`.

### Correcciones y ajustes relevantes ya reflejados

- la verificación de `lazy.nvim` ya no implica instalación en el script: el runtime lo bootstrappea en el primer inicio;
- la instalación ahora intenta dejar los plugins de `lazy.nvim` preparados antes del primer uso interactivo;
- la configuración local ya no depende de editar defaults del repo, sino del archivo `local.lua`;
- el launcher `kvim` es el punto de entrada recomendado para asegurar `NVIM_APPNAME=kvim`;
- el launcher ejecuta KVIM en terminal por defecto y reserva `kvim --gui` para Neovide;
- el flujo GUI real usa `kvim --gui`, no un binario GUI separado de KVIM;
- la integración de escritorio real se hace mediante `kvim.desktop` apuntando al launcher;
- el instalador ya contempla warnings de `PATH` para que `kvim` y `lazysvn` sean resolubles en shells nuevos;
- la selección de módulos en Arch Linux ahora implica instalación automática de dependencias salvo `--skip-optional-deps`;
- la validación posterior recomendada ya incluye el health check general del proyecto;
- el uninstall usa un manifiesto para retirar por defecto todo lo instalado por KVIM, incluyendo `lazygit` cuando procede.

## Criterio de consistencia

Esta spec debe mantenerse sincronizada con:

- `package/linux/install.sh`
- `README.md`
- `nvim/init.lua`
- `nvim/lua/kvim/config.lua`
- `nvim/lua/kvim/health.lua`

Si cambian el launcher, rutas públicas, módulos instalables, checks, integración de escritorio o comportamiento de `local.lua`, esta spec debe actualizarse.
