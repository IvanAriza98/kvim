-- lua/kvim/modules/connections/commands.lua

local M = {}

function M.setup(opts)
  opts = opts or {}

  local ssh = require("kvim.modules.connections.ssh")
  local state = require("kvim.modules.connections.state")
  local actions = require("kvim.modules.connections.actions")
  local transfer = require("kvim.modules.connections.transfer")

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

  vim.api.nvim_create_user_command("KvimSSHUploadCurrent", function()
    local conn = state.get_active_connection()

    if not conn then
      vim.notify("KVIM: no SSH connection configured", vim.log.levels.ERROR)
      return
    end

    transfer.upload_current_file(conn)
  end, {
    desc = "Upload current file to SSH connection",
  })

    vim.api.nvim_create_user_command("KvimSSHUploadPath", function(params)
      local conn = state.get_active_connection()

      if not conn then
        vim.notify("KVIM: no SSH connection configured", vim.log.levels.ERROR)
        return
      end

      local local_path = params.args

      if local_path == "" then
        local_path = vim.fn.input("Local path: ", "", "file")
      end

      if local_path == "" then
        vim.notify("KVIM: upload cancelled", vim.log.levels.WARN)
        return
      end

      transfer.upload_path(conn, local_path)
    end, {
      nargs = "?",
      complete = "file",
      desc = "Upload local file or directory to SSH connection",
    })

    vim.api.nvim_create_user_command("KvimSSHDownloadPath", function(params)
      local conn = state.get_active_connection()

      if not conn then
        vim.notify("KVIM: no SSH connection configured", vim.log.levels.ERROR)
        return
      end

      local remote_path = params.args

      if remote_path == "" then
        remote_path = vim.fn.input("Remote path: ")
      end

      if remote_path == "" then
        vim.notify("KVIM: download cancelled", vim.log.levels.WARN)
        return
      end

      transfer.download_path(conn, remote_path)
    end, {
      nargs = "?",
      desc = "Download remote file or directory from SSH connection",
    })


    vim.api.nvim_create_user_command("KvimConnectionSetActive", function()
      actions.set_active_connection_picker(opts)
    end, {
      desc = "Select active KVIM connection",
    })

    vim.api.nvim_create_user_command("KvimSSHConnectionSetActive", function()
      actions.set_active_ssh_connection_picker(opts)
    end, {
      desc = "Select active KVIM SSH connection",
    })

    vim.api.nvim_create_user_command("KvimConnectionShowActive", function()
      vim.notify(
        "KVIM Connections: active connection: " .. state.get_active_connection_label(),
        vim.log.levels.INFO
      )
    end, {
      desc = "Show active KVIM connection",
    })

    vim.api.nvim_create_user_command("KvimConnectionClearActive", function()
      state.clear_active_connection()
    end, {
      desc = "Clear active KVIM connection",
    })

    vim.api.nvim_create_user_command("KvimSSHRun", function(params)
      local conn = state.get_active_connection()

      if not conn then
        vim.notify("KVIM Connections: no active connection selected", vim.log.levels.ERROR)
        return
      end

      if conn.type ~= "ssh" then
        vim.notify("KVIM Connections: active connection is not SSH", vim.log.levels.ERROR)
        return
      end

      local remote_command = params.args

      if remote_command == "" then
        remote_command = vim.fn.input("Remote command: ")
      end

      if remote_command == "" then
        vim.notify("KVIM Connections: SSH command cancelled", vim.log.levels.WARN)
        return
      end

      ssh.run_command(conn, remote_command)
    end, {
      nargs = "*",
      desc = "Run command on active SSH connection",
    })
end



return M
