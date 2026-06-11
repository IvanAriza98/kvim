# 0001 - Linux Installer

## Objetivo

Crear un instalador Linux para KVIM que permita instalar y ejecutar el IDE usando Neovide y la configuración propia de KVIM.
El instalador debe preparar el entorno mínimo necesario para ejecutar KVIM sin sobrescribir la configuración normal de Neovim del usuario.
KVIM debe ejecutarse usando `NVIM_APPNAME=kvim`.

## Alcance

Esta feature cubre únicamente el instalador Linux.

Debe implementar:

- Verificación de Neovim.
- Verificación de Neovide.
- Verificación de lazy.nvim.
- Instalación o preparación de la configuración KVIM.
- Selección opcional de dependencias por módulos.
- Launcher `kvim`.
- Uso de `NVIM_APPNAME=kvim`.
- Advertencias claras si faltan dependencias.
- Instalación en rutas de usuario.

No debe implementar todavía:

- Instalador Windows.
- AppImage.
- Paquetes `.deb`, `.rpm` o `.pkg.tar.zst`.
- Actualizador automático.
- Desinstalador completo.
- Gestión avanzada de versiones.
- Instalación de toolchains complejas de lenguajes.

## Rutas

El instalador debe usar estas rutas:

```text
~/.config/kvim
~/.local/share/kvim
~/.local/bin/kvim
~/.local/share/applications/kvim.desktop
