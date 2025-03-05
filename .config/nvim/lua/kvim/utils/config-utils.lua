local json = require("dkjson")
-- local vars = require('kvim.config.environment-vars')

local function _getConfigFile()
    local file = io.open(vim.g.configs_path, "r")
    if not file then
	print("Config file not found.")
	return
    end

    local content = file:read("*a")
    file:close()

    local data, _, _ = json.decode(content, 1, nil)
    return data
end

local function _setConfigFile(data)
    local content, err = json.encode(data, { indent = true })
    if err then
	print("Error to encode.")
	return
    end

    local file = io.open(vim.g.configs_path, "w")
    if not file then
	print("Config file not found")
	return
    end

    file:write(content)
    file:close()
end

-- supports two levels
function getConfigField(key1, key2)
    local data = _getConfigFile()
    if not data then return end
    if key2 == nil then
	return data[key1]
    else
	return data[key1][key2]
    end
end

function setConfigField(value, key1, key2)
    local data = _getConfigFile() or {}
    if not data then return end
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

