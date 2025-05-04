require("kvim.layout.configs.esp-idf.config")
require("kvim.layout.configs.nrf-sdk.config")
require("kvim.layout.configs.general.python-config")
require("kvim.layout.configs.communications.ssh-config")

require("kvim.utils.devices")

local n = require("nui-components")

local btnRender = n.create_renderer({width=19, height=2})
local pythonRender = n.create_renderer({with=50, height=2})
local nrfSdkRender = n.create_renderer({with=50, height=10})
local espIdfcRender = n.create_renderer({with=50, height=10})

local sshRender = n.create_renderer({with=50, height=8})

-- Crear los botones
local function mainMenu()
    local btn_cnt = 0
    local function numbered_button(label, opts)
	btn_cnt = btn_cnt + 1
	return n.button({
	    label = ("%d. %s"):format(btn_cnt, label),
	    global_press_key = ("<C-%d>"):format(btn_cnt),
	    on_press = opts.on_press
	})
    end
    return n.rows(
	n.paragraph({
	    autofocus = true,
	    lines = "[Embedded]",
	    align = "center",
	}),
	numbered_button("Esp-Idf", {
	    on_press = function()
		btnRender:close()
		espIdfcRender:render(config_esp_idf_c_cpp())
	    end}),
	numbered_button("Nrf-Sdk", {
	    on_press = function()
		get_nrf_devices()
		btnRender:close()
		nrfSdkRender:render(config_nrf_sdk())
	    end}),

	n.gap(1),
	n.paragraph({
	    autofocus = true,
	    lines = "[General]",
	    align = "center",
	}),
	numbered_button("C++", {
	    on_press = function()
	    end}),
	numbered_button("Python", {
	    on_press = function()
		btnRender:close()
		pythonRender:render(config_python())
	    end}),

	n.gap(1),
	n.paragraph({
	    autofocus = true,
	    lines = "[MultiPlaform]",
	    align = "center",
	}),
	numbered_button("Flutter", {
	    on_press = function()
	    end}),
	n.gap(1),
	n.paragraph({
	    autofocus = true,
	    lines = "[Communications]",
	    align = "center",
	}),
	numbered_button("SSH", {
	    on_press = function()
		btnRender:close()
		sshRender:render(config_ssh())
	    end})
    );
end

vim.keymap.set("n", "<leader>k", function()
    btnRender:render(mainMenu())
end, {noremap = true, desc = ""})
