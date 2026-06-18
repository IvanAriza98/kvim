# 0004 - Separación entre tab `term` y explorer en tab `code`

## Objetivo

Definir una política explícita para separar las tabs lógicas `code` y `term` de los workspaces de KVIM respecto al explorer basado en Neo-tree.

El objetivo funcional es doble:

- el tab `term` no debe conservar ventanas ni buffers de Neo-tree;
- cualquier acción de explorer lanzada desde `term` debe bloquearse con un notice informativo.

La intención es reforzar la semántica actual de layout por roles de KVIM:

```text
code = edición y navegación de proyecto
term = terminales, sesiones SSH y vistas auxiliares del hub term
```

## Motivación

KVIM ya usa workspaces con tabs lógicas `code` y `term`, pero el explorer sigue expuesto hoy mediante keymaps globales y acciones directas de Neo-tree.

Eso rompe la separación de roles en varios casos:

- desde `term` se puede abrir Neo-tree en la tab equivocada;
- el tab `term` puede quedar contaminado con una sidebar de explorer;
- al volver a `term`, el usuario puede encontrar ventanas de Neo-tree en lugar de una terminal, la vista de sesiones o el placeholder;
- la navegación por buffers del tab `term` deja de representar solo buffers terminales;
- la UX de workspace pierde predictibilidad.

La política propuesta busca que el usuario pueda asumir siempre lo siguiente:

```text
si estoy en term, el explorer no debe abrirse
```

## Alcance

Esta spec cubre:

- la política de separación entre tabs lógicas `code` y `term`;
- el bloqueo de acciones de explorer cuando se lanzan desde `term`;
- la limpieza de Neo-tree en `term`;
- el comportamiento esperado al volver a `term`;
- la interacción con workspaces activos;
- los keymaps públicos afectados;
- los tipos de buffers permitidos en cada tab lógica;
- las pruebas mínimas para validar el comportamiento.

## Fuera de alcance

Esta spec no cubre:

- rediseño completo del módulo `workspaces`;
- cambios de provider de explorer distintos de Neo-tree;
- interceptar todos los `:Neotree ...` escritos manualmente por el usuario;
- sincronización avanzada entre múltiples explorers;
- persistencia explícita del estado abierto/cerrado de Neo-tree por workspace;
- reorganización de tabs fuera del modelo actual `role_tabs`.

## Comportamiento actual / problema

Estado real actual relevante en el código:

- `workspaces` define layout por defecto con dos tabs lógicas: `code` y `term`;
- `:KvimWorkspaceTabCode` y `:KvimWorkspaceTabTerm` ya permiten navegar entre ambas;
- `term` puede mostrar:
  - terminales reales;
  - una vista de sesiones SSH del workspace;
  - un placeholder `KVIM Term` si no hay terminal activa;
- los keymaps de explorer actuales llaman a acciones públicas que pueden disparar Neo-tree desde cualquier tab;
- no existía una capa de bloqueo por rol de tab;
- no existía una limpieza específica de Neo-tree al entrar o volver a `term`.

Consecuencia práctica:

- si el usuario lanza explorer desde `term`, Neo-tree puede abrirse en `term`;
- si luego vuelve a `term`, esa tab puede seguir teniendo una ventana de explorer;
- la semántica actual de `term` como hub de terminales deja de cumplirse.

## Política deseada

Regla principal:

```text
Neo-tree pertenece a code, no a term.
```

Reglas obligatorias:

1. El tab `term` no debe conservar ventanas de Neo-tree.
2. El tab `term` no debe quedar con buffers de Neo-tree como vista visible al regresar.
3. Toda acción pública de explorer disparada desde `term` debe bloquearse con un notice informativo.
4. Neo-tree no debe abrirse ni reubicarse automáticamente en `term`.
5. Si Neo-tree llega a abrirse en `term` por cualquier entrypoint, KVIM debe cerrarlo y mantener `term` en un estado válido.
6. Si no hay workspace activo o no existe contexto de tabs lógicas, el explorer puede mantener su comportamiento global actual.
7. La política aplica al explorer lateral de Neo-tree, incluyendo al menos:
   - filesystem;
   - focus;
   - reveal;
   - close;
   - git_status;
   - buffers.

## Principio de diseño

La tab `term` debe comportarse como un espacio de ejecución, no como un espacio de navegación lateral del proyecto.

En términos prácticos:

```text
code -> archivos, edición, explorer
term -> terminales, SSH, vistas del hub term, placeholder term
```

## Reglas de UX

### Regla 1: abrir explorer desde `term` se bloquea

Si el usuario está en `term` y pulsa un keymap de explorer, KVIM debe:

1. detectar que está en la tab `term`;
2. no abrir Neo-tree;
3. mostrar un notice informativo.

El foco final debe permanecer en `term`.

### Regla 2: `term` no debe mostrar Neo-tree al volver

Si el usuario vuelve luego a `term` con `:KvimWorkspaceTabTerm` o `<leader>2`, no debe reaparecer una ventana de Neo-tree en esa tab.

`term` debe quedar en uno de estos estados válidos:

- una terminal activa;
- la vista `KVIM Term Sessions`;
- el placeholder `KVIM Term`.

### Regla 3: si Neo-tree llega a abrirse en `term`, se cierra

Si por cualquier motivo Neo-tree llega a abrirse en `term`:

1. KVIM detecta el buffer `neo-tree` en un contexto `term`;
2. cierra Neo-tree;
3. muestra un notice informativo;
4. reconstruye la vista válida de `term`.

### Regla 4: no duplicar sidebars entre roles

No debe existir el mismo explorer abierto simultáneamente en `code` y `term` dentro del mismo workspace lógico.

