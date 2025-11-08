--- Component to build or execute algorithms (build esp-idf, compile C programs, run python programs ...)
require("kvim.utils.python-commands")
require("kvim.utils.esp-idf-commands")
require("kvim.utils.nrf-sdk-commands")

function getEnvironment()
	local scoreNrf = getScoreNrf()
	local scorePyt = getScorePyt()
	-- TODO review different getScored environment
    -- local scoreIdf = getScoreIdf()
	-- local scoreCpp = getScoreCpp()
	-- local max_score = math.max(scoreNrf, scoreIdf, scorePyt) --, scoreCpp)
	local max_score = math.max(scoreNrf, scorePyt) --, scoreCpp)


	if max_score == 0 then
	elseif max_score == scoreNrf then
		return "nrf"
	elseif max_score == scorePyt then
		return "pyt"
	-- TODO review different getScored environment
	-- elseif max_score == scoreIdf then
	-- 	return "idf"
    -- elseif max_score == scoreCpp then
    -- return "cpp"
	end
end

-- Function to config projects
vim.keymap.set("n", "<F4>", function()
	local cmd = "botright split | term "
	local env = getEnvironment()
	if env == "nrf" then
		vim.cmd(cmd .. nrfConfigBuildProject())
	end
end, { noremap = true, desc = "Build" })

vim.keymap.set("n", "<F5>", function()
	local cmd = "botright split | term "
	local env = getEnvironment()
	if env == "nrf" then
		vim.cmd(cmd .. nrfBuildProject())
	-- vim.cmd(cmd..nrfBuildProject())
	elseif env == "idf" then
		vim.cmd(cmd .. idfBuildProject())
	elseif env == "pyt" then
		vim.cmd(cmd .. pytExecute())
	elseif env == "cpp" then
	end
end, { noremap = true, desc = "Build" })

vim.keymap.set("n", "<F6>", function()
	local cmd = "botright split | term "
	local env = getEnvironment()
	if env == "nrf" then
		vim.cmd(cmd .. nrfFlashProject())
	end
end, { noremap = true, desc = "Flash" })

vim.keymap.set("n", "<F7>", function()
	local cmd = "botright split | term "
	local env = getEnvironment()
	if env == "nrf" then
		vim.cmd(cmd .. nrfRTTMonitorProject())
	end
end, { noremap = true, desc = "Monitor" })

vim.keymap.set("n", "<F8>", function()
	local cmd = "botright split | term "
	local env = getEnvironment()
	if env == "nrf" then
		vim.cmd(cmd .. nrfDebugMonitorProject())
	end
end, { noremap = true, desc = "Monitor" })
