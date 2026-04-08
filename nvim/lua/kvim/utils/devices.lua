-- =============================================================================
-- Devices: USB and Nordic Device Detection
-- =============================================================================
-- Scans system for connected development hardware.
-- Used by ESP-IDF and NRF-SDK commands for device selection.
--
-- Dependencies:
-- - /dev/serial/by-id/* (Linux) for USB serial devices
-- - nrfjprog (Nordic command-line tool) for NRF devices


--- Formats USB device name from serial/by-id path.
--- Extracts meaningful name from symlink format.
---
--- @param device_string string The device name from /dev/serial/by-id
--- @return string Formatted device name for display
local function format_device_name(device_string)
	local parts = {}
	for part in device_string:gmatch("[^_]+") do
		table.insert(parts, part)
	end
	local formatted_name = table.concat(parts, " ", 2, #parts - 1)
	return formatted_name
end

local M = {}

--- Scans for connected USB serial devices (ttyUSB/ttyACM).
--- Reads from /dev/serial/by-id for stable device paths.
---
--- @return table Array of device tables with 'path' and 'name' fields
---
--- @usage
---   local devices = get_usb_devices()
---   for _, dev in ipairs(devices) do
---     print(dev.name, dev.path)
---   end
function M.get_usb_devices()
	local devices = {}
	local files = vim.fn.glob("/dev/serial/by-id/*", false, true)
	for _, file in ipairs(files) do
		local device_link = vim.loop.fs_realpath(file)
		if device_link ~= nil then
			if device_link:match("/dev/ttyUSB") or device_link:match("/dev/ttyACM") then
				local device_name = vim.fn.fnamemodify(file, ":t")
				table.insert(
					devices,
					{ path = device_link, name = device_link .. " -> " .. format_device_name(device_name) }
				)
			end
		end
	end
	return devices
end

--- Scans for connected Nordic Semiconductor devices via nrfjprog.
--- Requires nrfjprog to be installed and in PATH.
---
--- @return table Array of device IDs as strings
---
--- @usage
---   local nrf_ids = get_nrf_devices()
---   if #nrf_ids > 0 then
---     print("Found NRF devices:", table.concat(nrf_ids, ", "))
---   end
function M.get_nrf_devices()
	local handle = io.popen("nrfjprog --ids")
	local result = handle:read("*a")
	handle:close()

	local ids = {}
	for id in result:gmatch("%d+") do
		table.insert(ids, id)
	end

	return ids
end

return M
