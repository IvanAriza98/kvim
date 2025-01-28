-- Indentifiers of environments
local envs = {
    C_CPP		= "c-cpp",
    PYTHON 		= "python",
    ESP_IDF_C_CPP	= "esp-idf-c-cpp",
    ESP_IDF_MICRO	= "esp-idf-micro",
    SSH			= "ssh",
}

local labels = {
    C_CPP		= "C/C++",
    PYTHON		= "Python",
    ESP_IDF_C_CPP	= "ESP-IDF C/C++",
    ESP_IDF_MICRO	= "ESP-IDF Micropython",
    SSH			= "SSH", 
}

local keys = {
    PORT = "port",
    FAMILY = "family",
    BUILD_PATH = "buildPath",

    PYTHON_PATH = "path",
    PYTHON_SCRIPT_PATH = "scriptPath",

    DEVELOPMENT = "development",
    ENVIRONMENT = "environment",
    
    --- SSH COMUNICATION
    TARGET_IP	= "targetIp",
    TARGET_DIR	= "targetDir",
}

return {
    id = envs,
    env = envs,
    key = keys,
    label = labels,
}

