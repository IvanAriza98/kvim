-- lua/kvim/init.lua

local M = {}

function M.setup(opts)
  opts = opts or {}

  require("kvim.config").setup(opts)
  require("kvim.core.commands").setup()

  local config = require("kvim.config").get()
   
  -- UI/editor base
  if config.ui and config.ui.enabled then
    require("kvim.ui").setup()
  end

  -- Theme base
  if config.ui.theme and config.ui.theme.enabled then
    require("kvim.ui.theme").setup()
  end

  for _, module_name in ipairs(config.modules) do
    require("kvim.core.modules." .. module_name)
  end

  if config.keymaps and config.keymaps.enabled then
    require("kvim.core.keymaps").setup()
  end
end

function M.register_module(module)
  require("kvim.core.registry").register(module)
end

function M.run_action(module_name, action_name)
  require("kvim.registry").run_action(module_name, action_name)
end

function M.get_modules()
  return require("kvim.registry").get_modules()
end

return M
