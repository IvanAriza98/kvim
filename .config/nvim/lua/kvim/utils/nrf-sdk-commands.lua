require("kvim.utils.config-utils")
local var = require("kvim.config.environment-vars")

function nrfConfigBuildProject()
	local workspacePath = getConfigField(var.id.NRF_SDK, var.key.NRF_WORKSPACE_PATH)
	local project = getConfigField(var.id.NRF_SDK, var.key.NRF_PROJECT_NAME)
	local application = getConfigField(var.id.NRF_SDK, var.key.NRF_APPLICATION)
	local boardTarget = getConfigField(var.id.NRF_SDK, var.key.NRF_BOARD_TARGET)
    local appConfigFile = getConfigField(var.id.NRF_SDK, var.key.NRF_APP_CONFIG_FILE)
	local extraKconfigFragments = getConfigField(var.id.NRF_SDK, var.key.NRF_EXTRA_KCONFIG_FRAGMENTS)
	local baseDevicetreeOverlays = getConfigField(var.id.NRF_SDK, var.key.NRF_BASE_DEVICETREE_OVERLAYS)
	local extraDevicetreeOverlays = getConfigField(var.id.NRF_SDK, var.key.NRF_EXTRA_DEVICETREE_OVERLAYS)
    local projectPath = workspacePath .. "/" .. project
    local applicationPath = workspacePath .. "/" .. project .. "/" .. application
    -- ~~~~~~ Rules ~~~~~~
    -- Build folder will create in the same directory of the application
    -- You should have a .venv with all dependencies requierements to use zephyr + NrfSdk
    -- Board directory should be in the project directory boards/
    local cmd = "cd " .. workspacePath .. " && ".. workspacePath.. "/.venv/bin/python -m west build --build-dir " .. applicationPath .. "/build "
    cmd = cmd .. applicationPath .. " --pristine --board " .. boardTarget .. " --sysbuild"
	cmd = cmd .. " -- -DCONF_FILE=" .. projectPath .. "/" .. appConfigFile .. " -DBOARD_ROOT=" .. projectPath

	if extraKconfigFragments ~= nil and extraKconfigFragments ~= "" then
		cmd = cmd .. " -DEXTRA_CONF_FILE=" .. projectPath .. "/" .. extraKconfigFragments
	end

	if baseDevicetreeOverlays ~= nil and baseDevicetreeOverlays ~= "" then
		cmd = cmd .. " -DDTC_OVERLAY_FILE=".. projectPath .. "/" .. baseDevicetreeOverlays
	end

	if extraDevicetreeOverlays ~= nil and extraDevicetreeOverlays ~= "" then
		local overlayDir = projectPath .. "/" .. extraDevicetreeOverlays
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
            overlayFiles = overlayFiles:gsub("%s+", ";")
			cmd = cmd .. ' -DEXTRA_DTC_OVERLAY_FILE="' .. overlayFiles .. '"'
		end
	end
	return cmd
end

function nrfBuildProject()
    local workspacePath = getConfigField(var.id.NRF_SDK, var.key.NRF_WORKSPACE_PATH)
	local project = getConfigField(var.id.NRF_SDK, var.key.NRF_PROJECT_NAME)
	local application = getConfigField(var.id.NRF_SDK, var.key.NRF_APPLICATION)

    local projectPath = workspacePath .. "/" .. project
    local applicationPath = workspacePath .. "/" .. project .. "/" .. application

    return "cd " .. projectPath .. " && " .. workspacePath .."/.venv/bin/python -m west build --build-dir " .. applicationPath .. "/build " .. applicationPath
end

function nrfFlashProject()
	local snDevice = getConfigField(var.id.NRF_SDK, var.key.NRF_SN_DEVICE)
    local workspacePath = getConfigField(var.id.NRF_SDK, var.key.NRF_WORKSPACE_PATH)
	local project = getConfigField(var.id.NRF_SDK, var.key.NRF_PROJECT_NAME)
	local application = getConfigField(var.id.NRF_SDK, var.key.NRF_APPLICATION)

    local projectPath = workspacePath .. "/" .. project
    local applicationPath = workspacePath .. "/" .. project .. "/" .. application
	-- local monitor = nrfRTTMonitorProject() -- Automatically get the RTT monitor

    return "cd "
		.. projectPath
        .. " && " .. workspacePath .."/.venv/bin/python -m west flash -d "
		.. applicationPath
		.. "/build --dev-id "
		.. snDevice
		.. " --erase"
		-- .. " --erase && "
		-- .. monitor
end

function nrfRTTMonitorProject()
	local snDevice = getConfigField(var.id.NRF_SDK, var.key.NRF_SN_DEVICE)
    local workspacePath = getConfigField(var.id.NRF_SDK, var.key.NRF_WORKSPACE_PATH)
	local project = getConfigField(var.id.NRF_SDK, var.key.NRF_PROJECT_NAME)
	local application = getConfigField(var.id.NRF_SDK, var.key.NRF_APPLICATION)

    local projectPath = workspacePath .. "/" .. project
    local applicationPath = workspacePath .. "/" .. project .. "/" .. application

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
		.. projectPath
		.. " && nrfjprog -s "
		.. snDevice
		.. " -r && python -m west rtt -r jlink --build-dir "
		.. applicationPath
		.. "/build -- --speed 1000"
end

function nrfDebugMonitorProject()
    local workspacePath = getConfigField(var.id.NRF_SDK, var.key.NRF_WORKSPACE_PATH)
	local project = getConfigField(var.id.NRF_SDK, var.key.NRF_PROJECT_NAME)
	local application = getConfigField(var.id.NRF_SDK, var.key.NRF_APPLICATION)
    local applicationPath = workspacePath .. "/" .. project .. "/" .. application
    return workspacePath .. "/.venv/bin/python -m west debug --runner jlink --build-dir " .. applicationPath .. "/build"
end


function getScoreNrf()
	local score = 0
	local currentPath = vim.fn.expand("%:p:h")

    local workspacePath = getConfigField(var.id.NRF_SDK, var.key.NRF_WORKSPACE_PATH)
	local project = getConfigField(var.id.NRF_SDK, var.key.NRF_PROJECT_NAME)
	local application = getConfigField(var.id.NRF_SDK, var.key.NRF_APPLICATION)
    local applicationPath = workspacePath .. "/" .. project .. "/" .. application

	if not currentPath:find(applicationPath, 1, true) then
		return score
	end

	local filename = vim.api.nvim_buf_get_name(0)
	local build_exist = vim.fn.isdirectory(applicationPath .. "/build") == 1
	local prj_found = vim.fn.systemlist("find . -name " .. applicationPath .. "prj.conf")

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
