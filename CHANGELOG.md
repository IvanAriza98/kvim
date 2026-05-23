# Changelog

Todos los cambios relevantes de KVIM se documentan en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/)
y el proyecto sigue [Semantic Versioning](https://semver.org/lang/es/).

## [Unreleased]

### Added
- Cobertura de tests para componentes de UI (`tests/ui/*`), incluyendo inicialización, editor, lualine y tema.
- Nuevos casos de test para core LSP (`tests/core/lsp/*`) y validaciones de keymaps/diagnósticos.
- Más cobertura en core para comandos, keymaps, terminal, registry y runner.

### Changed
- Endurecimiento del core (hardening) con validaciones explícitas en registro y ejecución de acciones:
  - validación de tipos en módulos/acciones;
  - mensajes de error más claros en `registry` y `runner`;
  - protección adicional al ejecutar callbacks de acciones.
- Ajustes en tests globales de runner para reflejar el comportamiento actual de apertura de terminal y expansión de placeholders.
- Consolidación de comandos y keymaps sobre la arquitectura modular vigente (`core` + `modules/*`).

### Fixed
- Correcciones en cobertura y estabilidad de tests al ejecutar toda la suite en modo headless.
- Mejor consistencia en comportamiento de runner ante comandos inválidos.
- Ajustes menores en flujo de LSP/diagnósticos y pruebas asociadas.

---

## [1.0.0] - 2026-01-01

### Added
- Base modular de KVIM sobre Neovim + Lua.
- Core con registry, runner, comandos y keymaps globales.
- Módulos iniciales: `connections`, `git` y `svn`.
- Integración de plugins con `lazy.nvim`.
- Suite de tests automatizados con `plenary.nvim` + `busted`.

[unreleased]: https://github.com/kodvmv/kvim/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/kodvmv/kvim/releases/tag/v1.0.0
