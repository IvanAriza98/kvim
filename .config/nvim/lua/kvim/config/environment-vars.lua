-- Indentifiers of environments
local envs = {
    C_CPP		= "c_cpp",
    PYTHON 		= "python",
    ESP_IDF_C_CPP	= "esp_idf_c_cpp",
    ESP_IDF_MICRO	= "esp_idf_micro",
    SSH			= "ssh",
    NRF_SDK		= "nrf_sdk"
}

local labels = {
    C_CPP		= "C/C++",
    PYTHON		= "Python",
    ESP_IDF_C_CPP	= "ESP-IDF C/C++",
    ESP_IDF_MICRO	= "ESP-IDF Micropython",
    SSH			= "SSH",
    NRF_SDK		= "NRF-SDK"
}

local keys = {
    --- ESP-IDF
    PORT = "port",
    FAMILY = "family",
    BUILD_PATH = "buildPath",

    --- NRF
    NRF_PRJ	= "prj",
    NRF_BOARD	= "board",
    NRF_DEVICE	= "device",
    NRF_APPPATH	= "appPath",

    --- PYTHON
    PYTHON_PATH = "path",
    PYTHON_SCRIPT_PATH = "scriptPath",

    DEVELOPMENT = "development",
    ENVIRONMENT = "environment",

    --- SSH COMUNICATION
    TARGET_IP	= "targetIp",
    TARGET_USER = "targetUser",
    TARGET_PASS = "targetPass",
    TARGET_DIR	= "targetDir",
}

return {
    id = envs,
    env = envs,
    key = keys,
    label = labels,
}

