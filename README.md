# KVIM

A powerful Neovim configuration designed to replace multiple specialized programs with a single CLI-based IDE. Because you shouldn't need a separate tool for every task.

## Features

### General Development
- **Smart Autocomplete** - LSP integration with intelligent code completion, snippets, and syntax highlighting
- **Debugging** - Visual DAP interface for debugging multiple languages
- **Multi-Cursor Editing** - VSCode-like multi-cursor support
- **File Management** - Ultra-fast file manager with Yazi + fuzzy finder with Telescope
- **Integrated Terminal** - Embedded terminals with directional splits and SSH support
- **Smart Comments** - Intelligent commenting for 60+ languages

### Supported Languages
| Language | LSP | Linter | Formatter | Debugger |
|----------|-----|--------|-----------|----------|
| Python | pyright | ruff | black | debugpy |
| C/C++ | clangd | - | clang-format | codelldb |
| Lua | lua-language-server | luacheck | stylua | nvim-dap |
| Dart/Flutter | dart | dart analyze | dart format | dart-debug-adapter |
| Bash | bash-language-server | shellcheck | shfmt | bash-db |
| JSON/YAML/XML/TOML | via LSP | - | prettier | - |

### Embedded Systems Development
- **ESP-IDF** - Build, flash, and monitor ESP32 projects
- **Nordic NRF-SDK / Zephyr RTOS** - Build, flash, debug with JLink, RTT monitor

### AI Assistance
- **OpenCode** - Integrated AI coding assistant

## Quick Start

### Prerequisites

**Required:**
```bash
# Neovim (>= 0.9.0)
# Git
# A Nerd Font (for icons)
```

**Recommended:**
```bash
# ripgrep      - Enhanced search
#lazygit      - Git UI
# lynx         - URL preview
#luarocks     - Lua packages
#lsof          - Serial port detection
```

**For embedded development:**
```bash
# ESP-IDF or NRF-SDK installed on your system
# nrfjprog     - Nordic programmer (NRF devices)
# esptool.py   - ESP programmer (ESP32 devices)
```

### Installation

```bash
# Backup existing config
mv ~/.config/nvim ~/.config/nvim.bak

# Clone KVIM
git clone https://github.com/kodvmv/kvim.git ~/.config/nvim

# Start Neovim
nvim
```

Lazy.nvim will automatically install all plugins on first launch.

## Keybindings

### General
| Key | Action |
|-----|--------|
| `s` | Save file |
| `q` | Quit |
| `<ESC>` | Clear search highlight |
| `<leader>fp` | Open Yazi at current file |
| `<leader>cw` | Open Yazi at working directory |
| `<leader>k` | Open main menu |

### Terminal
| Key | Action |
|-----|--------|
| `<C-t>h/j/k/l` | Open terminal in split direction |
| `<C-t>rh/rv/rf` | SSH in hsplit/vsplit/float |
| `<C-t>af` | Send current file via SCP |

### LSP (when server active)
| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gR` | Find references |
| `gi` | Find implementations |
| `gt` | Go to type definition |
| `<leader>ca` | Code actions |
| `<leader>rn` | Smart rename |
| `K` | Hover documentation |
| `[d` / `]d` | Previous/next diagnostic |

### Debug (DAP)
| Key | Action |
|-----|--------|
| `<Leader>db` | Toggle breakpoint |
| `<Leader>dc` | Continue |
| `<Leader>di` | Step into |
| `<Leader>do` | Step out |
| `<Leader>ds` | Step over |

### Embedded Projects (ESP-IDF / NRF)
| Key | Action |
|-----|--------|
| `<F5>` | Build project |
| `<F6>` | Flash device |
| `<F7>` | Monitor/RTT |
| `<F8>` | Debug session |

## Project Structure

```
nvim/
├── init.lua                 # Entry point
└── lua/kvim/
    ├── lazy.lua             # Plugin manager
    ├── core/                # Neovim core config
    ├── plugins/             # Plugin specifications
    ├── utils/               # Custom utilities
    └── layouts/             # UI components
```

## Configuration

KVIM stores configuration in `~/.config/nvim/configs.json`. On first run, it will create a default configuration. You can customize:

- Project paths
- SDK locations (ESP-IDF, NRF)
- Default build commands
- SSH configurations

## Screenshots

Check the `screenshots/` directory for UI previews.

## Credits

Built with [lazy.nvim](https://github.com/folke/lazy.nvim), [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig), [Telescope](https://github.com/nvim-telescope/telescope.nvim), [Yazi](https://github.com/sxyazi/yazi), and many more amazing plugins.

## License

MIT
