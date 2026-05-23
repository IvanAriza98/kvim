# KVIM Git Module

Módulo de integración Git basado en LazyGit.

Expone acciones, comandos y keymaps para abrir:
- LazyGit general;
- LazyGit sobre el archivo actual;
- configuración de LazyGit.

---

## Requisitos

- `git`
- `lazygit`
- Plugin LazyGit declarado en `nvim/lua/kvim/modules/git/plugins.lua`

---

## Comandos

- `:KvimGit` → abre LazyGit.
- `:KvimGitFile` → abre LazyGit en contexto del archivo actual.
- `:KvimGitConfig` → abre pantalla de configuración de LazyGit.

Internamente ejecuta:
- `:LazyGit`
- `:LazyGitCurrentFile`
- `:LazyGitConfig`

---

## Keymaps actuales

Definidos en `keymaps.lua`:

- `<leader>g` → acción `git.open`
- `<leader>f` → acción `git.open_current_file`
- `<leader>c` → acción `git.config`

> Nota: en el estado actual estos keymaps están hardcodeados en el módulo y no usan `opts.prefix`.

---

## Acciones registradas

- `open`
- `open_current_file`
- `config`

Se ejecutan vía registry (`kvim.run_action("git", "...")`) y callbacks Lua.
