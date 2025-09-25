return {
    "mfussenegger/nvim-dap",
    dependencies = {
        "rcarriga/nvim-dap-ui",
        "nvim-neotest/nvim-nio",
    },
    config = function()
        local dap, dapui= require("dap"), require("dapui")

        dapui.setup()

        dap.listeners.before.attach.dapui_config = function()
          dapui.open()
        end
        dap.listeners.before.launch.dapui_config = function()
          dapui.open()
        end
        dap.listeners.before.event_terminated.dapui_config = function()
          dapui.close()
        end
        dap.listeners.before.event_exited.dapui_config = function()
          dapui.close()
        end


        vim.keymap.set('n', '<Leader>dt', dap.toggle_breakpoint, {})
        vim.keymap.set('n', '<Leader>dc', dap.continue, {})
        


        --- PYTHON CONFIG
        dap.adapters.python = function(cb, config)
            local cwd = vim.fn.getcwd()
            if config.request == 'attach' then
                local port = (config.connect or config).port
                local host = (config.connect or config).host or '127.0.0.1'
                cb({
                    type = 'server',
                    port = assert(port, '`connect.port` is required for a python attach configuration'),
                    host = host,
                    options = { source_filetype = 'python' },
                })
            else
                cb({
                    type = 'executable',
                    command = cwd .. '/venv/bin/python',
                    args = { '-m', 'debugpy.adapter' },
                    options = { source_filetype = 'python' },
                })
            end
        end
        
        dap.configurations.python = {
            {
                type = 'python',
                request = 'launch',
                name = 'Launch File',

                program = "${file}";
                pythonPath = function()
                    local cwd = vim.fn.getcwd()
                    if vim.fn.executable(cwd .. '/venv/bin/python') == 1 then
                        return cwd .. '/venv/bin/python'
                    elseif vim.fn.executable(cwd .. '/.venv/bin/python') == 1 then
                        return cwd .. '/.venv/bin/python'
                    else
                        return '/usr/bin/python'
                    end
                end;
            },
        }
    end,
}
