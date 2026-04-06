require('kvim.utils.config-utils')
local var = require('kvim.config.environment-vars')

function idfBuildProject()
    local appPath = getConfigField(var.id.ESP_IDF, var.key.IDF_APPPATH)
    return 'idf.py build -C ' ..appPath
end

function setIdfTargetProject()
    local family = getConfigField(var.id.ESP_IDF, var.key.FAMILY)
    local appPath = getConfigField(var.id.ESP_IDF, var.key.IDF_APPPATH)
    return 'idf.py set-target ' ..family.. ' -C ' ..appPath
end

function idfFullCleanProject()
    local appPath = getConfigField(var.id.ESP_IDF, var.key.IDF_APPPATH)
    return 'idf.py fullclean -C '..appPath
end

function idfFlashProject()
    local port = getConfigField(var.id.ESP_IDF, var.key.PORT)
    local appPath = getConfigField(var.id.ESP_IDF, var.key.IDF_APPPATH)
    return 'idf.py flash -C ' ..appPath.. ' -p ' ..port
end

function idfMonitorProject()
    local port = getConfigField(var.id.ESP_IDF, var.key.PORT)
    local appPath = getConfigField(var.id.ESP_IDF, var.key.IDF_APPPATH)
    return 'idf.py monitor -C ' ..appPath.. ' -p ' ..port
end


function getScoreIdf()
    local score = 0
    local currentPath = vim.fn.expand('%:p:h')
    local appPath = getConfigField(var.id.ESP_IDF, var.key.IDF_APPPATH)

    if not currentPath:find(appPath, 1, true) then
	return score
    end

    local filename = vim.api.nvim_buf_get_name(0)
    local build_exist = vim.fn.isdirectory(appPath.."build") == 1
    local sdk_config = vim.fn.systemlist("find . -name "..appPath.."/sdkconfig")

    if filename:match("%.c") then
	score = score + 1
    elseif filename:match("%.h") then
	score = score + 1
    elseif filename:match("%.cpp") then
	score = score + 1
    elseif filename:match("%.hpp") then
	score = score + 1
    end

    if #sdk_config > 0 then
	score = score + 1
    end

    if build_exist then
	score = score + 1
    end
    return score
end
