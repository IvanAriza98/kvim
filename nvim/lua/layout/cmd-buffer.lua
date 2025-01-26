--- Component to build or execute algorithms (build esp-idf, compile C programs, run python programs ...)
require('utils.commands')
local n = require('nui-components')
local var = require('config.environment-vars') 

renderer = n.create_renderer({
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
            if data then
                -- Añade las nuevas líneas al buffer
                vim.api.nvim_buf_set_lines(buf, -1, -1, false, data)

                -- Autoscroll: Mueve el cursor a la última línea en la ventana del buffer
                local win_id = vim.fn.bufwinid(buf)
                if win_id ~= -1 then
                    local line_count = vim.api.nvim_buf_line_count(buf)
                    vim.api.nvim_win_set_cursor(win_id, { line_count, 0 })
                end
            end
        end,
        on_stderr = function(_, data)
            if data then
                -- Añade errores al buffer
                vim.api.nvim_buf_set_lines(buf, -1, -1, false, data)

                -- Autoscroll: Igual que stdout
                local win_id = vim.fn.bufwinid(buf)
                if win_id ~= -1 then
                    local line_count = vim.api.nvim_buf_line_count(buf)
                    vim.api.nvim_win_set_cursor(win_id, { line_count, 0 })
                end
            end
        end,
    })
end

 
vim.keymap.set("n", "<F5>", function()
    local env_cfg = getConfigField(var.key.ENVIRONMENT)
    if env_cfg == var.env.ESP_IDF_C_CPP or env_cfg == var.env.ESP_IDF_MICRO then
	send_cmd(espIdfExecuteCmd())
    elseif env_cfg == var.env.PYTHON then
	send_cmd(pythonExecuteCmd())
    end
    renderer:render(body)
    renderer:set_size({height = 20})
end, {noremap = true, desc = ""})

vim.keymap.set("n", "<F6>", function()
    send_cmd(espIdfBuildCmd())
    renderer:render(body)
    renderer:set_size({height = 20})
end, {noremap = true, desc = ""})
