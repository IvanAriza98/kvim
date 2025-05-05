local var = require('kvim.config.environment-vars')

function pytExecute()
    local python_bin = getConfigField(var.id.PYTHON, var.key.PYT_PATH)
    return python_bin.." "..vim.api.nvim_buf_get_name(0)
end


function getScorePyt()
    local score = 0
    local filename = vim.api.nvim_buf_get_name(0)

    if filename:match("%.py") then
	score = score + 1
    end

    return score
end


