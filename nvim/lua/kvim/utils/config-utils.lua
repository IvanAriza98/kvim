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
local env = require("kvim.env")

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

--- Gets all SSH sessions from the config file.
--- @return table? Array of SSH session objects, or nil if no sessions exist
local function getSSHSessions()
	local sessions = getConfigField(env.id.SSH, env.key.SSH_SESSIONS)
	if not sessions or type(sessions) ~= "table" then
		return nil
	end
	return sessions
end

--- Gets the current active SSH session index.
--- @return number? The active session index (1-based), or nil if not set
local function getActiveSSH()
	return getConfigField(env.id.SSH, env.key.SSH_ACTIVE)
end

--- Sets the active SSH session index.
--- @param index number The session index to set as active (1-based)
--- @return boolean True if successfully set, false if index is invalid
local function setActiveSSH(index)
	local sessions = getSSHSessions()
	if not sessions or index < 1 or index > #sessions then
		vim.notify("Invalid SSH session index: " .. tostring(index), vim.log.levels.WARN)
		return false
	end
	setConfigField(index, env.id.SSH, env.key.SSH_ACTIVE)
	return true
end

--- Adds a new SSH session to the config file.
--- @param session table The SSH session object to add
--- @return boolean True if successfully added, false otherwise
local function addSSHSession(session)
	if not session or type(session) ~= "table" then
		vim.notify("Invalid SSH session object", vim.log.levels.WARN)
		return false
	end

	local sessions = getSSHSessions()
	if not sessions then
		sessions = {}
	end

	table.insert(sessions, session)
	setConfigField(sessions, env.id.SSH, env.key.SSH_SESSIONS)

	-- If this is the first session, set it as active
	if not getActiveSSH() then
		setConfigField(1, env.id.SSH, env.key.SSH_ACTIVE)
	end

	return true
end

--- Updates an existing SSH session at the given index.
--- @param index number The session index to update (1-based)
--- @param session table The new SSH session object
--- @return boolean True if successfully updated, false if index is invalid
local function updateSSHSession(index, session)
	local sessions = getSSHSessions()
	if not sessions or index < 1 or index > #sessions then
		vim.notify("Invalid SSH session index: " .. tostring(index), vim.log.levels.WARN)
		return false
	end

	if not session or type(session) ~= "table" then
		vim.notify("Invalid SSH session object", vim.log.levels.WARN)
		return false
	end

	sessions[index] = session
	setConfigField(sessions, env.id.SSH, env.key.SSH_SESSIONS)
	return true
end

--- Deletes an SSH session at the given index.
--- @param index number The session index to delete (1-based)
--- @return boolean True if successfully deleted, false if index is invalid
local function deleteSSHSession(index)
	local sessions = getSSHSessions()
	if not sessions or index < 1 or index > #sessions then
		vim.notify("Invalid SSH session index: " .. tostring(index), vim.log.levels.WARN)
		return false
	end

	table.remove(sessions, index)
	setConfigField(sessions, env.id.SSH, env.key.SSH_SESSIONS)

	-- Adjust active index if needed
	local active = getActiveSSH()
	if active and active > #sessions then
		setConfigField(#sessions > 0 and #sessions or nil, env.id.SSH, env.key.SSH_ACTIVE)
	end

	return true
end

return {
	getConfigField = getConfigField,
	setConfigField = setConfigField,
	getSSHSessions = getSSHSessions,
	getActiveSSH = getActiveSSH,
	setActiveSSH = setActiveSSH,
	addSSHSession = addSSHSession,
	updateSSHSession = updateSSHSession,
	deleteSSHSession = deleteSSHSession,
}
