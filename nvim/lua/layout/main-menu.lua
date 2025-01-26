require("layout.config-environment")

local n = require("nui-components")
local var = require("config.environment-vars")

local mainRender = n.create_renderer({with=50, height=10}) 

local development = n.create_signal({ environment = var.id.ESP_IDF_C_CPP })
local is_tab_active = n.is_active_factory(development.environment)

function mainMenu()
    return n.tabs(
      { active_tab = development.environment },
      n.columns(
	{ flex = 0 },
	n.button({
	  label = var.label.ESP_IDF_C_CPP,
	  global_press_key = "<S-u>",
	  is_active = is_tab_active(var.id.ESP_IDF_C_CPP),
	  on_press = function()
	    development.environment = var.id.ESP_IDF_C_CPP
	  end,
	}),
	n.gap(1),
	n.button({
	  label = var.label.ESP_IDF_MICRO,
	  global_press_key = "<S-u>",
	  is_active = is_tab_active(var.id.ESP_IDF_MICRO),
	  on_press = function()
	    development.environment = var.id.ESP_IDF_MICRO
	  end,
	}),
	n.gap(1),
	n.button({
	  label = var.label.C_CPP,
	  global_press_key = "<S-i>",
	  is_active = is_tab_active(var.id.C_CPP),
	  on_press = function()
	    development.environment = var.id.C_CPP
	  end,
	}),
	n.gap(1),
	n.button({
	  label = var.label.PYTHON,
	  global_press_key = "<S-o>",
	  is_active = is_tab_active(var.id.PYTHON),
	  on_press = function()
	    development.environment = var.id.PYTHON
	  end,
	})
      ),
      n.gap(1),
      n.tab(
	{ id = var.id.ESP_IDF_C_CPP },
	esp_idf_config_c_cpp(mainRender)		
      ),
      n.tab(
	{ id = var.id.ESP_IDF_MICRO },
	esp_idf_config_c_cpp(mainRender)		
      ),
      n.tab(
	{ id = var.id.C_CPP},
	esp_idf_config_c_cpp(mainRender)		
      ),
      n.tab(
	{ id = var.id.PYTHON},
	config_python(mainRender)		
      )
    )
end
mainRender:render(mainMenu()) 
