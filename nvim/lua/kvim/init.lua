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

  -- Load LSP
  if config.lsp and config.lsp.enabled then
    require("kvim.core.lsp").setup()
  end
  -- Load extra modules ...
  for module_name, module_opts in pairs(config.modules or {}) do
    if module_opts.enabled then
        local ok, module = pcall(require, "kvim.modules." .. module_name)

        if not ok then
            vim.notify("Kvim failed to load module '" .. module_name .. "': " .. tostring(module), vim.log.levels.ERROR)
            goto continue
        end

        if type(module) ~= "table" then
            vim.notify("Kvim module must be a table: " .. module_name, vim.log.levels.ERROR)
            goto continue
        end

        if not module.name or module.name == "" then
                module.name = module_name
        end

        require("kvim.core.registry").register(module)
        if type(module.setup) == "function" then
                local ok_setup, err = pcall(module.setup, module_opts)
                if not ok_setup then
                    vim.notify("Kvim module setup failed for '" .. module_name .. "': " .. tostring(err), vim.log.levels.ERROR)
                end
        end
    end

    ::continue::
  end

  if config.keymaps and config.keymaps.enabled then
    require("kvim.core.keymaps").setup()
  end
end

function M.register_module(module)
  require("kvim.core.registry").register(module)
end

function M.run_action(module_name, action_name)
  require("kvim.core.registry").run_action(module_name, action_name)
end

function M.get_modules()
  return require("kvim.core.registry").get_modules()
end

return M