## Flujo esperado

### Caso A: abrir explorer desde `code`

1. Usuario está en `code`.
2. Lanza una acción de explorer.
3. Neo-tree se abre o enfoca en `code`.
4. `term` no cambia.

### Caso B: abrir explorer desde `term`

1. Usuario está en `term`.
2. Lanza una acción de explorer.
3. KVIM detecta que la tab activa tiene rol `term`.
4. KVIM bloquea la apertura del explorer.
5. Muestra un notice al usuario.
6. `term` queda libre de Neo-tree.

### Caso C: volver a `term`

1. Usuario estuvo en `code` usando explorer.
2. Vuelve a `term`.
3. KVIM garantiza que `term` no muestra Neo-tree.
4. Si hay terminal activa, la muestra.
5. Si no hay terminal activa pero hay sesiones SSH del workspace, muestra `KVIM Term Sessions`.
6. Si no hay nada restaurable, muestra `KVIM Term`.

## Interacción con workspaces

Esta política depende del modelo actual de `workspaces` con tabs por rol.

### Con workspace activo

Con un workspace activo:

- `code` y `term` son tabs lógicas del workspace;
- el bloqueo desde `term` debe apoyarse en el rol guardado en `state`;
- `term` debe seguir usando su lógica actual de terminal activa, sesiones SSH o placeholder.

### Sin workspace activo

Sin workspace activo:

- KVIM no tiene garantía de roles `code`/`term`;
- los keymaps globales de explorer pueden conservar su comportamiento normal;
- esta spec no obliga a crear tabs nuevas fuera del flujo de workspace.

### Cambio de workspace

Al cargar otro workspace:

- la separación `code`/`term` debe aplicarse de nuevo sobre el nuevo workspace activo;
- cualquier resto de explorer en el `term` del workspace cargado debe considerarse inválido;
- el foco final esperado del load sigue siendo `code`, consistente con el comportamiento documentado del módulo.

## Keymaps afectados

Afecta a los keymaps públicos actuales de explorer definidos en la configuración base:

- `<leader>e` → explorer toggle
- `<leader>E` → explorer focus
- `<leader>fe` → explorer reveal
- `<leader>ec` → explorer close
- `<leader>eg` → explorer git status
- `<leader>eb` → explorer buffers

## Buffers permitidos en `code` y `term`

## Tab `code`

Buffers/ventanas permitidos:

- buffers normales de edición;
- buffers listados no terminales;
- ventanas de Neo-tree;
- vistas relacionadas con navegación de proyecto;
- buffers auxiliares no terminales compatibles con flujo de edición.

## Tab `term`

Buffers/ventanas permitidos:

- buffers con `buftype=terminal`;
- vista `KVIM Term Sessions`;
- placeholder `KVIM Term`;
- vistas estrictamente orientadas al hub de terminales del workspace.

Buffers/ventanas no permitidos en `term`:

- Neo-tree filesystem;
- Neo-tree git_status;
- Neo-tree buffers;
- cualquier sidebar de explorer persistente.

## Comportamiento ante retorno al tab `term`

Al volver a `term`, KVIM debe validar la tab antes de presentarla al usuario.

Política esperada:

1. si hay una terminal activa visible en `term`, mantenerla;
2. si no hay terminal activa y hay sesiones SSH del workspace, mostrar `KVIM Term Sessions`;
3. si no hay terminal ni sesiones, mostrar `KVIM Term`;
4. si existen ventanas o buffers de Neo-tree en `term`, deben cerrarse o dejar de ser visibles antes de completar el cambio.

Resultado observable:

```text
volver a term nunca debe dejar el explorer como contenido residual de esa tab
```

## Pruebas mínimas

Pruebas mínimas recomendadas:

1. **Bloqueo desde `term`**
   - workspace activo;
   - tab actual con rol `term`;
   - disparar acción de explorer;
   - verificar que no se abre Neo-tree;
   - verificar que aparece el notice.

2. **No persistencia de Neo-tree en `term`**
   - simular apertura de explorer desde `term`;
   - volver a `term`;
   - verificar que `term` no muestra buffer/ventana de Neo-tree.

3. **Fallback válido de `term`**
   - sin terminal activa;
   - sin explorer visible;
   - volver a `term`;
   - verificar placeholder o vista de sesiones según corresponda.

4. **Auto-cierre de Neo-tree en `term`**
   - forzar apertura de buffer `neo-tree` en `term`;
   - verificar que KVIM lo cierra y mantiene `term` válido.

5. **Sin workspace activo**
   - lanzar explorer fuera de workspaces;
   - verificar que no se rompe el comportamiento global actual.

## Limitaciones

Limitaciones conocidas de esta política:

- aunque KVIM puede interceptar la apertura de buffers `neo-tree` en `term`, sigue dependiendo del comportamiento observable del plugin y de sus eventos de filetype/buffer;
- no cubre sidebars de otros plugins distintos de Neo-tree;
- puede requerir wrappers específicos para keymaps y acciones de dashboard en lugar de comandos directos;
- no define todavía persistencia del estado abierto/cerrado de explorer por workspace;
- si un plugin externo reabre Neo-tree automáticamente en `term`, eso queda fuera de la garantía básica salvo que KVIM añada interceptores adicionales.

## Resultado esperado

Tras aplicar esta spec, el comportamiento visible debe ser estable y predecible:

- `code` concentra explorer y navegación;
- `term` concentra terminales y vistas de sesión;
- abrir explorer desde `term` no abre Neo-tree y muestra un notice;
- volver a `term` nunca deja Neo-tree como residuo visual.
