require("kvim.utils.config-utils")
local var = require("kvim.config.environment-vars")

-- NOTE! To work's properly is mandatory add in the ~/ncs/toolchains/??????/opt/zephyr-sdk
function nrfConfigBuildProject()
	local appPath = getConfigField(var.id.NRF_SDK, var.key.NRF_APP_PATH)
	local baseConfigFiles = getConfigField(var.id.NRF_SDK, var.key.NRF_CONFIG_FILES)
	local zephyrPath = getConfigField(var.id.NRF_SDK, var.key.NRF_ZEPHYR_VERSION_PATH)
	local boardTarget = getConfigField(var.id.NRF_SDK, var.key.NRF_BOARD_TARGET)

	local extraKconfigFragments = getConfigField(var.id.NRF_SDK, var.key.NRF_EXTRA_KCONFIG_FRAGMENTS)
	local baseDevicetreeOverlays = getConfigField(var.id.NRF_SDK, var.key.NRF_BASE_DEVICETREE_OVERLAYS)
	local extraDevicetreeOverlays = getConfigField(var.id.NRF_SDK, var.key.NRF_EXTRA_DEVICETREE_OVERLAYS)

    local sep = "/"
	if appPath:sub(-1) == "/" then
		sep = ""
	end
    local cmd = "cd " .. zephyrPath .. " && python -m west build --build-dir " .. appPath .. "/build " .. appPath
	cmd = cmd .. " --pristine --board " .. boardTarget .. " --sysbuild"
	cmd = cmd .. " -- -DCONF_FILE=" .. baseConfigFiles .. " -DBOARD_ROOT=" .. appPath

	if extraKconfigFragments ~= nil and extraKconfigFragments ~= "" then
		cmd = cmd .. " -DEXTRA_CONF_FILE=" .. appPath .. sep .. extraKconfigFragments
	end

	if baseDevicetreeOverlays ~= nil and baseDevicetreeOverlays ~= "" then
		cmd = cmd .. " -DDTC_OVERLAY_FILE=" .. appPath .. sep .. baseDevicetreeOverlays
	end

	if extraDevicetreeOverlays ~= nil and extraDevicetreeOverlays ~= "" then
		local overlayDir = extraDevicetreeOverlays
		local overlayFiles = ""
		local p = io.popen('ls "' .. overlayDir .. '"')
		if p then
			for file in p:lines() do
				if file:match("%.overlay$") then
					overlayFiles = overlayFiles .. overlayDir .. "/" .. file .. " "
				end
			end
			p:close()
		end

		overlayFiles = overlayFiles:match("^%s*(.-)%s*$") -- Trim leading and trailing spaces
		if overlayFiles ~= "" then
			cmd = cmd .. ' -DEXTRA_DTC_OVERLAY_FILE="' .. overlayFiles .. '"'
		end
	end

	return cmd
end

function nrfBuildProject()
	local appPath = getConfigField(var.id.NRF_SDK, var.key.NRF_APP_PATH)
	local zephyrPath = getConfigField(var.id.NRF_SDK, var.key.NRF_ZEPHYR_VERSION_PATH)
	return "cd " .. zephyrPath .. " && python -m west build --build-dir " .. appPath .. "/build " .. appPath
	-- return "python -m west build --build-dir " .. appPath .. "/build " .. appPath
end

function nrfFlashProject()
	local snDevice = getConfigField(var.id.NRF_SDK, var.key.NRF_SN_DEVICE)
	local appPath = getConfigField(var.id.NRF_SDK, var.key.NRF_APP_PATH)
	local zephyrToolchainPath = getConfigField(var.id.NRF_SDK, var.key.NRF_ZEPHYR_VERSION_PATH)
	local monitor = nrfRTTMonitorProject() -- Automatically get the RTT monitor

	return "cd "
		.. zephyrToolchainPath
		.. " && python -m west flash -d "
		.. appPath
		.. "/build --dev-id "
		.. snDevice
		.. " --erase"
		-- .. " --erase && "
		-- .. monitor
end

function nrfRTTMonitorProject()
	local snDevice = getConfigField(var.id.NRF_SDK, var.key.NRF_SN_DEVICE)
	local appPath = getConfigField(var.id.NRF_SDK, var.key.NRF_APP_PATH)
	local zephyrToolchainPath = getConfigField(var.id.NRF_SDK, var.key.NRF_ZEPHYR_VERSION_PATH)

	-- Check if port 2331 is already in use
	local port = 2331
	local cmd = string.format("lsof -i :%d | awk '{print $2}' | tail -n +2", port)
	local handle = io.popen(cmd)
	local result = handle:read("*a")
	handle:close()

	if result ~= "" then
		-- If port is in use, kill the process using it
		local pid = result:match("%S+")
		if pid then
			os.execute("kill -9 " .. pid)
		end
	end

	return "cd "
		.. zephyrToolchainPath
		.. " && nrfjprog -s "
		.. snDevice
		.. " -r && python -m west rtt -r jlink --build-dir "
		.. appPath
		.. "/build -- --speed 1000"
end

function nrfDebugMonitorProject()
    local appPath = getConfigField(var.id.NRF_SDK, var.key.NRF_APP_PATH)
    return "python -m west debug --runner jlink --build-dir "
        .. appPath
        .. "/build"
end


function getScoreNrf()
	local score = 0
	local currentPath = vim.fn.expand("%:p:h")
	local appPath = getConfigField(var.id.NRF_SDK, var.key.NRF_APP_PATH)

	if not currentPath:find(appPath, 1, true) then
		return score
	end

	local filename = vim.api.nvim_buf_get_name(0)
	local build_exist = vim.fn.isdirectory(appPath .. "/build") == 1
	local prj_found = vim.fn.systemlist("find . -name " .. appPath .. "prj.conf")

	if filename:match("%.c") then
		score = score + 1
	elseif filename:match("%.h") then
		score = score + 1
	elseif filename:match("%.cpp") then
		score = score + 1
	elseif filename:match("%.hpp") then
		score = score + 1
	end

	if #prj_found > 0 then
		score = score + 1
	end

	if build_exist then
		score = score + 1
	end

	return score
end
