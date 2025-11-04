require("kvim.utils.devices")
local n = require("nui-components")
local vars = require("kvim.config.environment-vars")

local nrfSdk = n.create_signal({
	appPath = { "" },
	zephyrVersionPath = { "" },
	zephyrCompilerPath = { "" },
	boardTarget = { "" },
	baseConfigFiles = { "" },
	extraKconfigFragments = { "" },
	baseDevicetreeOverlays = { "" },
	extraDevicetreeOverlays = { "" },
	snDevice = { "" },
})

local function save_nrf_sdk()
	setConfigField(nrfSdk:get_value().appPath, vars.id.NRF_SDK, vars.key.NRF_APP_PATH)
	setConfigField(nrfSdk:get_value().zephyrVersionPath, vars.id.NRF_SDK, vars.key.NRF_ZEPHYR_VERSION_PATH)
	setConfigField(nrfSdk:get_value().zephyrCompilerPath, vars.id.NRF_SDK, vars.key.NRF_ZEPHYR_COMPILER_PATH)
	setConfigField(nrfSdk:get_value().boardTarget, vars.id.NRF_SDK, vars.key.NRF_BOARD_TARGET)
	setConfigField(nrfSdk:get_value().baseConfigFiles, vars.id.NRF_SDK, vars.key.NRF_CONFIG_FILES)
	setConfigField(nrfSdk:get_value().extraKconfigFragments, vars.id.NRF_SDK, vars.key.NRF_EXTRA_KCONFIG_FRAGMENTS)
	setConfigField(nrfSdk:get_value().baseDevicetreeOverlays, vars.id.NRF_SDK, vars.key.NRF_BASE_DEVICETREE_OVERLAYS)
	setConfigField(nrfSdk:get_value().extraDevicetreeOverlays, vars.id.NRF_SDK, vars.key.NRF_EXTRA_DEVICETREE_OVERLAYS)
	setConfigField(nrfSdk:get_value().snDevice, vars.id.NRF_SDK, vars.key.NRF_SN_DEVICE)
end

function config_nrf_sdk()
	local nrf_devices_list = {}
	nrfSdk.appPath = getConfigField(vars.id.NRF_SDK, vars.key.NRF_APP_PATH)
	nrfSdk.zephyrVersionPath = getConfigField(vars.id.NRF_SDK, vars.key.NRF_ZEPHYR_VERSION_PATH)
	nrfSdk.zephyrCompilerPath = getConfigField(vars.id.NRF_SDK, vars.key.NRF_ZEPHYR_COMPILER_PATH)
	nrfSdk.boardTarget = getConfigField(vars.id.NRF_SDK, vars.key.NRF_BOARD_TARGET)
	nrfSdk.baseConfigFiles = getConfigField(vars.id.NRF_SDK, vars.key.NRF_CONFIG_FILES)

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
			border_label = "App path",
			value = nrfSdk:get_value().appPath,
			on_change = function(value)
				nrfSdk.appPath = value
			end,
		}),
        n.text_input({
			flex = 1,
			border_label = "Zephyr Version Path",
			value = nrfSdk:get_value().zephyrVersionPath,
			on_change = function(value)
				nrfSdk.zephyrVersionPath = value
			end,
		}),
		n.text_input({
			flex = 1,
			border_label = "Zephyr Compiler Path",
			value = nrfSdk:get_value().zephyrCompilerPath,
			on_change = function(value)
				nrfSdk.zephyrCompilerPath = value
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
			selected = nrfSdk.baseConfigFiles,
			border_label = "Base Configuration Files (Kconfig)",
			value = nrfSdk:get_value().baseConfigFiles,
			on_change = function(value)
				nrfSdk.baseConfigFiles = value
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
			border_label = "Extra Devicetree Overlays (Directories)",
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
