-- Indentifiers of environments
local envs = {
    C_CPP		= "c_cpp",
    PYTHON 		= "python",
    ESP_IDF		= "esp_idf",
    SSH			= "ssh",
    NRF_SDK		= "nrf_sdk"
}

local labels = {
    C_CPP		= "C/C++",
    PYTHON		= "Python",
    ESP_IDF 		= "ESP-IDF",
    SSH			= "SSH",
    NRF_SDK		= "NRF-SDK"
}

local keys = {
    --- ESP-IDF
    IDF_PORT	= "port",
    IDF_FAMILY	= "family",
    IDF_PATH	= "idfPath",
    IDF_APPPATH = "appPath",

    --- NRF
    NRF_PRJ		= "prj",
    NRF_BOARD		= "board",
    NRF_DEVICE		= "device",
    NRF_APPPATH		= "appPath",
    NRF_ZEPHYRPATH	= "zephyrPath",

    --- PYTHON
    PYT_PATH = "path",

    DEVELOPMENT = "development",
    ENVIRONMENT = "environment",

    --- SSH COMUNICATION
    SSH_IP	= "targetIp",
    SSH_PATH	= "targetPath",
    SSH_USER	= "targetUser",
}

return {
    id = envs,
    env = envs,
    key = keys,
    label = labels,
}

