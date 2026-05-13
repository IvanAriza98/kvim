describe("kvim.modules.connections.commands", function()
  it("registers user commands", function()
    local commands = require("kvim.modules.connections.commands")

    commands.setup({})

    local registered = vim.api.nvim_get_commands({})

    assert.is_not_nil(registered.KvimConnections)
    assert.is_not_nil(registered.KvimSshConnections)
    assert.is_not_nil(registered.KvimSerialConnections)
    assert.is_not_nil(registered.KvimConnectionShowActive)
    assert.is_not_nil(registered.KvimSSHUploadCurrent)
  end)
end)
