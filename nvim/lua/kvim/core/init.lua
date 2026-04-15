-- lua/kvim/core/init.lua

-- Añadir path del sistema para módulos luarocks (dkjson, etc.)
package.path = package.path .. ";/usr/share/lua/5.4/?.lua;/usr/share/lua/5.4/?/init.lua"

require("kvim.core.options")
require("kvim.core.keymaps")
require("kvim.core.autocmds")
require("kvim.env")
require("kvim.commands")
