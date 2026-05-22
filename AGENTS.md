# KVIM - Guía para agentes

Este archivo describe la estructura actual del proyecto KVIM y las reglas que deben seguir los agentes al modificar el repositorio.

KVIM es una configuración modular de Neovim escrita en Lua. El proyecto está organizado alrededor de un core pequeño, módulos funcionales, especificaciones de plugins, configuración de UI, tests y agentes de OpenCode.

## Estructura del proyecto

```text
.
├── .opencode/
│   ├── agents/
│   │   ├── kvim-main.md
│   │   ├── kvim-core.md
│   │   ├── kvim-docs.md
│   │   ├── kvim-module.md
│   │   └── kvim-tester.md
│   └── opencode.json
├── nvim/
│   ├── init.lua
│   ├── lazy-lock.json
│   └── lua/
│       └── kvim/
│           ├── init.lua
│           ├── config.lua
│           ├── health.lua
│           ├── connections.lua
│           ├── core/
│           ├── modules/
│           ├── plugins/
│           └── ui/
├── scripts/
│   └── test.sh
├── tests/
│   ├── minimal_init.lua
│   ├── core/
│   └── connections/
├── AGENTS.md
├── CHANGELOG.md
├── LICENSE
└── README.md
```

## Arquitectura

KVIM se divide en estas áreas principales:

- `nvim/init.lua`: punto de entrada de Neovim.
- `nvim/lua/kvim/init.lua`: punto de entrada Lua de KVIM.
- `nvim/lua/kvim/config.lua`: configuración global de KVIM.
- `nvim/lua/kvim/health.lua`: comprobaciones de salud del proyecto.
- `nvim/lua/kvim/connections.lua`: definiciones o configuración de entrada para conexiones.
- `nvim/lua/kvim/core/`: funcionalidad base del framework.
- `nvim/lua/kvim/modules/`: módulos funcionales opcionales.
- `nvim/lua/kvim/plugins/`: especificaciones de plugins para `lazy.nvim`.
- `nvim/lua/kvim/ui/`: configuración de UI, tema, editor y barra de estado.
- `tests/`: tests automatizados con Neovim headless, `plenary.nvim` y `busted`.
- `.opencode/`: configuración de OpenCode y agentes del proyecto.

## Core

El código del core vive en:

```text
nvim/lua/kvim/core/
```

Áreas actuales del core:

- `commands.lua`
- `keymaps.lua`
- `registry.lua`
- `runner.lua`
- `terminal.lua`
- `lsp/`

El core debe mantenerse genérico. No debe depender de la implementación interna de un módulo concreto.

Responsabilidades del core:

- comandos globales;
- keymaps globales;
- registro de acciones;
- soporte para carga de módulos;
- ejecución de comandos;
- helpers de terminal;
- comportamiento compartido del framework.

No coloques lógica específica de una funcionalidad dentro del core salvo que sea una abstracción reutilizable.

## Módulos

Los módulos viven en:

```text
nvim/lua/kvim/modules/
```

Módulos actuales:

```text
nvim/lua/kvim/modules/connections/
nvim/lua/kvim/modules/git/
nvim/lua/kvim/modules/svn/
```

Un módulo debe ser autocontenido y puede exponer:

```lua
return {
    name = "module-name",
    setup = function(opts) end,
    plugins = function() return {} end,
    actions = {},
    commands = {},
    keymaps = {},
}
```

No todos los campos son obligatorios.

Para módulos medianos o grandes, usa preferentemente esta estructura:

```text
nvim/lua/kvim/modules/<module>/
├── init.lua
├── config.lua
├── actions.lua
├── commands.lua
├── keymaps.lua
├── plugins.lua
├── state.lua
└── README.md
```

Crea solo los archivos necesarios. No añadas estructura innecesaria.

## Módulos existentes

### Connections

Ruta:

```text
nvim/lua/kvim/modules/connections/
```

El módulo `connections` gestiona SSH, conexiones serie, estado, pickers, gestión de claves y transferencias.

