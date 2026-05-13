describe("kvim.modules.connections.ssh", function()
  local ssh = require("kvim.modules.connections.ssh")


  it("build ssh command with port and identity file", function()
    local conn = {
        type = "ssh",
        host = "127.0.0.1",
        user = "test",
        port = 2222,
        identity_file = "~/.ssh/key",
    }

    local cmd, err = ssh.build_command(conn)
    assert.is_nil(err)
    assert.is_not_nil(cmd)

    assert.matches("ssh", cmd)
    assert.matches("-p '2222'", cmd)
    assert.matches("-i '~/.ssh/key'", cmd)
    assert.matches("'test@127.0.0.1'", cmd)
  end)

  it("fails without host", function()
    local conn = {
        type = "ssh",
        user = "test",
    }

    local cmd, err = ssh.build_command(conn)

    assert.is_nil(cmd)
    assert.is_not_nil(err)
  end)

  it("fails without type", function()
    local conn = {
        host = "127.0.0.1",
        user = "test",
    }

    local cmd, err = ssh.build_command(conn)

    assert.is_nil(cmd)
    assert.is_not_nil(err)
  end)

  it("fails without table variable", function()
    local conn = "127.0.0.1"
    local cmd, err = ssh.build_command(conn)

    assert.is_nil(cmd)
    assert.is_not_nil(err)
  end)

end)

