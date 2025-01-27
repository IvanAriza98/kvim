require('utils.devices')

local n = require("nui-components")
local vars = require('config.environment-vars')


local python = n.create_signal({ path = '', scriptPath = '' })
local espidf = n.create_signal({ port = '', family = '', buildPath = '' })

local function save_esp_idf_config_c_cpp()
    setConfigField(vars.env.ESP_IDF_C_CPP, vars.key.ENVIRONMENT)
    if espidf:get_value().port ~= getConfigField(vars.env.ESP_IDF_C_CPP, vars.key.PORT) then
	setConfigField(espidf:get_value().port, vars.id.ESP_IDF_C_CPP, vars.key.PORT)
    end
    setConfigField(espidf:get_value().family, vars.id.ESP_IDF_C_CPP, vars.key.FAMILY)
    setConfigField(espidf:get_value().buildPath, vars.id.ESP_IDF_C_CPP, vars.key.BUILD_PATH)
end

function esp_idf_config_c_cpp(render)
    local usb_devices_list = {}
    for path, device in ipairs(get_usb_devices()) do
	table.insert(usb_devices_list, n.option(device.name, { id = device.path}))
    end
    
    -- el env debería de ser global para acceder desde cualquier lado
    espidf.port = getConfigField(vars.id.ESP_IDF_C_CPP, vars.key.PORT)
    espidf.family = getConfigField(vars.id.ESP_IDF_C_CPP, vars.key.FAMILY)
    espidf.buildpath = getConfigField(vars.id.ESP_IDF_C_CPP, vars.key.BUILD_PATH)
    
    local form_elements= {
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
		n.option("linux", { id = "linux" }),
		n.option("esp32c5", { id = "esp32c5" }),
		n.option("esp32c61", { id = "esp32c61" }),
	    },
	    multiselect = false,
	    on_select = function(node, component)
		espidf.family = node.text
	    end,
	}),	
	n.text_input({
	    flex = 1,
	    border_label = "Build path",
	    value = espidf.buildPath,
	    on_change = function(value, component)
		espidf.buildPath = value
	    end,
	}),
    }
    
    if usb_device_list ~= nil then
	if #usb_device_list > 0 then 
	    table.insert(form_elements, 2, 	
		n.select({
			border_label = "Select port",
			selected = espidf.port,
			data = usb_devices_list,
			multiselect = false,
			on_select = function(node, component)
			    espidf.port = node.text
			end,
		})
	    )
	end
    end
    return n.form(
	{
	    id = "esp32-settings",
	    submit_key = "<c-cr>",
	    on_submit = function(is_valid)
		save_esp_idf_config_c_cpp()
		render:close()
	    end,
	},
	unpack(form_elements)
    )
end

local function save_python_config()
    setConfigField(vars.env.PYTHON, vars.key.ENVIRONMENT)
    setConfigField(python:get_value().path, vars.id.PYTHON, vars.key.PYTHON_PATH)
    setConfigField(python:get_value().scriptPath, vars.id.PYTHON, vars.key.PYTHON_SCRIPT_PATH)
end

function config_python(render)
    python.path = getConfigField(vars.id.PYTHON, vars.key.PYTHON_PATH)
    python.scriptPath = getConfigField(vars.id.PYTHON, vars.key.PYTHON_SCRIPT_PATH)
    return n.form(
	{
	    id = "python-settings",
	    submit_key = "<c-cr>",
	    on_submit = function(is_valid)
		save_python_config()
		render:close()
	    end,
	},
	n.text_input({
	    flex = 1,
	    border_label = "python path",
	    value = python.path,
	    on_change = function(value, component)
		python.path = value
	    end,
	}),
	n.text_input({
	    flex = 1,
	    border_label = "script path",
	    placeholder = "If it's empty, Kvim use the local file path that you're using.",
	    value = python.scriptPath,
	    on_change = function(value, component)
		python.scriptPath = value
	    end,
	})
    )

end