Archivos habituales:

- `actions.lua`
- `commands.lua`
- `config.lua`
- `health.lua`
- `init.lua`
- `keymaps.lua`
- `picker.lua`
- `serial.lua`
- `ssh.lua`
- `ssh_keys.lua`
- `state.lua`
- `transfer.lua`
- `README.md`

No guardes secretos ni claves privadas en el repositorio.

### Git

Ruta:

```text
nvim/lua/kvim/modules/git/
```

El módulo `git` gestiona acciones, comandos, keymaps e integración de plugins relacionados con Git.

Archivos habituales:

- `actions.lua`
- `commands.lua`
- `init.lua`
- `keymaps.lua`
- `plugins.lua`
- `README.md`

No ejecutes operaciones destructivas de Git automáticamente.

### SVN

Ruta:

```text
nvim/lua/kvim/modules/svn/
```

El módulo `svn` gestiona acciones, comandos y keymaps relacionados con SVN.

Archivos habituales:

- `actions.lua`
- `commands.lua`
- `init.lua`
- `keymaps.lua`
- `README.md`

Mantén SVN separado de Git. No mezcles su lógica de comandos.

## Plugins

Las especificaciones de plugins viven en:

```text
nvim/lua/kvim/plugins/
```

Áreas actuales de plugins:

- `dashboard.lua`
- `dev.lua`
- `editor.lua`
- `init.lua`
- `lsp.lua`
- `navigation.lua`
- `ui.lua`
- `README.md`

Las especificaciones de plugins deben ser compatibles con `lazy.nvim`.

No hardcodees comportamiento de plugins dentro de módulos si puede exponerse mediante `plugins()`.

## UI

El código de UI vive en:

```text
nvim/lua/kvim/ui/
```

Archivos actuales de UI:

- `editor.lua`
- `init.lua`
- `lualine.lua`
- `theme.lua`

Mantén separados los conceptos de tema, editor UI y barra de estado.

Evita hardcodear colores salvo petición explícita. Prioriza highlights compatibles con el tema activo.

## Agentes de OpenCode

Los agentes de OpenCode viven en:

```text
.opencode/agents/
```

Agentes actuales:

- `kvim-main.md`: orquestador principal.
- `kvim-core.md`: especialista en arquitectura core.
- `kvim-module.md`: especialista en módulos.
- `kvim-docs.md`: especialista en documentación.
- `kvim-tester.md`: especialista en testing.

El agente principal debe delegar trabajo especializado en lugar de hacerlo todo directamente.

Delegación esperada:

- usa `@kvim-core` para core, registry, runner, comandos y arquitectura global;
- usa `@kvim-module` para módulos funcionales;
- usa `@kvim-tester` para tests;
- usa `@kvim-docs` para README, documentación de módulos, changelog y documentación de uso.

## Reglas de código

Reglas generales:

- Usa Lua.
- Prioriza variables `local` explícitas.
- Evita variables globales accidentales.
- Mantén los módulos pequeños y enfocados.
- Evita dependencias circulares con `require`.
- Evita acoplar módulos directamente entre sí.
- Usa `pcall` al requerir plugins opcionales o integraciones externas.
- Mantén los callbacks de comandos ligeros.
- Coloca el comportamiento reutilizable en `actions.lua` o en archivos internos tipo servicio.
- Mantén los keymaps declarativos y con `desc`.
- Mantén testeable la construcción de comandos externos.

Indentación:

- Usa 4 espacios.
- Usa `expandtab`.

## Comandos y acciones

KVIM usa comandos personalizados y acciones registradas.

Conceptos de comandos conocidos:

- `:KvimAction`
- `:KvimModules`
- `:KvimRun`
- `:KvimTest`

Al añadir una funcionalidad:

1. Coloca el comportamiento reutilizable en `actions.lua`.
2. Haz que los comandos llamen a acciones.
3. Haz que los keymaps llamen a acciones.
4. Registra acciones públicas cuando corresponda.
5. Documenta comandos y keymaps nuevos.

