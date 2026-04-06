require("kvim.utils.devices")
local n = require("nui-components")
local vars = require("kvim.config.environment-vars")

local nrfSdk = n.create_signal({
	snDevice = "",
	workspacePath = "",
	projectName = "",
    application = "",
	boardTarget = "",
    appConfigFile = "", -- prj.conf
	extraKconfigFragments = "",
	baseDevicetreeOverlays = "",
    extraDevicetreeOverlays = "", -- boards/
})

local function strip_trailing_slash(path)
    if type(path) == "string"  then
        return path:gsub("/+$", "")
    end
    return path
end

local function save_nrf_sdk()
    local clean = {
        snDevice = strip_trailing_slash(nrfSdk:get_value().snDevice),
        workspacePath = strip_trailing_slash(nrfSdk:get_value().workspacePath),
        projectName = strip_trailing_slash(nrfSdk:get_value().projectName),
        application = strip_trailing_slash(nrfSdk:get_value().application),
        boardTarget = strip_trailing_slash(nrfSdk:get_value().boardTarget),
        appConfigFile = strip_trailing_slash(nrfSdk:get_value().appConfigFile),
        extraKconfigFragments = strip_trailing_slash(nrfSdk:get_value().extraKconfigFragments),
        baseDevicetreeOverlays = strip_trailing_slash(nrfSdk:get_value().baseDevicetreeOverlays),
        extraDevicetreeOverlays = strip_trailing_slash(nrfSdk:get_value().extraDevicetreeOverlays),
    }

	setConfigField(clean.snDevice, vars.id.NRF_SDK, vars.key.NRF_SN_DEVICE)
	setConfigField(clean.workspacePath, vars.id.NRF_SDK, vars.key.NRF_WORKSPACE_PATH)
    setConfigField(clean.projectName, vars.id.NRF_SDK, vars.key.NRF_PROJECT_NAME)
    setConfigField(clean.application, vars.id.NRF_SDK, vars.key.NRF_APPLICATION)
	setConfigField(clean.boardTarget, vars.id.NRF_SDK, vars.key.NRF_BOARD_TARGET)
	setConfigField(clean.appConfigFile, vars.id.NRF_SDK, vars.key.NRF_APP_CONFIG_FILE)
	setConfigField(clean.extraKconfigFragments, vars.id.NRF_SDK, vars.key.NRF_EXTRA_KCONFIG_FRAGMENTS)
	setConfigField(clean.baseDevicetreeOverlays, vars.id.NRF_SDK, vars.key.NRF_BASE_DEVICETREE_OVERLAYS)
	setConfigField(clean.extraDevicetreeOverlays, vars.id.NRF_SDK, vars.key.NRF_EXTRA_DEVICETREE_OVERLAYS)
end

function config_nrf_sdk()
	local nrf_devices_list = {}
	nrfSdk.workspacePath= getConfigField(vars.id.NRF_SDK, vars.key.NRF_WORKSPACE_PATH)
	nrfSdk.application = getConfigField(vars.id.NRF_SDK, vars.key.NRF_APPLICATION)
	nrfSdk.boardTarget = getConfigField(vars.id.NRF_SDK, vars.key.NRF_BOARD_TARGET)
	nrfSdk.appConfigFile = getConfigField(vars.id.NRF_SDK, vars.key.NRF_APP_CONFIG_FILE)
	nrfSdk.extraKconfigFragments = getConfigField(vars.id.NRF_SDK, vars.key.NRF_EXTRA_KCONFIG_FRAGMENTS)
	nrfSdk.baseDevicetreeOverlays = getConfigField(vars.id.NRF_SDK, vars.key.NRF_BASE_DEVICETREE_OVERLAYS)
	nrfSdk.extraDevicetreeOverlays = getConfigField(vars.id.NRF_SDK, vars.key.NRF_EXTRA_DEVICETREE_OVERLAYS)

	nrfSdk.snDevice = getConfigField(vars.id.NRF_SDK, vars.key.NRF_SN_DEVICE)
	for _, device in ipairs(get_nrf_devices()) do
		table.insert(nrf_devices_list, n.option(device, { id = device }))
	end

	local form_elements = {
		n.gap(1),
		n.paragraph({
			autofocus = true,
			lines = "NRF-SDK Configurator",
			align = "center",
		}),
		n.gap(1),

		n.text_input({
			flex = 1,
			border_label = "Workspace [Path]",
			value = nrfSdk:get_value().workspacePath,
			on_change = function(value)
				nrfSdk.workspacePath = value
			end,
		}),
        n.text_input({
			flex = 1,
			border_label = "Project Name",
			value = nrfSdk:get_value().projectName,
			on_change = function(value)
				nrfSdk.projectName = value
			end,
		}),
        n.text_input({
			flex = 1,
			border_label = "Application",
			value = nrfSdk:get_value().application,
			on_change = function(value)
				nrfSdk.application = value
			end,
		}),
		n.text_input({
			flex = 1,
			border_label = "Board Target",
			value = nrfSdk:get_value().boardTarget,
			on_change = function(value)
				nrfSdk.boardTarget = value
			end,
		}),
		n.text_input({
			flex = 1,
			border_label = "Application Config File [prj.conf]",
			value = nrfSdk:get_value().appConfigFile,
			on_change = function(value)
				nrfSdk.appConfigFile= value
			end,
		}),
		n.text_input({
			flex = 1,
			selected = nrfSdk.extraKconfigFragments,
			border_label = "Extra Kconfig Fragments",
			value = nrfSdk:get_value().extraKconfigFragments,
			on_change = function(value)
				nrfSdk.extraKconfigFragments = value
			end,
		}),
		n.text_input({
			flex = 1,
			selected = nrfSdk.baseDevicetreeOverlays,
			border_label = "Base Devicetree Overlays",
			value = nrfSdk:get_value().baseDevicetreeOverlays,
			on_change = function(value)
				nrfSdk.baseDevicetreeOverlays = value
			end,
		}),
		n.text_input({
			flex = 1,
			selected = nrfSdk.extraDevicetreeOverlays,
			border_label = "Extra Devicetree Overlays",
			value = nrfSdk:get_value().extraDevicetreeOverlays,
			on_change = function(value)
				nrfSdk.extraDevicetreeOverlays = value
			end,
		}),

		n.columns(
			n.button({
				label = "Back",
				on_press = function() end,
			}),
			n.gap(3),
			n.button({
				label = "Save",
				on_press = function()
					save_nrf_sdk()
				end,
			}),
			n.gap(3),
			n.button({
				label = "Exit",
				on_press = function() end,
			})
		),
	}
	if nrf_devices_list ~= nil then
		if #nrf_devices_list > 0 then
			table.insert(
				form_elements,
				4,
				n.select({
					border_label = "Select device",
					-- selected = nrfSdk:get_value().device,
					data = nrf_devices_list,
					on_select = function(node, _)
						nrfSdk.snDevice = node.text
					end,
				})
			)
		end
	end
	return n.form({
		id = "nrf-sdk-settings",
		submit_key = "<C-cr>",
		on_submit = function(_)
			save_nrf_sdk()
		end,
	}, unpack(form_elements))
end
