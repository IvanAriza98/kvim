require('utils.config-utils')
local var = require('config.environment-vars')
function espIdfBuildCmd()
    local cfg_env = getConfigField(var.key.ENVIRONMENT)
    if cfg_env == var.env.ESP_IDF_C_CPP then
	local family = getConfigField(var.env.ESP_IDF_C_CPP, var.key.FAMILY)
	local buildPath = getConfigField(var.ESP_IDF_C_CPP, var.key.BUILD_PATH)
	print("idf.py -C " .. buildPath .. " set-target " .. family .. "&& idf.py -C " .. buildPath .. " build")
	return "idf.py -C " .. buildPath .. " set-target " .. family .. "&& idf.py -C " .. buildPath .. " build"
    elseif env == var.env.ESP_IDF_MICRO then
	local family = getConfigField(var.env.ESP_IDF_MICRO, var.key.FAMILY)
	local buildPath = getConfigField(var.env.ESP_IDF_MICRO, var.key.BUILD_PATH)
	return "idf.py -C" .. buildPath .. "set-target" .. family .. "&& idf.py -C" .. buildPath .. "build"
    end
end


function espIdfExecuteCmd()
    local cfg_env = getConfigField(var.key.ENVIRONMENT)
    if cfg_env == var.env.ESP_IDF_C_CPP then
	local port = getConfigField(var.env.ESP_IDF_C_CPP, var.key.PORT)
	local buildPath = getConfigField(var.env.ESP_IDF_C_CPP, var.key.BUILD_PATH)
	return "idf.py -B" .. buildPath .. "-p" .. port .. "flash"
    elseif env == var.env.ESP_IDF_MICRO then
	local port = getConfigField(var.env.ESP_IDF_MICRO, var.key.PORT)
	local buildPath = getConfigField(var.env.ESP_IDF_MICRO, var.key.BUILD_PATH)
	return "idf.py -B" .. buildPath .. "-p" .. port .. "flash"
    end
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
