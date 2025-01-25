
local n = require("nui-components")
-- Se da formato al string del nombre del USB que se
-- quiere mostrar en la lista
local function format_device_name(device_string)
    local parts = {}
    for part in device_string:gmatch("[^_]+") do
	table.insert(parts, part)
    end
    local formatted_name = table.concat(parts, " ", 2, #parts-1)
    return formatted_name
end

-- Obtenemos todos los usbs que están en el 
-- path de /dev/ttyUSB /dev/ttyACM ...
local function get_usb_devices()
    local devices = {}
    local files = vim.fn.glob('/dev/serial/by-id/*', false, true)
    for _,file in ipairs(files) do
	local device_link = vim.loop.fs_realpath(file)
	if device_link:match('/dev/ttyUSB')  or device_link:match('/dev/ttyACM') then
	    local device_name = vim.fn.fnamemodify(file, ":t")
	    table.insert(devices, { path = device_link, name = device_link .. " -> " .. format_device_name(device_name) })
	end
    end
    return devices
end

local renderer = n.create_renderer({
  width = 50,
  height = 10,
})

local espidf = n.create_signal({
    port = getConfigField('espidf', 'port'),
    family = getConfigField('espidf', 'family'),
    buildPath = getConfigField('espidf', 'buildPath'):gsub('"', ''),
})

local function save()
    setConfigField('espidf', 'port', espidf:get_value().port)
    setConfigField('espidf', 'family', espidf:get_value().family)
    local filter_path = espidf:get_value().buildPath:gsub('"', ''):gsub("'", "")
    setConfigField('espidf', 'buildPath', filter_path)
    renderer:close()
end

local function esp_config()
    local usb_devices_list = {}
    for path, device in ipairs(get_usb_devices()) do
	table.insert(usb_devices_list, n.option(device.name, { id = device.path}))
    end

    return n.form(
	{
	    id = "esp32-settings",
	    submit_key = "<C-CR>",
	    on_submit = function(is_valid)
		save()
	    end,
	},
	n.select({
	    border_label = "Select Family",
	    selected = espidf.family,
	    data = {
		n.option("esp32", { id = "esp32" }),
		n.option("esp32s2", { id = "esp32s2" }),
		n.option("esp32c2", { id = "esp32c2" }),
		n.option("esp32s3", { id = "esp32s3" }),
		n.option("esp32c3", { id = "esp32c3" }),
		n.option("esp32c6", { id = "esp32c6" }),
		n.option("esp32h2", { id = "esp32h2" }),
		n.option("esp32p4", { id = "esp32p4" }),
		n.option("linux", { id = "linux" }),
		n.option("esp32c5", { id = "esp32c5" }),
		n.option("esp32c61", { id = "esp32c61" }),
	    },
	    multiselect = false,
	    on_select = function(node, component)
		espidf.family = node.text
	    end,
	}),
	n.select({
	    border_label = "Select Port",
	    selected = espidf.port,
	    data = usb_devices_list,
	    multiselect = false,
	    on_select = function(node, component)
		espidf.port = node.text
	    end
	}),
	n.text_input({
	    flex = 1,
	    border_label = "Set Build Path",
	    value = espidf.buildPath,
	    on_change = function(value, component)
		espidf.buildPath = value
	    end,
	})
    )
end

renderer:render(esp_config())
