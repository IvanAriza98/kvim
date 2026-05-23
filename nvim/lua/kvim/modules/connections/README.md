# KVIM Connections Module

Módulo para gestionar conexiones SSH y serie desde KVIM.

Incluye:
- pickers de conexiones;
- apertura de terminales para sesión remota/serie;
- conexión activa en memoria;
- utilidades SSH (generar/instalar/testear claves);
- transferencia de archivos/directorios por SCP;
- ejecución remota de comandos (`KvimSSHRun`).

---

## Requisitos de sistema

Según funcionalidad:

- `ssh` (sesiones SSH y ejecución remota)
- `scp` (subida/bajada de archivos)
- `picocom` u otro comando serie configurado en la conexión
- `ssh-keygen` / `ssh-copy-id` (operaciones de claves, según entorno)

---

## Configuración

Archivo por defecto de conexiones:

```text
~/.config/nvim/lua/kvim/connections.lua
```

Debe devolver una **tabla Lua** con conexiones.

Ejemplo mínimo:

```lua
return {
    {
        type = "ssh",
        name = "srv-dev",
        host = "192.168.1.10",
        user = "dev",
        port = 22,
        identity_file = "~/.ssh/id_ed25519",
        remote_root = "/home/dev/project",
        transfer = {
            remote_root = "/home/dev/project",
            local_root = "~/Downloads",
        },
    },
    {
        type = "serial",
        name = "uart-esp32",
        device = "/dev/ttyUSB0",
        baudrate = 115200,
        command = "picocom",
    },
}
```

---

## Comandos disponibles

- `:KvimConnections` → abre picker de todas las conexiones.
- `:KvimSshConnections` → abre picker solo SSH.
- `:KvimSerialConnections` → abre picker solo serie.
- `:KvimConnectionsReload` → recarga archivo de configuración.

### SSH keys / test

- `:KvimConnectionsGenerateKey`
- `:KvimConnectionsInstallKey`
- `:KvimConnectionsTestSsh`

### Conexión activa

- `:KvimConnectionSetActive` → selecciona conexión activa.
- `:KvimSSHConnectionSetActive` → selecciona conexión SSH activa.
- `:KvimConnectionShowActive` → muestra conexión activa.
- `:KvimConnectionClearActive` → limpia conexión activa.

### Ejecución remota y transferencias

- `:KvimSSHRun [comando]`
- `:KvimSSHUploadCurrent`
- `:KvimSSHUploadPath [ruta_local]`
- `:KvimSSHDownloadPath [ruta_remota]`

---

## Keymaps (por defecto)

Prefijo configurable por módulo (`opts.prefix`), valor por defecto: `<leader>c`.

- `<leader>cc` → `:KvimConnections`
- `<leader>cs` → `:KvimSshConnections`
- `<leader>cu` → `:KvimSerialConnections`
- `<leader>cr` → `:KvimConnectionsReload`
- `<leader>ckg` → `:KvimConnectionsGenerateKey`
- `<leader>cki` → `:KvimConnectionsInstallKey`
- `<leader>ckt` → `:KvimConnectionsTestSsh`

---

## Notas de comportamiento real

- La conexión activa se mantiene en memoria de sesión (estado runtime), no persistida en disco.
- `KvimSSHRun` requiere conexión activa y de tipo `ssh`.
- En transferencias:
  - `upload` detecta si la ruta local es archivo/directorio;
  - `download` usa `scp -r` para cubrir ambos casos.
- Si falta el archivo de configuración, el módulo notifica warning y devuelve lista vacía.
