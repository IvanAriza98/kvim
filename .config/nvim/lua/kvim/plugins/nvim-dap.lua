return {
  "mfussenegger/nvim-dap",
  dependencies = {
    "rcarriga/nvim-dap-ui",
    "nvim-neotest/nvim-nio",
  },
  config = function()
    local dap = require("dap")
    local dapui = require("dapui")

    -- Configuración de UI
    dapui.setup()

    dap.listeners.after.event_initialized["dapui_config"] = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated["dapui_config"] = function()
      dapui.close()
    end
    dap.listeners.before.event_exited["dapui_config"] = function()
      dapui.close()
    end

    -- Keymaps básicos
    vim.keymap.set('n', '<Leader>db', dap.toggle_breakpoint, {})
    vim.keymap.set('n', '<Leader>dc', dap.continue, {})
    vim.keymap.set('n', '<Leader>di', dap.step_into, {})
    vim.keymap.set('n', '<Leader>do', dap.step_out, {})
    vim.keymap.set('n', '<Leader>ds', dap.step_over, {})

    -- Adapter para LLDB (usando lldb-dap)
    dap.adapters.lldb = {
      type = 'executable',
      command = '/usr/bin/lldb-dap',
      name = 'lldb'
    }

    -- Configuración para C/C++/Zephyr ELF
    dap.configurations.cpp = {
      {
        name = "Debug Zephyr ELF",
        type = "lldb",
        request = "launch",
        program = function()
          -- Cambia la ruta a tu ELF compilado
          return vim.fn.input('Path to ELF: ', vim.fn.getcwd() .. '/build/zephyr/zephyr.elf', 'file')
        end,
        cwd = '${workspaceFolder}',
        stopOnEntry = true,
        args = {}, -- argumentos si los hubiera
        runInTerminal = false,
      },
    }

    -- Para C también
    dap.configurations.c = dap.configurations.cpp
  end
}

