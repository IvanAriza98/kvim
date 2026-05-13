describe("kvim.modules.connections.config", function()
  local config = require("kvim.modules.connections.config")

  it("filters connections by type", function()
    local connections = {
      { name = "SSH Test", type = "ssh" },
      { name = "Serial Test", type = "serial" },
      { name = "Other", type = "unknown" },
    }

    local result = config.filter_by_type(connections, "ssh")

    assert.are.equal(1, #result)
    assert.are.equal("SSH Test", result[1].name)
  end)

  it("returns empty list when no type matches", function()
    local connections = {
      { name = "Serial Test", type = "serial" },
    }

    local result = config.filter_by_type(connections, "ssh")

    assert.are.equal(0, #result)
  end)

  it("return default config file", function()
    assert.is_not_nil(config.get_config_file())
  end)
end)
