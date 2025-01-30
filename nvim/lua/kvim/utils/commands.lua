require('kvim.utils.config-utils')
local var = require('kvim.config.environment-vars')

function espIdfBuildCmd(buildPath)
   return 'idf.py build -C ' ..buildPath
end

function espIdfSetTargetCmd(family, buildPath)
    return 'idf.py set-target ' ..family.. ' -C ' ..buildPath
end

function espIdfFullCleanCmd(buildPath)
    return 'idf.py fullclean -C '..buildPath
end

function espIdfFlashCmd(port, buildPath)
    return 'idf.py flash -C ' ..buildPath.. ' -p ' ..port
end

function espIdfMonitorCmd(port, buildPath)
    return 'idf.py monitor -C ' ..buildPath.. ' -p ' ..port
end


function pythonExecuteCmd()
    local python_bin = getConfigField(var.id.PYTHON, var.key.PYTHON_PATH)
    local script_path = getConfigField(var.id.PYTHON, var.key.PYTHON_SCRIPT_PATH)
    if script_path == "" then
	return python_bin .. " " .. vim.api.nvim_buf_get_name(0)
    else
	return python_bin .. " ".. script_path
    end
end
