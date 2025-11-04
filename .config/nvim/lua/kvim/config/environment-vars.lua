-- Indentifiers of environments
local envs = {
	C_CPP = "c_cpp",
	PYTHON = "python",
	ESP_IDF = "esp_idf",
	SSH = "ssh",
	NRF_SDK = "nrf_sdk",
}

local labels = {
	C_CPP = "C/C++",
	PYTHON = "Python",
	ESP_IDF = "ESP-IDF",
	SSH = "SSH",
	NRF_SDK = "NRF-SDK",
}

local keys = {
	--- ESP-IDF
	IDF_PORT = "port",
	IDF_FAMILY = "family",
	IDF_PATH = "idfPath",
	IDF_APPPATH = "appPath",

	--- NRF
	NRF_APP_PATH = "appPath",
	NRF_ZEPHYR_TOOLCHAIN_PATH = "zephyrToolchainPath",
	NRF_BOARD_TARGET = "boardTarget",
	NRF_CONFIG_FILES = "baseConfigFiles",
	NRF_EXTRA_KCONFIG_FRAGMENTS = "extraKconfigFragments",
	NRF_BASE_DEVICETREE_OVERLAYS = "baseDevicetreeOverlays",
	NRF_EXTRA_DEVICETREE_OVERLAYS = "extraDevicetreeOverlays",
	NRF_SN_DEVICE = "snDevice",

	--- PYTHON
	PYT_PATH = "path",

	DEVELOPMENT = "development",
	ENVIRONMENT = "environment",

	--- SSH COMUNICATION
	SSH_IP = "ip",
	SSH_PORT = "port",
	SSH_USER = "user",
	SSH_PATH = "path",
    SSH_KEY_TYPE = "key_type",
}

return {
	id = envs,
	env = envs,
	key = keys,
	label = labels,
}
