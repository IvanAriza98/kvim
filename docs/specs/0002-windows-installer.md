# 0002 - Windows Installer

## Objetivo

Definir el comportamiento real del instalador y desinstalador Windows actuales de KVIM tras la migración a PowerShell, manteniendo un perfil aislado de Neovim basado en `NVIM_APPNAME=kvim` y sin tocar el perfil normal del usuario.

La intención del flujo Windows actual es:

- preparar una instalación por usuario en `%LOCALAPPDATA%\kvim`;
- generar un launcher `kvim`;
- añadir ese launcher al `PATH` de usuario;
- crear un acceso directo en el menú inicio;
- registrar estado suficiente para una desinstalación gestionada.

## Alcance

Esta spec cubre los scripts actuales:

```text
package/windows/install.ps1
package/windows/uninstall.ps1
```

No cubre:

- MSI;
- instalador con UI gráfica;
- paquetes Chocolatey, Scoop o MSIX;
- actualización automática;
- instalación de dependencias opcionales por módulo;
- accesos directos de escritorio o asociación de archivos;
- limpieza avanzada fuera de las rutas gestionadas por `%LOCALAPPDATA%\kvim`.

## Estado actual

El instalador Windows ya está implementado y funcional como script PowerShell por usuario.

Actualmente hace lo siguiente:

- garantiza `Neovim >= 0.10.0`;
- instala o actualiza Neovim con `winget` si hace falta;
- garantiza `node` y `npm`;
- instala Node.js LTS con `winget` si hace falta;
- exige `git`;
- detecta `neovide` como opcional;
- crea `%LOCALAPPDATA%\kvim`;
- copia `nvim/` dentro de `%LOCALAPPDATA%\kvim`;
- genera `%LOCALAPPDATA%\kvim\lua\kvim\local.lua`;
- copia `assets/kvim-logo.png` a `%LOCALAPPDATA%\kvim\assets\kvim-logo.png` si existe;
- genera el launcher `%LOCALAPPDATA%\kvim\bin\kvim.bat`;
- añade `%LOCALAPPDATA%\kvim\bin` al `PATH` de usuario;
- crea `KVIM.lnk` en el menú inicio del usuario;
- escribe un manifiesto `install-state`;
- escribe logs de progreso en `%LOCALAPPDATA%\kvim\logs\install.log`.

El desinstalador actual:

- carga `install-state` si existe;
- elimina launcher, shortcut, icono, estado y directorio raíz `%LOCALAPPDATA%\kvim`;
- quita `%LOCALAPPDATA%\kvim\bin` del `PATH` de usuario si el estado indica que KVIM lo añadió;
- desinstala `Neovim` y `Node.js LTS` con `winget` solo si `install-state` indica que KVIM los instaló.

## Rutas utilizadas

El flujo Windows usa estas rutas:

```text
%LOCALAPPDATA%\kvim
%LOCALAPPDATA%\kvim\bin
%LOCALAPPDATA%\kvim\bin\kvim.bat
%LOCALAPPDATA%\kvim\assets
%LOCALAPPDATA%\kvim\assets\kvim-logo.png
%LOCALAPPDATA%\kvim\logs
%LOCALAPPDATA%\kvim\logs\install.log
%LOCALAPPDATA%\kvim\lua\kvim\local.lua
%LOCALAPPDATA%\kvim\install-state
%APPDATA%\Microsoft\Windows\Start Menu\Programs\KVIM.lnk
%TEMP%\kvim-uninstall.log
```

Notas:

- `%LOCALAPPDATA%\kvim` actúa como raíz del perfil instalado y también como directorio de estado.
- no se usa `%USERPROFILE%\.config\kvim`;
- no se crea una ruta separada equivalente a `~/.local/share/kvim`;
- el shortcut se crea en el menú inicio del usuario, no en el escritorio.

## Interfaz actual del instalador

Uso recomendado:

