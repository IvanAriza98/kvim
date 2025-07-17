--- Component to build or execute algorithms (build esp-idf, compile C programs, run python programs ...)
require('kvim.utils.python-commands')
require('kvim.utils.esp-idf-commands')
require('kvim.utils.nrf-sdk-commands')

function getEnvironment()
    local scoreNrf = getScoreNrf()
    local scoreIdf = getScoreIdf()
    local scorePyt = getScorePyt()
    -- local scoreCpp = getScoreCpp()

    local max_score = math.max(scoreNrf, scoreIdf, scorePyt) --, scoreCpp)

    if (max_score == 0) then
    elseif(max_score == scoreNrf) then
	return "nrf"
    elseif(max_score == scoreIdf) then
	return "idf"
    elseif(max_score == scorePyt) then
	return "pyt"
 --    elseif(max_score == scoreCpp) then
	-- return "cpp"
    end
end


vim.keymap.set("n", "<F5>", function()
    local cmd = "botright split | term "
    local env = getEnvironment()
    if (env == "nrf") then
	vim.cmd(cmd..nrfConfigBuildProject())
	-- vim.cmd(cmd..nrfBuildProject())
    elseif (env == "idf") then
	vim.cmd(cmd..idfBuildProject())
    elseif (env == "pyt") then
	vim.cmd(cmd..pytExecute())
    elseif (env == "cpp") then
    end
end, { noremap = true, desc = "Build" })

vim.keymap.set("n", "<F6>", function()
    local cmd = "botright split | term "
    local env = getEnvironment()
    if (env == "nrf") then
	vim.cmd(cmd..nrfFlashProject())
    end
end, { noremap = true, desc = "Flash" })

-- vim.keymap.set("n", "<F5>", function()
--     local cfg_env = getConfigField(var.key.ENVIRONMENT)
--     if cfg_env == var.env.ESP_IDF_C_CPP then
-- 	-- local family = getConfigField(cfg_env, var.key.FAMILY)
-- 	local buildPath = getConfigField(cfg_env, var.key.BUILD_PATH)
-- 	-- send_cmd(espIdfFullCleanCmd(buildPath))
-- 	-- send_cmd(espIdfSetTargetCmd(family, buildPath)) 
-- 	-- send_cmd(espIdfBuildCmd(buildPath))
--         vim.cmd("botright split | term " ..espIdfBuildCmd(buildPath))
--
--         -- Configuraciones clave
--         vim.cmd([[
--             setlocal nobuflisted
--             setlocal bufhidden=hide
--             setlocal winfixheight   " Mantener altura fija
--             resize 12               " Altura inicial de 12 líneas
--         ]])
--
--     end
--     -- renderer:render(body)
--     -- renderer:set_size({height = 30})
-- end, {noremap = true, desc = ""})
--
-- vim.keymap.set("n", "<F6>", function()
--     local cfg_env = getConfigField(var.key.ENVIRONMENT)
--     if cfg_env == var.env.ESP_IDF_C_CPP or cfg_env == var.env.ESP_IDF_MICRO then
-- 	local port = getConfigField(cfg_env, var.key.PORT)
-- 	local buildPath = getConfigField(cfg_env, var.key.BUILD_PATH)
-- 	-- send_cmd(espIdfFlashCmd(port, buildPath))
-- 	vim.cmd("botright split | term " ..espIdfFlashCmd(port, buildPath))
--     elseif cfg_env == var.env.PYTHON then
-- 	-- send_cmd(pythonExecuteCmd())
-- 	vim.cmd("botright split | term " ..pythonExecuteCmd())
--     end
--     -- Configuraciones clave
--     vim.cmd([[
-- 	setlocal nobuflisted
-- 	setlocal bufhidden=hide
-- 	setlocal winfixheight   " Mantener altura fija
-- 	resize 12               " Altura inicial de 12 líneas
--     ]])
--     -- renderer:render(body)
--     -- renderer:set_size({height = 30})
-- end, {noremap = true, desc = ""})
--
-- vim.keymap.set("n", "<F7>", function()
--     local cfg_env = getConfigField(var.key.ENVIRONMENT)
--     if cfg_env == var.env.ESP_IDF_C_CPP or cfg_env == var.env.ESP_IDF_MICRO then
-- 	local port = getConfigField(cfg_env, var.key.PORT)
-- 	local buildPath = getConfigField(cfg_env, var.key.BUILD_PATH)
--         vim.cmd("botright split | term " ..espIdfMonitorCmd(port, buildPath))
--
--         -- Configuraciones clave
--         vim.cmd([[
--             setlocal nobuflisted
--             setlocal bufhidden=hide
--             setlocal winfixheight   " Mantener altura fija
--             resize 12               " Altura inicial de 12 líneas
--         ]])
--
--     end
-- end, {noremap = true, desc = ""})
