describe("kvim.modules.connections.state", function()
  local state = require("kvim.modules.connections.state")

  before_each(function()
    state.clear_active_connection()
    state.clear_connection_buffer("ssh-test")
  end)

  it("starts without active connection", function()
    assert.is_nil(state.get_active_connection())
    assert.is_false(state.has_active_connection())
  end)

  it("sets active SSH connection", function()
    local conn = {
      name = "SSH Test",
      type = "ssh",
      host = "127.0.0.1",
      user = "test",
      port = 2222,
    }

    state.set_active_connection(conn)

    assert.are.same(conn, state.get_active_connection())
    assert.is_true(state.has_active_connection())
  end)

  it("sets active Serial connection", function()
    local conn = {
      name = "Serial Test",
      type = "serial",
      device = "/dev/ttyUSB0",
      baudrate = 115200,
    }

    state.set_active_connection(conn)

    assert.are.same(conn, state.get_active_connection())
    assert.is_true(state.has_active_connection())
  end)

  it("stores connection buffer by name", function()
    state.set_connection_buffer("ssh-test", 42)

    assert.are.equal(42, state.get_connection_buffer("ssh-test"))
  end)

  it("clears connection buffer by name", function()
    state.set_connection_buffer("ssh-test", 42)
    state.clear_connection_buffer("ssh-test")

    assert.is_nil(state.get_connection_buffer("ssh-test"))
  end)

end)
