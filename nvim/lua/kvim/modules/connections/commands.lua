-- lua/kvim/modules/connections/commands.lua

local M = {}

function M.setup(opts)
  opts = opts or {}

  local actions = require("kvim.modules.connections.actions")

  vim.api.nvim_create_user_command("KvimConnections", function()
    actions.open_all_picker(opts)
  end, {
    desc = "Open KVIM connections picker",
  })

  vim.api.nvim_create_user_command("KvimSshConnections", function()
    actions.open_ssh_picker(opts)
  end, {
    desc = "Open KVIM SSH connections picker",
  })

  vim.api.nvim_create_user_command("KvimSerialConnections", function()
    actions.open_serial_picker(opts)
  end, {
    desc = "Open KVIM serial connections picker",
  })

  vim.api.nvim_create_user_command("KvimConnectionsReload", function()
    actions.reload_config(opts)
  end, {
    desc = "Reload KVIM connections config",
  })

  vim.api.nvim_create_user_command("KvimConnectionsGenerateKey", function()
    actions.generate_ssh_key_picker(opts)
  end, {
    desc = "Generate SSH key for selected KVIM connection",
  })

  vim.api.nvim_create_user_command("KvimConnectionsInstallKey", function()
    actions.install_ssh_key_picker(opts)
  end, {
    desc = "Install SSH public key for selected KVIM connection",
  })

  vim.api.nvim_create_user_command("KvimConnectionsTestSsh", function()
    actions.test_ssh_connection_picker(opts)
  end, {
    desc = "Test selected KVIM SSH connection",
  })
end

return M
