# 0003 - User Connections Configuration

## Objetivo

Abstraer la configuración de conexiones SSH de KVIM para que las conexiones reales del usuario residan fuera del código versionado del programa.

El fichero `connections.lua` de usuario deberá mantenerse entre actualizaciones, reinstalaciones y pulls del repositorio, y solo deberá eliminarse cuando el usuario desinstale KVIM con borrado explícito de datos locales.

## Motivación

Actualmente las conexiones SSH pueden quedar demasiado acopladas al árbol de código de KVIM o a ficheros que forman parte de la instalación.

Esto provoca varios problemas:

* Un `git pull` puede traer un `connections.lua` por defecto que no representa las conexiones reales del usuario.
* Una actualización puede sobrescribir configuración local.
* El usuario puede perder conexiones si la configuración vive dentro de la carpeta gestionada por el programa.
* No queda clara la diferencia entre configuración por defecto y configuración real del usuario.
* El instalador/desinstalador no tiene una política clara sobre cuándo conservar o eliminar conexiones.

Esta feature busca separar claramente:

```text
configuración distribuida por KVIM
configuración local del usuario
```

## Alcance

Esta especificación cubre:

* Nueva ubicación canónica para el fichero de conexiones de usuario.
* Fichero de conexiones por defecto distribuido con KVIM.
* Carga de configuración de conexiones desde la ruta local del usuario.
* Creación inicial de `connections.lua` si no existe.
* Política de actualización sin sobrescritura.
* Política de desinstalación.
* Compatibilidad con Linux y Windows.
* Backups preventivos antes de sobrescribir o migrar.
* Migración desde rutas antiguas, si existen.

## Fuera de alcance

No se contempla en esta feature:

* Backup/restore completo de workspaces.
* Exportación o importación entre máquinas.
* Migración entre Linux y Windows.
* Copia de claves privadas SSH.
* Copia de claves públicas SSH.
* Gestión de contraseñas o passphrases.
* Validación de conectividad SSH.
* Sincronización remota de conexiones.
* Cifrado de conexiones.
* Edición visual completa de conexiones.

## Principio de diseño

La configuración de usuario debe vivir fuera del código actualizable.

KVIM puede distribuir una plantilla por defecto, pero esa plantilla nunca debe sobrescribir automáticamente el fichero real del usuario.

```text
Código de KVIM:
  contiene defaults, ejemplos y lógica

Datos del usuario:
  contienen conexiones reales
```

## Rutas actuales

### Linux

```text
~/.config/kvim/lua/kvim/connections.lua
```

### Windows

```text
%LOCALAPPDATA%/kvim/lua/kvim/connections.lua
```

## Ruta canónica propuesta

El fichero de conexiones real del usuario deberá residir en la configuración local de KVIM.

### Linux

```text
~/.config/kvim/connections.lua
```

### Windows

```text
%LOCALAPPDATA%/kvim/connections.lua
```

## Ruta de plantilla por defecto

KVIM podrá incluir una plantilla de conexiones dentro del repositorio o instalación.

Ruta propuesta dentro del repo:

```text
nvim/lua/kvim/modules/connections/defaults/connections.lua
```

Contenido esperado:

```lua
return {
    connections = {
        -- Example:
        -- {
        --     name = "example",
        --     host = "192.168.1.100",
        --     user = "user",
        --     port = 22,
        --     identity_file = nil,
        -- }
    },
}
```

Esta plantilla sirve solo para inicializar la configuración del usuario cuando no exista todavía.

## Regla principal

KVIM nunca debe cargar conexiones reales desde el fichero versionado del repositorio.

El módulo `connections` debe cargar siempre desde:

### Linux

```text
~/.config/kvim/connections.lua
```

### Windows

```text
%LOCALAPPDATA%/kvim/connections.lua
```

Si el fichero no existe, KVIM deberá crearlo a partir de la plantilla por defecto.

## Comportamiento en primera ejecución

Durante la primera ejecución de KVIM:

1. Resolver la ruta local de configuración.
2. Comprobar si existe `connections.lua`.
3. Si no existe, crear el fichero desde la plantilla por defecto.
4. Cargar conexiones desde el fichero local.
5. Si la creación falla, mostrar un error controlado.

