require('kvim.utils.config-utils')
local var = require('kvim.config.environment-vars')

-- NOTE! To work's properly is mandatory add in the ~/ncs/toolchains/??????/opt/zephyr-sdk
function nrfConfigBuildProject()
    local prj = getConfigField(var.id.NRF_SDK, var.key.NRF_PRJ)
    local board = getConfigField(var.id.NRF_SDK, var.key.NRF_BOARD)
    local appPath = getConfigField(var.id.NRF_SDK, var.key.NRF_APPPATH)
    local zephyrPath = getConfigField(var.id.NRF_SDK, var.key.NRF_ZEPHYRPATH)
    return 'cd '..zephyrPath..' && python -m west build --build-dir '..appPath..'/build '..appPath..' --pristine --board '..board..' --sysbuild -- -DCONF_FILE='..prj
end

function nrfBuildProject()
    local appPath = getConfigField(var.id.NRF_SDK, var.key.NRF_APPPATH)
    local zephyrPath = getConfigField(var.id.NRF_SDK, var.key.NRF_ZEPHYRPATH)
    return 'cd '..zephyrPath..' && python -m west build --build-dir '..appPath..'/build '..appPath
end

function nrfFlashProject()
    local device = getConfigField(var.id.NRF_SDK, var.key.NRF_DEVICE)
    local appPath = getConfigField(var.id.NRF_SDK, var.key.NRF_APPPATH)
    local zephyrPath = getConfigField(var.id.NRF_SDK, var.key.NRF_ZEPHYRPATH)
    return 'cd '..zephyrPath..' && python -m west flash -d '..appPath..'/build --dev-id '..device..' --erase'
end

function getScoreNrf()
    local score = 0
    local currentPath = vim.fn.expand('%:p:h')
    local appPath = getConfigField(var.id.NRF_SDK, var.key.NRF_APPPATH)

    if not currentPath:find(appPath, 1, true) then
	return score
    end

    local filename = vim.api.nvim_buf_get_name(0)
    local build_exist = vim.fn.isdirectory(appPath.."/build") == 1
    local prj_found = vim.fn.systemlist("find . -name "..appPath.."prj.conf")

    if filename:match("%.c") then
	score = score + 1
    elseif filename:match("%.h") then
	score = score + 1
    elseif filename:match("%.cpp") then
	score = score + 1
    elseif filename:match("%.hpp") then
	score = score + 1
    end

    if #prj_found > 0 then
	score = score + 1
    end

    if build_exist then
	score = score + 1
    end

    return score
end
