describe("kvim.modules.connections.transfer", function()
  local transfer = require("kvim.modules.connections.transfer")

  local original_system
  local original_notify

  before_each(function()
    original_system = vim.system
    original_notify = vim.notify
    vim.notify = function() end
  end)

  after_each(function()
    vim.system = original_system
    vim.notify = original_notify
  end)

  it("runs scp when uploading path", function()
    local captured_cmd = nil

    vim.system = function(cmd, opts, callback)
      captured_cmd = cmd

      callback({
        code = 0,
        stdout = "",
        stderr = "",
      })
    end

    local conn = {
      user = "test",
      host = "127.0.0.1",
      port = 2222,
      transfer = {
        remote_root = "/home/test",
      },
    }

    transfer.upload_path(conn, "tests/connections/state_spec.lua")
    assert.is_not_nil(captured_cmd)

    local joined = table.concat(captured_cmd, " ")

    assert.matches("^scp", joined)
    assert.matches("%-P 2222", joined)
    assert.matches("test@127%.0%.0%.1:/home/test/state_spec.lua", joined)
  end)

    it("runs scp when uploading directory", function()
      local captured_cmd = nil

      vim.system = function(cmd, opts, callback)
        captured_cmd = cmd

        callback({
          code = 0,
          stdout = "",
          stderr = "",
        })
      end

      local conn = {
        user = "test",
        host = "127.0.0.1",
        port = 2222,
        transfer = {
          remote_root = "/home/test",
        },
      }

      transfer.upload_path(conn, "tests/connections")

      assert.is_not_nil(captured_cmd)

      local joined = table.concat(captured_cmd, " ")

      assert.matches("%-r", joined)
      assert.matches("^scp", joined)
      assert.matches("%-P 2222", joined)
      assert.matches("test@127%.0%.0%.1:/home/test/connections", joined)
    end)
end)
