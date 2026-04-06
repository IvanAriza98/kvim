Needs several tools:

- tiktoken-core - bindign f rust tiktoken to lua
  yay -Sy lua51-tiktoken-bin
- repgrip - to improved search performance
  sudo pacman -Sy ripgrep
- lynx - to improved URL context features
  sudo pacman -Sy lynx
- git - to use repositories
  sudo pacman -Sy git
- luarocks - ?
- sudo pacman -Sy lsof --> to nrf-sdk (serial debug)

LSP         -> Intelligent
DAP         -> Debug
Linker      -> Syntax errors, recommendations
Formatter   -> Structure organization

- Helpers (LSP, DAP, Linker, Formatter?)
    -Python
        - LSP: pyright
        - DAP: debugpy
        - Linter: ruff
        - Formater: black
    -C/C++
        - LSP: clangd
        - DAP: codelldb
        - Linter:
        - Formatter:clang-format 
    -Dart
        - LSP: dart
        - DAP: dart-debug-adapter
        - Linter: dart analyze
        - Formatter: dart format
    -Lua
        - LSP: lua-language-server
        - DAP: nvim-dap + mobdebug
        - Linter: luacheck
        - Formatter: stylua
    -Bash
        - LSP: bashls
        - DAP: bash-debug-adapter
        - Linter: shellcheck
        - Formatter: shfmt


- LSP Configure:
    -JSON
        - LSP: jsonls
        - Linter: jsonlint 
        - Formatter: prettier, jq
    -YAML
        - LSP: yamlls
        - Linter: yamllint
        - Formatter: prettier,yamlfmt
    -XML
        - LSP: lemminx
        - Linter: xmllint
        - Formatter: xmlformat, prettier-plugin-xml
    -TOML
        - LSP: taplo
        - Linter: taplo
        - Formatter: taplo 
    -INI
        -Linter: inilint
        -Formatter: prettier-plugin-ini


- BE CAREFUL! to install icons need to instal nerdtree font with pacman and configure .json in WSL (Winch Arch)


