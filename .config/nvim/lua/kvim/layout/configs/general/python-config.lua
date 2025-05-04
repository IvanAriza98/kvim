local n = require("nui-components")
local vars = require('kvim.config.environment-vars')

local python = n.create_signal({
    path = "",
    scriptPath = "" })

local function save_config()
    setConfigField(vars.env.PYTHON, vars.key.ENVIRONMENT)
    setConfigField(python:get_value().path, vars.id.PYTHON, vars.key.PYTHON_PATH)
    setConfigField(python:get_value().scriptPath, vars.id.PYTHON, vars.key.PYTHON_SCRIPT_PATH)
end

function config_python() --render)
    python.path = getConfigField(vars.id.PYTHON, vars.key.PYTHON_PATH)
    return n.form(
	{
	    id = "python-settings",
	    submit_key = "<c-cr>",
	    on_submit = function(_)
		save_config()
	    end,
	},
	n.gap(1),
	n.paragraph({
	    autofocus = true,
	    lines = "Python Configurator",
	    align ="center",
	}),
	n.gap(1),
	n.text_input({
	    border_label = "Python path",
	    value = python.path,
	    on_change = function(value, _)
		python.path = value
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
		    save_config()
		end,
	    }),
	    n.gap(3),
	    n.button({
		label = "Exit",
		on_press = function ()
		end,
	    })
	)
    )
end
