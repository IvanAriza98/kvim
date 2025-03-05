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
function get_usb_devices()
    local devices = {}
    local files = vim.fn.glob('/dev/serial/by-id/*', false, true)
    for _,file in ipairs(files) do
	local device_link = vim.loop.fs_realpath(file)
	if device_link ~= nil then
	    if device_link:match('/dev/ttyUSB')  or device_link:match('/dev/ttyACM') then
		local device_name = vim.fn.fnamemodify(file, ":t")
		table.insert(devices, { path = device_link, name = device_link .. " -> " .. format_device_name(device_name) })
	    end
	end
    end
    return devices
end

