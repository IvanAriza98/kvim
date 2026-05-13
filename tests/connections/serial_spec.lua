describe("kvim.modules.connections.serial", function()
  local serial = require("kvim.modules.connections.serial")

  it("builds picocom command", function()
    local conn = {
      type = "serial",
      baudrate = 115200,
      device = "/dev/ttyACM0",
    }

    local cmd, err = serial.build_command(conn)

    assert.is_nil(err)
    assert.is_not_nil(cmd)


    assert.matches("picocom", cmd)
    assert.matches("115200", cmd)
    assert.matches("/dev/ttyACM0", cmd)
  end)

  it("fails without device", function()
    local conn = {
      type = "serial",
      baudrate = 115200,
    }

    local cmd, err = serial.build_command(conn)

    assert.is_nil(cmd)
    assert.is_not_nil(err)
  end)

  it("fails without type", function()
    local conn = {
      baudrate = 115200,
      device = "/dev/ttyACM0",
    }

    local cmd, err = serial.build_command(conn)

    assert.is_nil(cmd)
    assert.is_not_nil(err)
  end)

  it("fails without table variable", function()
    local conn = "/dev/ttyACM0"
    local cmd, err = serial.build_command(conn)

    assert.is_nil(cmd)
    assert.is_not_nil(err)
  end)
end)
