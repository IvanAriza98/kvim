require('kvim.utils.devices')
local n = require('nui-components')
local vars = require('kvim.config.environment-vars')

local espidf = n.create_signal({
    port = {""},
    family = {""},
    buildPath = {""} })

local function save_esp_idf_c_cpp()
    setConfigField(vars.env.ESP_IDF_C_CPP, vars.key.ENVIRONMENT) -- deprecated 

    setConfigField(espidf:get_value().port, vars.id.ESP_IDF_C_CPP, vars.key.PORT)
    setConfigField(espidf:get_value().family, vars.id.ESP_IDF_C_CPP, vars.key.FAMILY)
    setConfigField(espidf:get_value().buildPath, vars.id.ESP_IDF_C_CPP, vars.key.BUILD_PATH)
end

function config_esp_idf_c_cpp()
    local usb_devices_list = {}
    espidf.port = getConfigField(vars.id.ESP_IDF_C_CPP, vars.key.PORT)
    espidf.family = getConfigField(vars.id.ESP_IDF_C_CPP, vars.key.FAMILY)
    espidf.buildPath = getConfigField(vars.id.ESP_IDF_C_CPP, vars.key.BUILD_PATH)

    for _, device in ipairs(get_usb_devices()) do
	table.insert(usb_devices_list, n.option(device.name, { id = device.path}))
    end

    local form_elements= {
	n.gap(1),
	n.paragraph({
	    autofocus = true,
	    lines = "ESP IDF Configurator",
	    align ="center",
	}),
	n.gap(1),
	n.select({
	    border_label = "Select family",
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
		n.option("esp32c5", { id = "esp32c5" }),
		n.option("esp32c61", { id = "esp32c61" }),
		n.option("linux", { id = "linux" })
	    },
	    on_select = function(node, _)
		espidf.family = node.text
	    end,
	}),
	n.text_input({
	    flex = 1,
	    autoresize = true,
	    border_label = "Build path",
	    value = espidf:get_value().buildPath,
	    on_change = function(value, _)
		espidf.buildPath = value
	    end,
	}),
	n.columns(
	    n.button({
		label = "Back",
		on_press = function ()
		end,
	    }),
	    n.gap(3),
	    n.button({
		label = "Save",
		on_press = function ()
		    save_esp_idf_c_cpp()
		end,
	    }),
	    n.gap(3),
	    n.button({
		label = "Exit",
		on_press = function ()
		end,
	    })
	),
	    }
    if usb_devices_list ~= nil then
	if #usb_devices_list > 0 then
	    table.insert(form_elements, 4,
		n.select({
			border_label = "Select port",
			selected = espidf:get_value().port,
			data = usb_devices_list,
			on_select = function(node, _)
			    local dev = string.match(node.text, "%s*([^%->]*)%s*%-?>")
			    espidf.port = dev or node.text:gsub("%s*%-?>.*", "")
			end,
		})
	    )
	end
    end
    return n.form(
	{
	    id = "esp32-settings",
	    on_submit = function(_)
	    end,
	},
	unpack(form_elements)
    )
end
