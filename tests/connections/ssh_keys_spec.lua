describe("kvim.modules.connections.ssh_keys", function()
  local ssh_keys

  local original_notify
  local original_executable
  local original_filereadable
  local original_readfile
  local original_has
  local original_mkdir
  local original_terminal
  local original_ssh

  local notifications
  local opened_commands
  local mkdir_calls

  before_each(function()
    package.loaded["kvim.modules.connections.ssh_keys"] = nil

    ssh_keys = require("kvim.modules.connections.ssh_keys")

    notifications = {}
    opened_commands = {}
    mkdir_calls = {}

    original_notify = vim.notify
    original_executable = vim.fn.executable
    original_filereadable = vim.fn.filereadable
    original_readfile = vim.fn.readfile
    original_has = vim.fn.has
    original_mkdir = vim.fn.mkdir
    original_terminal = package.loaded["kvim.core.terminal"]
    original_ssh = package.loaded["kvim.modules.connections.ssh"]

    vim.notify = function(message, level)
      table.insert(notifications, {
        message = message,
        level = level,
      })
    end

    vim.fn.executable = function()
      return 1
    end

    vim.fn.filereadable = function()
      return 0
    end

    vim.fn.readfile = function()
      return { "ssh-ed25519 AAAATESTKEY windows@test" }
    end

    vim.fn.has = function()
      return 0
    end

    vim.fn.mkdir = function(path, flags)
      table.insert(mkdir_calls, {
        path = path,
        flags = flags,
      })
      return 1
    end

    package.loaded["kvim.core.terminal"] = {
      open_command = function(cmd, opts)
        table.insert(opened_commands, {
          cmd = cmd,
          opts = opts,
        })
      end,
    }
  end)

  after_each(function()
    vim.notify = original_notify
    vim.fn.executable = original_executable
    vim.fn.filereadable = original_filereadable
    vim.fn.readfile = original_readfile
    vim.fn.has = original_has
    vim.fn.mkdir = original_mkdir

    package.loaded["kvim.core.terminal"] = original_terminal
    package.loaded["kvim.modules.connections.ssh"] = original_ssh

    package.loaded["kvim.modules.connections.ssh_keys"] = nil
  end)

  it("returns default key path", function()
    local path = ssh_keys.default_key_path()

    assert.are.equal(
      vim.fn.expand("~/.ssh/kvim_connections_ed25519"),
      path
    )
  end)

  it("returns connection identity_file when configured", function()
    local conn = {
      type = "ssh",
      name = "Docker SSH Test",
      identity_file = "~/.ssh/custom_key",
    }

    local path = ssh_keys.key_path_for_connection(conn)

    assert.are.equal(vim.fn.expand("~/.ssh/custom_key"), path)
  end)

  it("generates key path from connection name", function()
    local conn = {
      type = "ssh",
      name = "Docker SSH Test",
    }

    local path = ssh_keys.key_path_for_connection(conn)

    assert.are.equal(
      vim.fn.expand("~/.ssh/kvim_docker_ssh_test_ed25519"),
      path
    )
  end)

  it("generates sanitized key path from connection name", function()
    local conn = {
      type = "ssh",
      name = "Raspberry Pi @ Home!",
    }

    local path = ssh_keys.key_path_for_connection(conn)

    assert.are.equal(
      vim.fn.expand("~/.ssh/kvim_raspberry_pi_home_ed25519"),
      path
    )
  end)

  it("uses fallback key path when connection is nil", function()
    local path = ssh_keys.key_path_for_connection(nil)

    assert.are.equal(
      vim.fn.expand("~/.ssh/kvim_connection_ed25519"),
      path
    )
  end)

  it("detects private key exists", function()
    vim.fn.filereadable = function(path)
      if path == vim.fn.expand("~/.ssh/key") then
        return 1
      end

      return 0
    end

    assert.is_true(ssh_keys.key_exists("~/.ssh/key"))
  end)

  it("detects private key missing", function()
    vim.fn.filereadable = function()
      return 0
    end

    assert.is_false(ssh_keys.key_exists("~/.ssh/key"))
  end)

  it("detects public key exists", function()
    vim.fn.filereadable = function(path)
      if path == vim.fn.expand("~/.ssh/key") .. ".pub" then
        return 1
      end

      return 0
    end

    assert.is_true(ssh_keys.public_key_exists("~/.ssh/key"))
  end)

  it("detects public key missing", function()
    vim.fn.filereadable = function()
      return 0
    end

    assert.is_false(ssh_keys.public_key_exists("~/.ssh/key"))
  end)

  it("does not generate key when ssh-keygen is missing", function()
    vim.fn.executable = function(cmd)
      if cmd == "ssh-keygen" then
        return 0
      end

      return 1
    end

    ssh_keys.generate_key("~/.ssh/test_key", "test-comment")

    assert.are.equal(0, #opened_commands)
    assert.are.equal(1, #notifications)
    assert.matches("ssh%-keygen not found", notifications[1].message)
  end)

  it("does not generate key when key already exists", function()
    vim.fn.filereadable = function(path)
      if path == vim.fn.expand("~/.ssh/test_key") then
        return 1
      end

      return 0
    end

    ssh_keys.generate_key("~/.ssh/test_key", "test-comment")

    assert.are.equal(0, #opened_commands)
    assert.are.equal(1, #notifications)
    assert.matches("SSH key already exists", notifications[1].message)
  end)

  it("generates ssh-keygen command", function()
    ssh_keys.generate_key("~/.ssh/test_key", "test-comment")

    assert.are.equal(1, #opened_commands)

    local cmd = opened_commands[1].cmd

    assert.matches("^ssh%-keygen", cmd)
    assert.matches("%-t ed25519", cmd)
    assert.matches("%-f", cmd)
    assert.matches("test_key", cmd)
    assert.matches("%-C", cmd)
    assert.matches("test%-comment", cmd)
    assert.matches("%-N", cmd)

    assert.are.equal("bottom", opened_commands[1].opts.position)
    assert.are.equal("KVIM SSH Keygen", opened_commands[1].opts.name)
    assert.is_false(opened_commands[1].opts.listed)

    assert.are.equal(1, #mkdir_calls)
  end)

  it("generates key for ssh connection", function()
    local conn = {
      type = "ssh",
      name = "Docker SSH Test",
      host = "127.0.0.1",
    }

    ssh_keys.generate_key_for_connection(conn)

    assert.are.equal(1, #opened_commands)

    local cmd = opened_commands[1].cmd

    assert.matches("kvim_docker_ssh_test_ed25519", cmd)
    assert.matches("kvim%-docker_ssh_test", cmd)
  end)

  it("does not generate key for non-ssh connection", function()
    local conn = {
      type = "serial",
      name = "ESP32",
    }

    ssh_keys.generate_key_for_connection(conn)

    assert.are.equal(0, #opened_commands)
    assert.are.equal(1, #notifications)
    assert.matches("selected connection is not SSH", notifications[1].message)
  end)

  it("builds ssh fallback command on non-windows when ssh-copy-id is missing", function()
    vim.fn.executable = function(cmd)
      if cmd == "ssh-copy-id" then
        return 0
      end

      return 1
    end

    vim.fn.filereadable = function(path)
      if path == vim.fn.expand("~/.ssh/test_key") .. ".pub" then
        return 1
      end

      return 0
    end

    ssh_keys.install_key({
      type = "ssh",
      name = "SSH Test",
      host = "127.0.0.1",
      user = "test",
      port = 2222,
      identity_file = "~/.ssh/test_key",
    })

    assert.are.equal(1, #opened_commands)
    local cmd = opened_commands[1].cmd
    assert.matches("^cat ", cmd)
    assert.matches("authorized_keys", cmd)
    assert.matches("BatchMode=yes", cmd)
  end)

  it("does not install key when neither ssh-copy-id nor ssh are available", function()
    vim.fn.executable = function(cmd)
      if cmd == "ssh-copy-id" or cmd == "ssh" then
        return 0
      end

      return 1
    end

    vim.fn.has = function(flag)
      if flag == "win32" then
        return 1
      end

      return 0
    end

    ssh_keys.install_key({
      type = "ssh",
      name = "SSH Test",
      host = "127.0.0.1",
      user = "test",
      identity_file = "~/.ssh/test_key",
    })

    assert.are.equal(0, #opened_commands)
    assert.are.equal(1, #notifications)
    assert.matches("neither ssh%-copy%-id nor ssh are available", notifications[1].message)
  end)

  it("does not install key for non-ssh connection", function()
    ssh_keys.install_key({
      type = "serial",
      name = "ESP32",
    })

    assert.are.equal(0, #opened_commands)
    assert.are.equal(1, #notifications)
    assert.matches("selected connection is not SSH", notifications[1].message)
  end)

  it("does not install key when public key is missing", function()
    vim.fn.filereadable = function()
      return 0
    end

    ssh_keys.install_key({
      type = "ssh",
      name = "SSH Test",
      host = "127.0.0.1",
      user = "test",
      identity_file = "~/.ssh/test_key",
    })

    assert.are.equal(0, #opened_commands)
    assert.are.equal(1, #notifications)
    assert.matches("public key not found", notifications[1].message)
  end)

  it("builds ssh-copy-id command with user and port", function()
    vim.fn.filereadable = function(path)
      if path == vim.fn.expand("~/.ssh/test_key") .. ".pub" then
        return 1
      end

      return 0
    end

    ssh_keys.install_key({
      type = "ssh",
      name = "SSH Test",
      host = "127.0.0.1",
      user = "test",
      port = 2222,
      identity_file = "~/.ssh/test_key",
    })

    assert.are.equal(1, #opened_commands)

    local cmd = opened_commands[1].cmd

    assert.matches("^ssh%-copy%-id", cmd)
    assert.matches("%-i", cmd)
    assert.matches("test_key%.pub", cmd)
    assert.matches("%-p", cmd)
    assert.matches("2222", cmd)
    assert.matches("test@127%.0%.0%.1", cmd)
    assert.matches("BatchMode=yes", cmd)
    assert.matches("verifying passwordless SSH auth", cmd)

    assert.are.equal("KVIM SSH Copy ID", opened_commands[1].opts.name)
  end)

  it("builds ssh-copy-id command without user", function()
    vim.fn.filereadable = function(path)
      if path == vim.fn.expand("~/.ssh/test_key") .. ".pub" then
        return 1
      end

      return 0
    end

    ssh_keys.install_key({
      type = "ssh",
      name = "SSH Test",
      host = "127.0.0.1",
      identity_file = "~/.ssh/test_key",
    })

    assert.are.equal(1, #opened_commands)

    local cmd = opened_commands[1].cmd

    assert.matches("127%.0%.0%.1", cmd)
    assert.is_nil(cmd:match("test@127%.0%.0%.1"))
  end)

  it("builds ssh fallback command on windows when ssh-copy-id is missing", function()
    vim.fn.executable = function(cmd)
      if cmd == "ssh-copy-id" then
        return 0
      end

      return 1
    end

    vim.fn.has = function(flag)
      if flag == "win32" then
        return 1
      end

      return 0
    end

    vim.fn.filereadable = function(path)
      if path == vim.fn.expand("~/.ssh/test_key") .. ".pub" then
        return 1
      end

      return 0
    end

    vim.fn.readfile = function(path)
      if path == vim.fn.expand("~/.ssh/test_key") .. ".pub" then
        return { "ssh-ed25519 AAAATESTKEY windows@test" }
      end

      return {}
    end

    ssh_keys.install_key({
      type = "ssh",
      name = "SSH Test",
      host = "127.0.0.1",
      user = "test",
      port = 2222,
      identity_file = "~/.ssh/test_key",
      options = {
        IdentitiesOnly = "yes",
      },
    })

    assert.are.equal(1, #opened_commands)

    local cmd = opened_commands[1].cmd

    assert.matches("^type ", cmd)
    assert.matches("ssh", cmd)
    assert.matches("%-p", cmd)
    assert.matches("2222", cmd)
    assert.matches("test@127%.0%.0%.1", cmd)
    assert.matches("authorized_keys", cmd)
    assert.matches("IdentitiesOnly=yes", cmd)
    assert.matches("BatchMode=yes", cmd)
    assert.matches("verifying passwordless SSH auth", cmd)
    assert.are.equal("KVIM SSH Install Key", opened_commands[1].opts.name)
  end)

  it("does not test non-ssh connection", function()
    ssh_keys.test_connection({
      type = "serial",
      name = "ESP32",
    })

    assert.are.equal(0, #opened_commands)
    assert.are.equal(1, #notifications)
    assert.matches("selected connection is not SSH", notifications[1].message)
  end)

  it("shows error when ssh command cannot be built", function()
    package.loaded["kvim.modules.connections.ssh"] = {
      build_command = function()
        return nil, "missing host"
      end,
    }

    ssh_keys.test_connection({
      type = "ssh",
      name = "Broken SSH",
    })

    assert.are.equal(0, #opened_commands)
    assert.are.equal(1, #notifications)
    assert.matches("missing host", notifications[1].message)
  end)

  it("opens terminal to test ssh connection", function()
    package.loaded["kvim.modules.connections.ssh"] = {
      build_command = function()
        return "ssh -p 2222 test@127.0.0.1"
      end,
    }

    ssh_keys.test_connection({
      type = "ssh",
      name = "SSH Test",
      host = "127.0.0.1",
      user = "test",
      port = 2222,
    })

    assert.are.equal(1, #opened_commands)

    assert.are.equal(
      "ssh -p 2222 test@127.0.0.1 exit",
      opened_commands[1].cmd
    )

    assert.are.equal("KVIM SSH Test", opened_commands[1].opts.name)
    assert.are.equal("bottom", opened_commands[1].opts.position)
    assert.is_false(opened_commands[1].opts.listed)
  end)
end)