## Testing

KVIM tiene una estructura de tests automatizados.

Los tests viven en:

```text
tests/
├── minimal_init.lua
├── core/
└── connections/
```

La estructura actual de tests es plana por área o módulo. No migres a `tests/modules/<module>/` salvo que se pida explícitamente o que el árbol de tests crezca lo suficiente como para justificarlo.

Comando preferido para tests:

```bash
./scripts/test.sh
```

Comando directo alternativo:

```bash
nvim --headless -u tests/minimal_init.lua -c "PlenaryBustedDirectory tests" -c "qa!"
```

Los tests deben usar:

- Neovim headless;
- `plenary.nvim`;
- `busted`;
- mocks para comandos externos.

Reglas de testing:

- No dependas de servidores SSH reales salvo que estés escribiendo tests de integración explícitos.
- No dependas de claves privadas reales.
- No dependas de acceso a red.
- Mockea `vim.system` para comandos externos.
- Mockea `vim.notify` cuando compruebes notificaciones.
- Mockea `vim.keymap.set` cuando compruebes keymaps.
- Mockea `vim.api.nvim_create_user_command` cuando compruebes comandos.
- Restaura el estado global después de cada test.
- No cambies expectativas solo para ocultar fallos.

## Documentación

La documentación vive principalmente en:

- `README.md`
- `CHANGELOG.md`
- `AGENTS.md`
- `nvim/lua/kvim/modules/connections/README.md`
- `nvim/lua/kvim/modules/git/README.md`
- `nvim/lua/kvim/modules/svn/README.md`
- `nvim/lua/kvim/plugins/README.md`

No crees automáticamente una carpeta superior `docs/`. Créala solo si se solicita explícitamente o si la documentación empieza a ser demasiado grande para mantenerla en los README actuales.

Cuando cambie comportamiento público, actualiza documentación si el cambio afecta a:

- comandos;
- keymaps;
- configuración de módulos;
- acciones;
- providers;
- comandos de test;
- comportamiento visible para el usuario.

## Reglas de Git

No ejecutes estos comandos sin aprobación explícita del usuario:

```bash
git push
git merge
git rebase
git reset
git clean
rm -rf
```

Comandos seguros de solo lectura:

```bash
git status
git diff
git log
git branch
git show
```

Usa commits convencionales al sugerir mensajes de commit:

```text
feat(scope): descripción
fix(scope): descripción
refactor(scope): descripción
test(scope): descripción
docs(scope): descripción
chore(scope): descripción
```

Ejemplos:

```text
feat(ai): add opencode provider
test(connections): cover scp command generation
docs(modules): document git module
refactor(core): simplify action registry
```

## Flujo de trabajo de agentes

Antes de modificar código:

1. Inspecciona los archivos relevantes.
2. Identifica si la tarea afecta a core, módulos, tests o documentación.
3. Mantén el cambio localizado salvo que se pida explícitamente un refactor más amplio.
4. Añade o actualiza tests cuando cambie comportamiento.
5. Actualiza documentación cuando cambie el uso público.
6. Revisa el diff antes de finalizar.
7. Informa de los archivos modificados y de los próximos pasos recomendados.

## Reglas de seguridad

Nunca:

- guardes secretos;
- comitees claves privadas;
- hardcodees rutas absolutas personales;
- ejecutes comandos destructivos sin confirmación;
- modifiques módulos no relacionados;
- introduzcas dependencias ocultas de red en tests;
- asumas que las rutas de la arquitectura antigua siguen siendo válidas.

## Notas de arquitectura obsoleta

La arquitectura anterior de KVIM usaba referencias como:

- `nvim/lua/kvim/lazy.lua`
- `~/.config/nvim/configs.json`
- `nvim/lua/kvim/utils/`
- `nvim/lua/kvim/layouts/`
- testing manual únicamente mediante `:checkhealth`

Estas referencias están obsoletas para la estructura actual salvo que se reintroduzcan explícitamente.
