require('kvim.utils.config-utils')
local var = require('kvim.config.environment-vars')

function configBuildFolder()
    local prj = getConfigField(var.id.NRF_SDK, var.key.NRF_PRJ)
    local board = getConfigField(var.id.NRF_SDK, var.key.NRF_BOARD)
    local appPath = getConfigField(var.id.NRF_SDK, var.key.NRF_APPPATH)
    return 'python -m west build --build-dir '..appPath..'/build '..appPath..' --pristine --board '..board..' --cmake-only -- -DCONF_FILE='..prj
end

function buildProject()
    local appPath = getConfigField(var.id.NRF_SDK, var.key.APPPATH)
    return 'python -m west build --build-dir '..appPath..'/build '..appPath
end

function flashProject()
    local device = getConfigField(var.id.NRF_SDK, var.key.NRF_DEVICE)
    local appPath = getConfigField(var.id.NRF_SDK, var.key.NRF_APPPATH)
    return 'python -m west flash -d '..appPath..'/build --dev-id '..device..' --erase'
end

