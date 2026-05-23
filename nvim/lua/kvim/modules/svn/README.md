# KVIM SVN Module

Módulo para operaciones SVN desde KVIM usando terminal flotante.

Funcionalidades actuales:
- abrir `lazysvn`;
- mostrar `svn info`;
- mostrar `svn status`.

---

## Requisitos

- `svn` (obligatorio)
- `lazysvn` (solo para `KvimLazySvn`)
- estar dentro de una working copy SVN para ejecutar acciones

---

## Comandos

- `:KvimLazySvn` → abre `lazysvn` en terminal flotante.
- `:KvimSvnInfo` → ejecuta `svn info` en terminal flotante.
- `:KvimSvnStatus` → ejecuta `svn status` en terminal flotante.

---

## Keymaps

Prefijo interno por defecto: `<leader>s`.

- `<leader>sv` → `:KvimLazySvn`
- `<leader>si` → `:KvimSvnInfo`
- `<leader>ss` → `:KvimSvnStatus`

---

## Comportamiento real y validaciones

Antes de ejecutar comandos, el módulo valida:

1. que exista binario `svn`;
2. que el directorio actual sea una working copy SVN;
3. para `LazySVN`, que exista binario `lazysvn`.

Si falla una validación, muestra `vim.notify` y no ejecuta la acción.

La salida se muestra en una ventana flotante:
- `<Esc>` en terminal para volver a normal mode;
- `q` en normal mode para cerrar la ventana.
