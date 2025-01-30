--- Component to build or execute algorithms (build esp-idf, compile C programs, run python programs ...)
require('kvim.utils.commands')
local n = require('nui-components')
local var = require('kvim.config.environment-vars')

local renderer = n.create_renderer({
  width = 60,
  height = 3,
})
local buf = vim.api.nvim_create_buf(false, true)
local body = function()
  return n.buffer({
	  id = "buffer",
	  flex = 1,
	  buf = buf,
	  autoscroll = false,
	  border_label = "Build Output",
	})
end

local function send_cmd(cmd)
    -- Limpia el buffer antes de empezar
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})

    vim.fn.jobstart(cmd, {
        stdout_buffered = false,
        on_stdout = function(_, data)
            if data[1] ~= "" then
                -- Añade las nuevas líneas al buffer
                vim.api.nvim_buf_set_lines(buf, -1, -1, false, data)

                -- Autoscroll: Mueve el cursor a la última línea en la ventana del buffer
                local win_id = vim.fn.bufwinid(buf)
                if win_id ~= -1 then
                    local line_count = vim.api.nvim_buf_line_count(buf)
                    vim.api.nvim_win_set_cursor(win_id, { line_count-1, 0 })
                end
            end
        end,
        on_stderr = function(_, data)
            if data[1] ~= "" then
                -- Añade errores al buffer
                vim.api.nvim_buf_set_lines(buf, -1, -1, false, data)

                -- Autoscroll: Igual que stdout
                local win_id = vim.fn.bufwinid(buf)
                if win_id ~= -1 then
                    local line_count = vim.api.nvim_buf_line_count(buf)
                    vim.api.nvim_win_set_cursor(win_id, { line_count-1, 0 })
                end
            end
        end,
	on_exit = function(_, exit_code)
	    vim.schedule(function()
		local msg = "✅ Command done."
		if exit_code ~= 0 then
		    msg = "❌ " ..msg .. "(exit code: "..exit_code..")"
		end
		local line_count = vim.api.nvim_buf_line_count(buf)
		vim.api.nvim_buf_set_lines(buf, line_count, line_count, false, {msg})
		local win_id = vim.fn.bufwinid(buf)
		if win_id ~= -1 then
		    vim.api.nvim_win_set_cursor(win_id, {line_count, 0})
		end
	    end)
	end,
    })
end

vim.keymap.set("n", "<F5>", function()
    local cfg_env = getConfigField(var.key.ENVIRONMENT)
    if cfg_env == var.env.ESP_IDF_C_CPP then
	-- local family = getConfigField(cfg_env, var.key.FAMILY)
	local buildPath = getConfigField(cfg_env, var.key.BUILD_PATH)
	-- send_cmd(espIdfFullCleanCmd(buildPath))
	-- send_cmd(espIdfSetTargetCmd(family, buildPath)) 
	send_cmd(espIdfBuildCmd(buildPath))
    end
    renderer:render(body)
    renderer:set_size({height = 30})
end, {noremap = true, desc = ""})

vim.keymap.set("n", "<F6>", function()
    local cfg_env = getConfigField(var.key.ENVIRONMENT)
    if cfg_env == var.env.ESP_IDF_C_CPP or cfg_env == var.env.ESP_IDF_MICRO then
	local port = getConfigField(cfg_env, var.key.PORT)
	local buildPath = getConfigField(cfg_env, var.key.BUILD_PATH)
	send_cmd(espIdfFlashCmd(port, buildPath))
    elseif cfg_env == var.env.PYTHON then
	send_cmd(pythonExecuteCmd())
    end
    renderer:render(body)
    renderer:set_size({height = 30})
end, {noremap = true, desc = ""})

vim.keymap.set("n", "<F7>", function()
    local cfg_env = getConfigField(var.key.ENVIRONMENT)
    if cfg_env == var.env.ESP_IDF_C_CPP or cfg_env == var.env.ESP_IDF_MICRO then
	local port = getConfigField(cfg_env, var.key.PORT)
	local buildPath = getConfigField(cfg_env, var.key.BUILD_PATH)
        vim.cmd("botright split | term " ..espIdfMonitorCmd(port, buildPath))

        -- Configuraciones clave
        vim.cmd([[
            setlocal nobuflisted
            setlocal bufhidden=hide
            setlocal winfixheight   " Mantener altura fija
            resize 12               " Altura inicial de 12 líneas
        ]])

    end
end, {noremap = true, desc = ""})
