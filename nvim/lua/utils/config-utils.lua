local json = require("dkjson")

local function _getConfigFile()
    local file = io.open(vim.g.configs_path, "r")
    if not file then
	print("Config file not found.")
	return 
    end

    local content = file:read("*a")
    file.close()

    local data, pos, err = json.decode(content, 1, nil)
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


function getConfigField(module, property)
    local data = _getConfigFile()
    if not data then return end
    return vim.inspect(data[module] and _getConfigFile()[module][property] or nil)
end

function setConfigField(module, property, value)
    local data = _getConfigFile()
    if not data then return end
    if data[module] then
	data[module][property] = value
    else
	data[module] = { [property] = value }
    end
    _setConfigFile(data)
end
