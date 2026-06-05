# 0002 - Reconnect SSH connection in the same terminal buffer

## Objetivo

Implementar un comando para reintentar una conexión SSH existente en KVIM reutilizando el mismo buffer de terminal.

El comando debe permitir relanzar una conexión SSH previamente creada sin cerrar el buffer actual ni generar una nueva terminal duplicada.

## Contexto

En ocasiones, las máquinas virtuales o equipos físicos a los que se conecta por SSH no están disponibles.

Cuando esto ocurre, la terminal puede mostrar un error de conexión SSH. El usuario debe poder reintentar la conexión más adelante sobre el mismo buffer donde se vio el error.

La solución debe residir principalmente en el módulo `connections`.

El módulo `workspaces` solo debería intervenir si ya existe alguna API para localizar o mostrar el tab `Term`, pero no debe contener lógica SSH ni lógica de retry.

## Comando a implementar

Crear el comando:

```vim
:KvimConnectionsReconnect <name>
```

El parámetro `<name>` es obligatorio.

Ejemplo:

```vim
:KvimConnectionsReconnect Docker SSH Test
```

## Comportamiento esperado

Al ejecutar el comando con un nombre de conexión, KVIM debe:

1. Buscar la conexión configurada con ese nombre.
2. Verificar que la conexión existe.
3. Verificar que la conexión es de tipo `ssh`.
4. Buscar el buffer de terminal asociado a esa conexión.
5. Verificar que el buffer existe y sigue siendo válido.
6. Reutilizar ese mismo buffer de terminal.
7. Relanzar el comando SSH dentro de ese buffer.
8. Evitar crear un nuevo buffer si ya existe uno asociado a la conexión.

## Caso sin argumento

Si se ejecuta el comando sin nombre:

```vim
:KvimConnectionsReconnect
```

Debe devolver error.

Mensaje sugerido:

```text
Kvim Connections: connection name is required
```

## Requisitos funcionales

* `:KvimConnectionsReconnect <name>` debe aceptar únicamente el nombre de una conexión.
* El nombre de la conexión es obligatorio.
* Solo debe funcionar con conexiones de tipo `ssh`.
* No debe funcionar con conexiones `serial` u otros tipos.
* Debe reutilizar el mismo buffer de terminal asociado a la conexión.
* No debe crear buffers duplicados.
* Si el buffer asociado ya no existe, debe devolver un error controlado.
* Si la conexión no existe, debe devolver un error controlado.
* Si la conexión no es SSH, debe devolver un error controlado.
* Los errores deben mostrarse mediante `vim.notify`.
* Los errores deben registrarse mediante el logger del módulo, si existe.

## Diseño recomendado

La lógica debe implementarse dentro del módulo `connections`.

Estructura sugerida:

```text
lua/kvim/modules/connections/
├── commands.lua
├── actions.lua
├── ssh.lua
├── terminal.lua
└── state.lua
```

Responsabilidades recomendadas:

```text
commands.lua  -> define :KvimConnectionsReconnect
actions.lua   -> expone la acción reload
ssh.lua       -> construye el comando SSH
terminal.lua  -> reutiliza el buffer de terminal
state.lua     -> mantiene la relación conexión <-> buffer
```

## Función sugerida

Crear una función de alto nivel similar a:

```lua
M.reload(name)
```

Esta función debe:

1. Validar que `name` no está vacío.
2. Buscar la conexión por nombre.
3. Validar que es una conexión SSH.
4. Obtener el buffer asociado desde el estado del módulo.
5. Si no existe mapping runtime, intentar descubrir el buffer escaneando buffers terminal con metadata asociada a la conexión.
6. Validar que el buffer existe.
7. Reconstruir el comando SSH.
8. Reutilizar la misma ventana del terminal asociado.
9. Si el stream anterior está cerrado, recrear una nueva terminal SSH en esa misma ventana.

## Metadata recomendada

Cuando se cree una terminal SSH desde KVIM, guardar metadata que permita asociarla con su conexión:

```lua
vim.b.kvim_connection_managed = true
vim.b.kvim_connection_name = conn.name
vim.b.kvim_connection_type = conn.type
```

Además, para integrarse con `workspaces` y terminales restauradas, `Reconnect` puede usar metadata ya existente del recipe buffer:

```lua
vim.b.kvim_workspace_recipe_connection = conn.name
vim.b.kvim_workspace_recipe_type = "ssh"
```

Como último fallback, `Reconnect` puede intentar identificar el buffer por el comando SSH guardado en:

```lua
vim.b.kvim_workspace_recipe_command
```

si este contiene el target esperado (`user@host`, `host`, `port`) de la conexión.

Además, el módulo `connections.lua` debería mantener un registro similar a:
```lua
return {  {
    host = "127.0.0.1",
    identity_file = "/home/KODVMV/.ssh/kvim_docker-test-1_ed25519",
    name = "docker-test-1",
    options = {
      IdentitiesOnly = "yes"
    },
    port = 2222,
    type = "ssh",
    user = "test"
  } }

```

## Errores esperados

Ejemplos de errores que deben controlarse:

```text
Kvim Connections: connection name is required
Kvim Connections: connection not found: <name>
Kvim Connections: connection is not ssh: <name>
Kvim Connections: terminal buffer not found: <name>
Kvim Connections: terminal buffer is no longer valid: <name>
Kvim Connections: failed to reload SSH connection: <reason>
```

## Criterios de aceptación

* Existe el comando `:KvimConnectionsReconnect <name>`.
* El comando devuelve error si no se pasa `<name>`.
* El comando busca una conexión por nombre.
* El comando solo permite conexiones de tipo `ssh`.
* El comando reutiliza la ubicación visual del terminal existente.
* El comando no crea buffers duplicados.
* Si crea una nueva terminal para reintentar la conexión, limpia o deslista el buffer anterior para no dejar dos terminales lógicas de la misma conexión.
* El comando puede redescubrir buffers restaurados por sesión/workspace mediante metadata si se perdió el mapping en memoria.
* Los errores se notifican con `vim.notify`.
* Los errores se registran en logs si existe logger.
* No se introduce lógica SSH dentro de `workspaces`.
* No se rompe el comportamiento actual de apertura de conexiones.

## Tests recomendados

Añadir tests para los siguientes casos:

1. `reconnect` con nombre válido de conexión SSH.
2. `reconnect` sin nombre.
3. `reconnect` con nombre inexistente.
4. `reconnect` con conexión no SSH.
5. `reconnect` cuando el buffer asociado existe.
6. `reconnect` cuando el buffer asociado ya no existe.
7. Verificar que no se crea un nuevo buffer si ya existe uno válido.

## Nota final

El comando debe ser una capa fina sobre la lógica del módulo `connections`.

No implementar toda la lógica dentro de `commands.lua`. El comando debe delegar en una función testeable del módulo.
