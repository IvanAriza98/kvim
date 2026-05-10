# KVIM Connections Module

Connection manager for KVIM.

This module provides a simple launcher for SSH and serial connections using KVIM terminal windows.

## Depends

```
sudo pacman -Sy picocom ssh screen
```

## Features

- SSH connection picker
- Serial/UART connection picker
- Configurable connections file
- Opens sessions in styled KVIM terminal windows
- Supports `ssh`, `picocom`, `screen` and `minicom`

## Commands

| Command | Description |
|---|---|
| `:KvimConnections` | Open all connections |
| `:KvimSshConnections` | Open SSH connections |
| `:KvimSerialConnections` | Open serial connections |
| `:KvimConnectionsReload` | Reload connections config |

## Keymaps

Default prefix: `<leader>c`

| Keymap | Description |
|---|---|
| `<leader>cc` | Open all connections |
| `<leader>cs` | Open SSH connections |
| `<leader>cu` | Open serial connections |
| `<leader>cr` | Reload config |

## Configuration

Default config file:

```text
~/.config/nvim/kvim/connections.lua