```powershell
powershell -ExecutionPolicy Bypass -File package\windows\install.ps1 [options]
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
- `-h`, `--help`

Valores por defecto actuales:

- `workspaces = true`
- `git = false`
- `svn = false`
- `connections = false`

Estado real de la interfaz:

- `--yes` se acepta, pero en la implementación actual no hay prompts interactivos de selección de módulos;
- la selección de módulos se controla solo por flags o por defaults;
- una opción desconocida termina con error.

## Interfaz actual del desinstalador

Uso recomendado:

```powershell
powershell -ExecutionPolicy Bypass -File package\windows\uninstall.ps1 [options]
```

Opciones públicas actuales:

- `--yes`
- `-h`, `--help`

Estado real de la interfaz:

- `--yes` se acepta, pero el desinstalador actual no pide confirmación en ningún punto;
- la desinstalación es directa y no interactiva.

## Flujo real de instalación

Orden real del script:

1. parsea argumentos;
2. valida o instala `nvim`;
3. valida o instala `node` y `npm`;
4. verifica `git`;
5. detecta `neovide` como opcional;
6. crea directorios de trabajo bajo `%LOCALAPPDATA%\kvim`;
7. copia `nvim\*` a `%LOCALAPPDATA%\kvim`;
8. escribe `lua\kvim\local.lua`;
9. copia el icono si existe en el repo;
10. escribe `%LOCALAPPDATA%\kvim\bin\kvim.bat`;
11. añade `%LOCALAPPDATA%\kvim\bin` al `PATH` de usuario;
12. crea `KVIM.lnk` en el menú inicio;
13. escribe `install-state`;
14. imprime resumen final.

Comportamiento importante:

- `%LOCALAPPDATA%\kvim` no se crea al inicio, sino después de superar la validación de dependencias obligatorias;
- si `winget` instala Neovim o Node.js pero el binario todavía no queda usable en la sesión actual, el instalador aborta antes de copiar KVIM;
- en ese caso puede existir el paquete instalado por `winget` sin que exista todavía perfil KVIM, launcher ni `install-state`.

## Flujo real de desinstalación

Orden real del script:

1. parsea argumentos;
2. carga `install-state` si existe;
3. imprime el plan de borrado;
4. elimina launcher, shortcut, icono y `install-state`;
5. desinstala dependencias gestionadas con `winget` si el estado lo permite;
6. elimina `%LOCALAPPDATA%\kvim\bin` del `PATH` de usuario si procede;
7. elimina `%LOCALAPPDATA%\kvim` completo;
8. imprime resumen final.

Si `install-state` no existe:

- entra en modo best-effort;
- intenta limpiar rutas bajo `%LOCALAPPDATA%\kvim`;
- no puede saber con fiabilidad si debe retirar Neovim o Node.js;
- no puede garantizar que quite el `PATH` si no sabe que KVIM lo modificó.

## Dependencias

### Requeridas

- `git`
- `Neovim >= 0.10.0`
- `node`
- `npm`

### Provisionadas automáticamente

Cuando falta o no cumple requisitos, el instalador intenta usar:

- `winget` para `Neovim.Neovim`;
- `winget` para `OpenJS.NodeJS.LTS`.

### Requeridas para provisión automática

- `winget`

Si falta `winget` y Neovim o Node.js no están disponibles, el instalador falla.

### Opcionales realmente comprobadas

- `neovide`

Estado real:

- `neovide` solo se detecta;
- no se instala automáticamente;
- no se valida ninguna dependencia opcional específica de `git`, `svn` o `connections`;
- tampoco se instala ninguna dependencia adicional por módulo.

## Configuración local generada

El instalador escribe:

```text
%LOCALAPPDATA%\kvim\lua\kvim\local.lua
```

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

Este override local hace que la instalación Windows arranque con esa selección aunque los defaults globales de `kvim.config` habiliten más módulos.

## Estado y logs

### Log de instalación

Ruta:

```text
%LOCALAPPDATA%\kvim\logs\install.log
```

Características actuales:

- formato por líneas con timestamp;
- incluye `step:<nombre>`;
- registra niveles `STEP`, `INFO`, `WARN`, `ERROR`.

### Log de desinstalación

Ruta:

```text
%TEMP%\kvim-uninstall.log
```

Características actuales:

- también registra timestamps y `step:<nombre>`;
- no se guarda dentro de `%LOCALAPPDATA%\kvim` porque esa raíz puede eliminarse durante el proceso.

### Estado de instalación

Ruta:

```text
%LOCALAPPDATA%\kvim\install-state
```

El manifiesto actual registra al menos:

- rutas instaladas;
- ruta del launcher;
- ruta del icono;
- ruta del shortcut;
- flags de módulos habilitados;
- si `neovide` fue detectado;
- si Neovim fue instalado por KVIM;
- si Node.js fue instalado por KVIM;
- si KVIM añadió `%LOCALAPPDATA%\kvim\bin` al `PATH`.

Ese archivo es la fuente de verdad para la desinstalación gestionada.

## Comportamiento real del launcher `kvim`

El instalador genera:

```text
%LOCALAPPDATA%\kvim\bin\kvim.bat
```

El launcher actual:

- fija `NVIM_APPNAME=kvim`;
- ejecuta `nvim` por defecto;
- acepta `--gui`;
- acepta `--help`;
- para `--gui`, intenta ejecutar `neovide`;
- si `neovide` no existe, hace fallback a terminal con `nvim`;
- si `neovide` falla al arrancar, hace fallback a terminal con `nvim`.

Ejemplos válidos:

```bat
kvim
kvim file.lua
kvim --gui
kvim --gui file.lua
```

Notas reales:

- el launcher usa `nvim` y `neovide` por nombre, no por ruta absoluta;
- depende de que esos binarios sean resolubles en `PATH`;
- el manejo de argumentos del modo GUI está implementado con `%1` a `%9`, no con reenvío arbitrario completo.

## PATH de usuario

El instalador trabaja solo sobre el `PATH` de usuario de Windows.

Comportamiento actual:

- lee `Path` de usuario;
- si `%LOCALAPPDATA%\kvim\bin` ya existe en ese `PATH`, no hace cambios;
- si no existe, lo añade al final;
- no modifica el `PATH` de máquina.

El script también refresca el `PATH` de la sesión actual fusionando:

- `PATH` del proceso;
- `PATH` de usuario;
- `PATH` de máquina.

El desinstalador:

- solo retira esa entrada si `install-state` indica `PATH_UPDATED=true`;
- no elimina otras entradas similares no gestionadas por KVIM.

## Shortcut Start Menu

El instalador crea:

```text
%APPDATA%\Microsoft\Windows\Start Menu\Programs\KVIM.lnk
```

Configuración real del shortcut:

- `TargetPath = %LOCALAPPDATA%\kvim\bin\kvim.bat`
- `Arguments = --gui`
- `WorkingDirectory = %LOCALAPPDATA%\kvim`
- `IconLocation = %LOCALAPPDATA%\kvim\assets\kvim-logo.png` si el icono existe

Consecuencias reales:

- el menú inicio intenta abrir KVIM en modo GUI;
- si `neovide` no está disponible, el launcher hará fallback a terminal;
- si la creación COM del shortcut falla, la instalación continúa con warning.

## Criterios actuales de uninstall de dependencias

El desinstalador solo intenta quitar dependencias externas cuando `install-state` indica que KVIM las instaló.

Criterios actuales:

- `INSTALLED_NEOVIM=true` -> intenta `winget uninstall --id Neovim.Neovim`;
- `INSTALLED_NODEJS=true` -> intenta `winget uninstall --id OpenJS.NodeJS.LTS`.

No desinstala automáticamente:

- `git`;
- `neovide`;
- dependencias opcionales por módulo;
- cualquier otro paquete no registrado explícitamente.

Si `winget` no está disponible durante el uninstall:

- se emite warning;
- la limpieza de archivos KVIM sigue;
- la dependencia externa queda sin retirar.

## Limitaciones actuales

- depende de `ExecutionPolicy Bypass` o de una política que permita ejecutar `.ps1`;
- no hay fase de preinstalación headless de plugins de `lazy.nvim`;
- no hay instalación automática de dependencias por módulo;
- `git` es obligatorio pero no se provisiona automáticamente;
- solo `neovide` se trata como opcional visible;
- `--yes` está expuesto pero no cambia el flujo real actual;
- `%LOCALAPPDATA%\kvim` se sobreescribe al copiar `nvim\*`;
- el launcher GUI reenvía argumentos solo hasta `%9`;
- el launcher depende de `nvim` y `neovide` en `PATH`;
- no hay acceso directo en escritorio;
- no hay asociación de archivos ni integración con “Open with”;
- si falla la sesión justo después de `winget`, puede quedar dependencia instalada sin perfil KVIM terminado;
- si falta `install-state`, el uninstall solo puede hacer limpieza best-effort.

## Decisiones de diseño reflejadas por la implementación

- usar PowerShell como implementación real y único entrypoint Windows;
- instalar por usuario en `%LOCALAPPDATA%` en lugar de usar rutas globales;
- aislar KVIM mediante `NVIM_APPNAME=kvim`;
- generar `local.lua` en vez de editar defaults del repo;
- registrar un manifiesto mínimo para soportar uninstall seguro;
- tocar solo el `PATH` de usuario;
- usar `winget` solo para Neovim y Node.js;
- tratar `neovide` como opcional y dejar que el launcher haga fallback;
- permitir que la instalación continúe aunque falle la creación del shortcut o la detección del icono.

## Cambios futuros deseables

- convertir `--yes` en un contrato coherente o retirarlo;
- añadir prompts reales de selección de módulos o simplificar la interfaz;
- preinstalar plugins de `lazy.nvim` en modo headless si el flujo Windows ya lo soporta de forma estable;
- soportar instalación automática de dependencias opcionales por módulo;
- registrar más estado para uninstall y recuperación de errores parciales;
- mejorar el launcher para reenviar todos los argumentos correctamente;
- permitir shortcut de escritorio opcional;
- separar mejor config, logs y estado si el perfil Windows crece;
- documentar o implementar una estrategia de update incremental del perfil instalado.

## Changelog interno de la spec

### Implementado hasta la fecha

- migración del instalador/desinstalador Windows a PowerShell;
- provisión automática de Neovim con `winget`;
- provisión automática de Node.js LTS con `winget`;
- validación de versión mínima de Neovim (`0.10.0`);
- copia del perfil `nvim/` a `%LOCALAPPDATA%\kvim`;
- generación de `local.lua`;
- generación del launcher `kvim.bat`;
- adición de `%LOCALAPPDATA%\kvim\bin` al `PATH` de usuario;
- creación de shortcut en menú inicio;
- copia opcional del icono desde `assets/kvim-logo.png`;
- manifiesto `install-state`;
- uninstall gestionado con retirada opcional de Neovim y Node.js si fueron instalados por KVIM.

### Correcciones y ajustes relevantes ya reflejados

- el entrypoint Windows real y único son `install.ps1` y `uninstall.ps1`;
- la creación de `%LOCALAPPDATA%\kvim` ocurre después de validar dependencias críticas;
- el launcher `kvim --gui` ya no falla de forma dura cuando falta `neovide`, sino que hace fallback a terminal;
- el uninstall no usa prompts aunque acepte `--yes`;
- el uninstall se apoya en `install-state` para decidir si retira paquetes externos y PATH.

## Criterio de consistencia

Esta spec debe mantenerse sincronizada con:

- `package/windows/install.ps1`
- `package/windows/uninstall.ps1`
- `README.md`
- `nvim/lua/kvim/config.lua`

Si cambian rutas públicas, flags, launcher, política de `PATH`, shortcut del menú inicio, dependencias gestionadas o formato de `install-state`, esta spec debe actualizarse.