Ejemplo:

```text
KVIM Connections: user config not found
KVIM Connections: created ~/.config/kvim/connections.lua from default template
```

## Comportamiento en actualización

Durante una actualización, pull del repositorio o reinstalación:

1. No sobrescribir `connections.lua` del usuario.
2. No reemplazarlo por la plantilla del repositorio.
3. No eliminarlo.
4. Si cambia el formato interno esperado, crear backup antes de migrar.
5. Si la migración no es posible, conservar el fichero original y reportar error.

Regla obligatoria:

```text
update/pull/reinstall must preserve user connections
```

## Comportamiento en desinstalación

El desinstalador deberá distinguir entre desinstalación normal y purga.

### Uninstall normal

La desinstalación normal elimina binarios, launchers, desktop entries e integración del sistema, pero conserva datos de usuario.

Debe conservar:

```text
~/.config/kvim/connections.lua
%LOCALAPPDATA%/kvim/connections.lua
```

### Uninstall con purge

La desinstalación con purge puede eliminar configuración local de usuario.

Antes de borrar `connections.lua`, debe avisar al usuario.

Ejemplo:

```text
KVIM user connections found:
~/.config/kvim/connections.lua

Remove user connections? [y/N]
```

Comportamiento por defecto:

```text
No borrar
```

Si el usuario confirma, se elimina el fichero.

## Migración desde rutas antiguas

Si existen rutas antiguas, KVIM deberá migrarlas a la nueva ruta canónica.

Rutas antiguas conocidas:

### Linux

```text
~/.config/kvim/lua/kvim/connections.lua
```

### Windows

```text
%LOCALAPPDATA%/kvim/lua/kvim/connections.lua
```

Nueva ruta:

### Linux

```text
~/.config/kvim/connections.lua
```

### Windows

```text
%LOCALAPPDATA%/kvim/connections.lua
```

## Estrategia de migración

Durante el arranque o instalación:

1. Comprobar si existe la nueva ruta.
2. Si existe, usarla y no migrar nada.
3. Si no existe, comprobar si existe la ruta antigua.
4. Si existe la ruta antigua, copiarla a la nueva ruta.
5. Crear backup de la ruta antigua.
6. No eliminar automáticamente la ruta antigua en el MVP.
7. Mostrar aviso informativo.

Ejemplo:

```text
KVIM Connections: migrated config
from: ~/.config/kvim/lua/kvim/connections.lua
to:   ~/.config/kvim/connections.lua
```

Backup:

```text
~/.config/kvim/lua/kvim/connections.lua.bak
```

## Orden de resolución de configuración

El módulo `connections` deberá resolver configuración en este orden:

1. Ruta canónica de usuario.
2. Ruta antigua de usuario, solo para migración.
3. Plantilla por defecto del repositorio, solo para inicialización.

No se permite usar la plantilla por defecto como fichero de configuración real en ejecución normal.

## API interna propuesta

Añadir un módulo de paths/configuración para connections.

Ruta sugerida:

```text
nvim/lua/kvim/modules/connections/config_paths.lua
```

Responsabilidades:

* Resolver ruta de usuario.
* Resolver ruta legacy.
* Resolver ruta de plantilla.
* Crear directorios necesarios.
* Inicializar configuración si no existe.
* Migrar configuración legacy.
* Crear backups.

Ejemplo de API:

```lua
local M = {}

function M.user_config_path()
end

function M.legacy_config_path()
end

function M.default_config_path()
end

function M.ensure_user_config()
end

function M.migrate_legacy_config()
end

return M
```

## Carga de conexiones

El módulo de conexiones no debe hacer `require()` directo del fichero de usuario si eso depende de `runtimepath`.

Debe cargar el fichero por ruta absoluta.

Ejemplo conceptual:

```lua
local config_path = require("kvim.modules.connections.config_paths").ensure_user_config()
local ok, config = pcall(dofile, config_path)
```

Si falla la carga:

1. No romper el arranque de KVIM.
2. Mostrar error controlado.
3. Devolver lista vacía de conexiones.
4. Indicar ruta del fichero problemático.

Ejemplo:

```text
KVIM Connections: failed to load user connections config
File: ~/.config/kvim/connections.lua
Error: unexpected symbol near ...
```

