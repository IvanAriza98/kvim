# Changelog

All notable changes to KVIM will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- OpenCode integration for AI-assisted coding
- Typst language support (LSP, formatting)
- Mini Icons plugin for improved file icons
- Smear Cursor plugin for cursor trail effect
- Colorizer plugin for hex color preview

### Changed
- Improved lazy loading system for layouts (500ms deferred load)
- Updated LSP configurations for better compatibility

### Fixed
- Config caching mechanism with 5-second TTL
- USB device detection path stability (/dev/serial/by-id)

### Added (Unreleased Features)

#### Utils
- **config-utils.lua**: JSON config CRUD operations (dkjson-based)
  - `getConfigField(key1, key2)`: Retrieve config values
  - `setConfigField(value, key1, key2)`: Write config values
- **devices.lua**: Hardware device detection
  - `get_usb_devices()`: List ttyUSB/ttyACM devices
  - `get_nrf_devices()`: List Nordic devices via nrfjprog

#### Layouts (NUI-based)
- Deferred loading via `vim.defer_fn` for minimal startup impact
- FileType autocmd trigger (100ms) for main-menu and cmd-buffer
- VimEnter autocmd trigger (500ms) for config dialogs

## [1.0.0] - Initial Release

### Added
- **Plugin Manager**: lazy.nvim with lazy-loading by default
- **Language Server Protocol (LSP)**: 
  - Python (pyright)
  - C/C++ (clangd)
  - Lua (lua-language-server)
  - Dart/Flutter (dart)
  - Bash (bash-language-server)
  - JSON/YAML/XML/TOML via LSP
- **Debug Adapter Protocol (DAP)**:
  - Python (debugpy)
  - C/C++ (codelldb)
  - Lua (nvim-dap)
  - Dart (dart-debug-adapter)
  - Bash (bash-db)
- **Linting & Formatting**:
  - Python: ruff (lint), black (format)
  - C/C++: clang-format (format)
  - Lua: luacheck (lint), stylua (format)
  - Dart: dart analyze (lint), dart format (format)
  - Bash: shellcheck (lint), shfmt (format)
  - JSON/YAML/XML/TOML: prettier (format)
- **File Management**: Yazi integration with fuzzy finder (Telescope)
- **Terminal Integration**: ToggleTerm with SSH and SCP support
- **Embedded Systems Support**:
  - ESP-IDF: build, flash, monitor commands
  - Nordic NRF-SDK/Zephyr RTOS: build, flash, debug, RTT monitor
- **UI Enhancements**:
  - Alpha dashboard
  - Bufferline status line
  - NUI-based menu system
  - TokyoNight color scheme
- **Development Tools**:
  - Multi-cursor editing
  - Smart comments (60+ languages)
  - TODO highlights (TODO, FIXME, NOTE)
  - Autopairs
- **Configuration System**: JSON-based config stored in `~/.config/nvim/configs.json`

[unreleased]: https://github.com/kodvmv/kvim/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/kodvmv/kvim/releases/tag/v1.0.0
