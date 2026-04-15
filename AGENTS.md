# KVIM - Neovim Configuration

## Architecture

- **Plugin manager**: lazy.nvim (lazy-loaded by default)
- **Config entry**: `nvim/init.lua` -> `nvim/lua/kvim/lazy.lua`
- **Configuration storage**: `~/.config/nvim/configs.json` (JSON, not Lua)
- **Plugin specs**: `nvim/lua/kvim/plugins/` (one file per plugin)
- **Core config**: `nvim/lua/kvim/core/` (options, keymaps, autocmds)
- **Custom commands**: `nvim/lua/kvim/utils/` (embedded dev tools, SSH, Python)
- **UI layouts**: `nvim/lua/kvim/layouts/` (nvzone/menu based menus)

## Environment

- **Required**: `KVIM_HOME` environment variable pointing to config root
- **Config path**: `{KVIM_HOME}/nvim/configs.json`

## Code Style

- **Indent**: 4 spaces (expandtab)
- **Lua formatter**: stylua
- **Lua linter**: luacheck

## Linting Commands

```bash
# Lint all Lua files
luacheck nvim/lua/

# Format all Lua files (requires stylua installed)
stylua nvim/lua/
```

## Embedded Development

The config includes custom build/flash/debug commands for ESP-IDF and Nordic NRF-SDK. These are defined in `utils/esp-idf-commands.lua` and `utils/nrf-sdk-commands.lua`. They read settings from `configs.json`:
- `esp_idf`: family, port, appPath, idfPath
- `nrf_sdk`: workspacePath, projectName, application, snDevice, boardTarget, etc.

## Key Conventions

1. `mapleader` must be set before loading lazy.nvim
2. Lazy-loaded plugins use event triggers; core modules load eagerly
3. Layouts use VeryLazy event trigger to avoid startup delays
4. Config utils use dkjson for JSON parsing (no external deps for config)

## Testing

No formal test suite. Manual verification required - run `:checkhealth` in Neovim.
