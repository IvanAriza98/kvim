-- nvim-dap: Debug Adapter Protocol para depuración
-- Permite depurar programas en múltiples lenguajes (C, Python, Rust, etc.)
return {
  "mfussenegger/nvim-dap",
  dependencies = {
    "rcarriga/nvim-dap-ui",  -- Interfaz visual para el debugger
    "nvim-neotest/nvim-nio", -- Librería de I/O asíncrona
  },
    lazy = true, -- Carga perezosa para no ralentizar inicio
    -- Se carga cuando se ejecutan comandos DAP específicos
    cmd = { "DapContinue", "DapToggleBreakpoint", "DapStepOver", "DapStepInto", "DapStepOut" },
  config = function()
    local dap = require("dap")
    local dapui = require("dapui")

    -- Configuración de la interfaz visual del debugger
    dapui.setup()

    -- Eventos del debugger: abre/cierra UI automáticamente
    dap.listeners.after.event_initialized["dapui_config"] = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated["dapui_config"] = function()
      dapui.close()
    end
    dap.listeners.before.event_exited["dapui_config"] = function()
      dapui.close()
    end

    -- Atajos de teclado para debugging ( Leader = espacio )
    -- <Leader>db = toggle breakpoint
    -- <Leader>dc = continuar ejecución
    -- <Leader>di = step into (entrar en función)
    -- <Leader>do = step out (salir de función)
    -- <Leader>ds = step over (siguiente línea)
    vim.keymap.set('n', '<Leader>db', dap.toggle_breakpoint, {})
    vim.keymap.set('n', '<Leader>dc', dap.continue, {})
    vim.keymap.set('n', '<Leader>di', dap.step_into, {})
    vim.keymap.set('n', '<Leader>do', dap.step_out, {})
    vim.keymap.set('n', '<Leader>ds', dap.step_over, {})

    -- Adapter LLDB para debugging C/C++
    dap.adapters.lldb = {
      type = 'executable',
      command = '/usr/bin/lldb-dap', -- Usa lldb-dap como backend
      name = 'lldb'
    }

    -- Configuración para debugging de binarios C/C++ y Zephyr RTOS
    dap.configurations.cpp = {
      {
        name = "Debug Zephyr ELF",        -- Nombre en el menú de debug
        type = "lldb",                     -- Usa el adapter lldb
        request = "launch",               -- Tipo de request: launch o attach
        -- Solicita la ruta del ELF compilado al iniciar
        program = function()
          return vim.fn.input('Path to ELF: ', vim.fn.getcwd() .. '/build/zephyr/zephyr.elf', 'file')
        end,
        cwd = '${workspaceFolder}',       -- Directorio de trabajo
        stopOnEntry = true,               -- Pausa al entrar en main()
        args = {},                         -- Argumentos del programa
        runInTerminal = false,             -- No usa terminal externo
      },
    }

    -- Hereda configuración de C++ para archivos .c
    dap.configurations.c = dap.configurations.cpp
  end
}

