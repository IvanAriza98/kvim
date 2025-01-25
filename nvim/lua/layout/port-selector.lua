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
	    table.insert(devices, { path = device_link, name = format_device_name(device_name) .. " -> " .. device_link })
	end
    end
    return devices
end



local usb_devices = get_usb_devices()

local usb_devices_list = {}
for path, device in ipairs(usb_devices) do
    table.insert(usb_devices_list, n.option(device.name, { id = device.path}))
end

local renderer = n.create_renderer({
  width = 50,
  height = 10,
})

local signal = n.create_signal({
    selected_esp_port = {''},
    selected_esp_family = {''},
})

local function save()
    print("Saving ... ")
end

local function quit()
    print("Quitting ... ")
end

--TODO añadir protecciones de fichero
local function preload_config()
    local toml = require("toml")
    succeeded, table = pcall(toml.decodeFromFile, vim.g.configs_path)
    signal.port = table['esp-idf']['port']
    if usb_devices_list == {} then
	signal.port = "" -- revisar si hay agun puerto sino no poner por defecto sino otro 
    end
    signal.family = table['esp-idf']['family'] 
    signal.buildPath = table['esp-idf']['buildPath'] 
end

local function esp_config()
    preload_config()
    return n.form(
	{
	    id = "esp32-settings",
	    submit_key = "<S-CR>",
	    on_submit = function(is_valid)
	      print(is_valid)
	    end,
	},
	n.select({
	    border_label = "Select Family",
	    selected = signal.selected_esp_family,
	    data = {
		n.option("esp32"),
		n.option("esp32s2"),
		n.option("esp32c2"),
		n.option("esp32s3"),
		n.option("esp32c3"),
		n.option("esp32c6"),
		n.option("esp32h2"),
		n.option("esp32h2"),
		n.option("esp32p4"),
		n.option("linux"),
		n.option("esp32c5"),
		n.option("esp32c61"),
	    },
	    multiselect = false,
	}),
	n.select({
	    border_label = "Select Port",
	    selected = signal.selected_esp_port,
	    data = usb_devices_list,
	    multiselect = false,
	}),
	n.text_input({
	    flex = 1,
	    border_label = "Set Build Path",
	}),
	n.button({
	    label = "Save",
	    on_press = save(),
	}),
	n.button({
	    label = "Quit",
	    on_press = quit(),
	})
    )
end

renderer:render(esp_config())
