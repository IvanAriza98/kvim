require("kvim.utils.devices")
local n = require("nui-components")
local vars = require("kvim.config.environment-vars")

local nrfSdk = n.create_signal({
	prj = { "" },
	board = { "" },
	device = { "" },
	appPath = { "" },
})

local function save_nrf_sdk()
	setConfigField(nrfSdk:get_value().prj, vars.id.NRF_SDK, vars.key.NRF_PRJ)
	setConfigField(nrfSdk:get_value().board, vars.id.NRF_SDK, vars.key.NRF_BOARD)
	setConfigField(nrfSdk:get_value().device, vars.id.NRF_SDK, vars.key.NRF_DEVICE)
	setConfigField(nrfSdk:get_value().appPath, vars.id.NRF_SDK, vars.key.NRF_APPPATH)
	setConfigField(nrfSdk:get_value().zephyrPath, vars.id.NRF_SDK, vars.key.NRF_ZEPHYRPATH)
end

function config_nrf_sdk()
	local nrf_devices_list = {}
	nrfSdk.prj = getConfigField(vars.id.NRF_SDK, vars.key.NRF_PRJ)
	nrfSdk.board = getConfigField(vars.id.NRF_SDK, vars.key.NRF_BOARD)
	nrfSdk.device = getConfigField(vars.id.NRF_SDK, vars.key.NRF_DEVICE)
	nrfSdk.appPath = getConfigField(vars.id.NRF_SDK, vars.key.NRF_APPPATH)
	nrfSdk.zephyrPath = getConfigField(vars.id.NRF_SDK, vars.key.NRF_ZEPHYRPATH)
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
			border_label = "Board/Micro",
			value = nrfSdk:get_value().board,
			on_change = function(value)
				nrfSdk.board = value
			end,
		}),
		n.text_input({
			flex = 1,
			selected = nrfSdk.prj,
			border_label = "Prj.conf",
			value = nrfSdk:get_value().prj,
			on_change = function(value)
				nrfSdk.prj = value
			end,
		}),
		n.text_input({
			flex = 1,
			border_label = "Zephyr path",
			value = nrfSdk:get_value().zephyrPath,
			on_change = function(value)
				nrfSdk.zephyrPath = value
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
						nrfSdk.device = node.text
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
