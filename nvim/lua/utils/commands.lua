require('utils.config-utils')
local var = require('config.environment-vars')
function espIdfBuildCmd()
    local cfg_env = getConfigField(var.key.ENVIRONMENT)
    local family = getConfigField(cfg_env, var.key.FAMILY)
    local buildPath = getConfigField(cfg_env, var.key.BUILD_PATH)
    return "idf.py set-target -C " .. buildPath .. " set-target " .. family .. " && idf.py build -C " .. buildPath
end


function espIdfExecuteCmd()
    local cfg_env = getConfigField(var.key.ENVIRONMENT)
    local port = getConfigField(cfg_env, var.key.PORT)
    local buildPath = getConfigField(cfg_env, var.key.BUILD_PATH)
    return "idf.py flash -B " .. buildPath .. " -p " .. port
end

function espIdfMonitorCmd()
    local cfg_env = getConfigField(var.key.ENVIRONMENT)
    local port = getConfigField(cfg_env, var.key.PORT)
    local buildPath = getConfigField(cfg_env, var.key.BUILD_PATH)
    return "idf.py  monitor -C " .. buildPath .. " -p " .. port
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
