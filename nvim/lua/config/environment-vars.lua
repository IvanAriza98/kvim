-- Indentifiers of environments
local envs = {
    C_CPP		= "c-cpp",
    PYTHON 		= "python",
    -- Let a gap to new lenguages
    ESP_IDF_C_CPP	= "esp-idf-c-cpp",
    ESP_IDF_MICRO	= "esp-idf-micro",
}

local labels = {
    C_CPP		= "C/C++",
    PYTHON		= "Python",
    ESP_IDF_C_CPP	= "ESP-IDF C/C++",
    ESP_IDF_MICRO	= "ESP-IDF Micropython",
}

local keys = {
    PORT = "port",
    FAMILY = "family",
    BUILD_PATH = "buildPath",

    PYTHON_PATH = "path",
    PYTHON_SCRIPT_PATH = "scriptPath",

    DEVELOPMENT = "development",
    ENVIRONMENT = "environment",
}

return {
    id = envs,
    env = envs,
    key = keys,
    label = labels,
}

