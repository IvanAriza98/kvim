# Changelog

Todos los cambios relevantes de KVIM se documentan en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/)
y el proyecto sigue [Semantic Versioning](https://semver.org/lang/es/).

## [Unreleased]

### Added
- Cobertura de tests para componentes de UI (`tests/ui/*`), incluyendo inicialización, editor, lualine y tema.
- Nuevos casos de test para core LSP (`tests/core/lsp/*`) y validaciones de keymaps/diagnósticos.
- Más cobertura en core para comandos, keymaps, terminal, registry y runner.
- Integración de `dressing.nvim` para mejorar `vim.ui.select()` y `vim.ui.input()`.

### Changed
- Refresco importante de la documentación raíz para reflejar el estado real actual de KVIM:
  - arquitectura `core + modules + plugins + ui`;
  - comandos y keymaps públicos vigentes;
  - stack de UI actual (`noice`, `dressing`, `notify`, `bufferline`, `dashboard`);
  - cobertura de testing e instaladores.
- Endurecimiento del core con validaciones explícitas en registro y ejecución de acciones:
  - validación de tipos en módulos/acciones;
  - mensajes de error más claros en `registry` y `runner`;
  - protección adicional al ejecutar callbacks de acciones.
- Consolidación de la UX de workspaces con tabs lógicas `Code` / `Term` y badges en bufferline.
- Ajustes recientes en la command palette de `noice.nvim` para mantenerla centrada y más compacta.
- Ajustes en tests globales de runner para reflejar el comportamiento actual de apertura de terminal y expansión de placeholders.
- Consolidación de comandos y keymaps sobre la arquitectura modular vigente (`core` + `modules/*`).

### Fixed
- Correcciones en cobertura y estabilidad de tests al ejecutar toda la suite en modo headless.
- Mejor consistencia en comportamiento de runner ante comandos inválidos.
- Ajustes menores en flujo de LSP/diagnósticos y pruebas asociadas.
- Mejor consistencia visual entre command palette, selectores e inputs al usar `noice.nvim` + `dressing.nvim`.

---

## [1.0.0] - 2026-01-01

### Added
- Base modular de KVIM sobre Neovim + Lua.
- Core con registry, runner, comandos y keymaps globales.
- Módulos iniciales de uso público:
  - `workspaces`
  - `connections`
  - `git`
  - `svn`
- Integración de plugins con `lazy.nvim` y separación por áreas (`ui`, `editor`, `navigation`, `dashboard`, `completion`, `lsp`).
- UI base con Catppuccin, Lualine, Telescope, Neo-tree, Yazi y dashboard.
- Suite de tests automatizados con `plenary.nvim` + `busted`.
- Instaladores para Linux y Windows con launcher `kvim`.

[unreleased]: https://github.com/kodvmv/kvim/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/kodvmv/kvim/releases/tag/v1.0.0
