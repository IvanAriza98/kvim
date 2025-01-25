-- Modificar el package.path y package.cpath para usar Lua 5.4
package.path = package.path .. ";/usr/lib/lua/5.4/?.lua"
package.cpath = package.cpath .. ";/usr/lib/lua/5.4/?.so"

require("config.lazy")