## Formato de connections.lua

El fichero deberá devolver una tabla Lua.

Formato recomendado:

```lua
return {
    connections = {
        {
            name = "local-linux",
            host = "192.168.1.186",
            user = "KODVMV",
            port = 22,
            identity_file = "~/.ssh/kvim_test_ed25519",
            remote_root = nil,
            use_tmux = false,
            tmux_session = nil,
        },
    },
}
```

## Campos soportados

Campos mínimos:

```text
name
host
user
port
```

Campos opcionales:

```text
identity_file
remote_root
use_tmux
tmux_session
extra_args
```

## Validación mínima

Al cargar el fichero, KVIM deberá validar:

* `connections` existe.
* `connections` es una tabla.
* Cada conexión tiene `name`.
* Cada conexión tiene `host`.
* Cada conexión tiene `user`.
* `port`, si existe, es numérico.
* `identity_file`, si existe, es string.

Las conexiones inválidas deberán ignorarse o reportarse sin romper todo el módulo.

## Seguridad

Reglas obligatorias:

* No copiar claves privadas.
* No copiar claves públicas.
* No copiar passphrases.
* No copiar contraseñas.
* No incluir secretos en la plantilla por defecto.
* No sobrescribir fichero local del usuario durante actualización.
* Crear backup antes de migrar o modificar una configuración existente.
* No ejecutar comandos remotos durante la carga de configuración.
* No validar conexiones automáticamente en el arranque.

## Relación con instaladores

### Instalador Linux

El instalador deberá:

1. Crear directorio de configuración si no existe.
2. Crear `~/.config/kvim/connections.lua` solo si no existe.
3. No sobrescribir `connections.lua` si ya existe.
4. Migrar desde ruta antigua si procede.
5. Registrar en `install-state` que existe configuración de usuario, pero no tratarla como fichero propio que deba borrarse en uninstall normal.

### Instalador Windows

El instalador deberá:

1. Crear directorio de configuración si no existe.
2. Crear `%LOCALAPPDATA%/kvim/connections.lua` solo si no existe.
3. No sobrescribir `connections.lua` si ya existe.
4. Migrar desde ruta antigua si procede.
5. Registrar en `install-state` que existe configuración de usuario, pero no tratarla como fichero propio que deba borrarse en uninstall normal.

## Relación con uninstall

### Uninstall normal

No debe eliminar:

### Linux

```text
~/.config/kvim/connections.lua
```

### Windows

```text
%LOCALAPPDATA%/kvim/connections.lua
```

### Uninstall purge

Puede eliminar el fichero si el usuario lo confirma explícitamente.

## Logs esperados

Primera ejecución:

```text
KVIM Connections: created user config from default template
```

Configuración existente:

```text
KVIM Connections: using user config ~/.config/kvim/connections.lua
```

Migración:

```text
KVIM Connections: migrated legacy config to ~/.config/kvim/connections.lua
```

Error de carga:

```text
KVIM Connections: failed to load user config
```

## Criterios de aceptación

La feature se considera válida cuando:

* Las conexiones reales se cargan desde la ruta de usuario.
* El fichero versionado del repositorio solo actúa como plantilla.
* Un `git pull` no sobrescribe conexiones reales.
* Una reinstalación no sobrescribe conexiones reales.
* La primera ejecución crea `connections.lua` si no existe.
* La configuración antigua se migra a la ruta nueva si existe.
* El uninstall normal conserva `connections.lua`.
* El uninstall purge puede eliminar `connections.lua` solo con confirmación.
* Los errores de sintaxis en `connections.lua` no rompen todo KVIM.
* No se copian claves SSH ni secretos.
* Funciona en Linux.
* Funciona en Windows.

## Futuras mejoras

* Comando `:KvimConnectionsConfigOpen`.
* Comando `:KvimConnectionsConfigPath`.
* Editor interactivo de conexiones.
* Validación manual de conexiones.
* Backup automático antes de editar.
* Soporte para perfiles.
* Soporte para conexiones por workspace.
* Soporte para configuración JSON/YAML además de Lua.
* Cifrado opcional de campos sensibles si en el futuro se soportan secretos.
