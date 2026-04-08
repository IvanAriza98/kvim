-- =============================================================================
-- Config Utils: JSON Configuration Reader/Writer
-- =============================================================================
-- Reads and writes configuration to ~/.config/nvim/configs.json
-- Uses dkjson for dependency-free JSON parsing.
--
-- Cache Strategy:
-- - TTL: 5 seconds to balance freshness vs performance
-- - Auto-invalidation on write operations
--
-- Key Conventions:
-- - Top-level keys: esp_idf, nrf_sdk, project, ssh, etc.
-- - Two-level access: getConfigField("esp_idf", "idfPath")

local json = require("dkjson")

local _config_cache = nil
local _cache_time = nil
local CACHE_TTL = 5000

local function _getConfigFile()
	local now = vim.loop.now()
	if _config_cache and _cache_time and (now - _cache_time) < CACHE_TTL then
		return _config_cache
	end

	local file = io.open(vim.g.configs_path, "r")
	if not file then
		print("Config file not found. ", vim.g.configs_path)
		return
	end

	local content = file:read("*a")
	file:close()

	local data = json.decode(content)
	if not data then
		print("Failed to decode")
	end
	_config_cache = data
	_cache_time = now
	return data
end

local function _setConfigFile(data)
	_config_cache = nil
	_cache_time = nil
	local content, err = json.encode(data, { indent = true })
	if err then
		print("Error to encode.")
		return
	end

	local file = io.open(vim.g.configs_path, "w")
	if not file then
		print("Config file not found")
		print(vim.g.configs_path)
		return
	end

	file:write(content)
	file:close()
end

--- Retrieves a configuration field from the JSON config file.
--- Supports one or two-level key access.
---
--- @param key1 string The top-level key
--- @param key2 string? Optional second-level key
--- @return any The configuration value, or nil if not found
---
--- @usage
---   local path = getConfigField("esp_idf", "idfPath")
---   local name = getConfigField("project", "name")
function getConfigField(key1, key2)
	local data = _getConfigFile()
	if not data then
		return
	end
	if key2 == nil then
		return data[key1]
	else
		return data[key1][key2]
	end
end

--- Sets a configuration field in the JSON config file.
--- Automatically creates nested tables if needed for two-level keys.
--- Invalidates the cache after writing.
---
--- @param value any The value to set
--- @param key1 string The top-level key
--- @param key2 string? Optional second-level key
---
--- @usage
---   setConfigField("/opt/esp-idf", "esp_idf", "idfPath")
---   setConfigField("my-project", "project", "name")
function setConfigField(value, key1, key2)
	local data = _getConfigFile() or {}
	if not data then
		return
	end
	if key2 == nil then
		data[key1] = value
	else
		if not data[key1] or type(data[key1]) ~= "table" then
			data[key1] = {}
		end
		data[key1][key2] = value
	end
	_setConfigFile(data)
end
