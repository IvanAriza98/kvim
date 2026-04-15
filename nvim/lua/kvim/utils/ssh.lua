local config_utils = require("kvim.utils.config-utils")

-- Helper function to get active SSH session object
local function getActiveSession()
	local active_index = config_utils.getActiveSSH()
	if not active_index then
		vim.notify("No active SSH session. Set one with :SSHSetActive <n>", vim.log.levels.ERROR)
		return nil
	end

	local sessions = config_utils.getSSHSessions()
	if not sessions or not sessions[active_index] then
		vim.notify("Invalid SSH session index: " .. tostring(active_index), vim.log.levels.ERROR)
		return nil
	end

	return sessions[active_index]
end

function share_pub_key(key_type, user, ip, port)
	-- Check if all parameters are provided
	local has_all_params = key_type and user and ip and port

	-- If not all params provided, try to get from active session
	local session = nil
	if not has_all_params then
		session = getActiveSession()
		if not session then
			return
		end
	end

	-- Use session values as fallback for missing params
	key_type = key_type or (session and session.key_type)
	user = user or (session and session.user)
	ip = ip or (session and session.ip)
	port = tostring(port or (session and session.port))

	if not key_type or key_type == "" then
		vim.notify("SSH key type is not defined", vim.log.levels.ERROR)
		return
	end
	if not ip or ip == "" then
		vim.notify("SSH IP is not defined", vim.log.levels.ERROR)
		return
	end
	if not user or user == "" then
		vim.notify("SSH user is not defined", vim.log.levels.ERROR)
		return
	end

	local key_path = os.getenv("HOME") .. "/.ssh/id_" .. key_type
	local pub_key_path = key_path .. ".pub"

	if vim.fn.filereadable(key_path) == 0 then
		vim.notify(string.format("Generating %s key...", key_type:upper()), vim.log.levels.INFO)
		os.execute(string.format('ssh-keygen -t %s -b 4096 -f "%s" -N ""', key_type, key_path))
	end

	local cmd = string.format('ssh-copy-id -f -i "%s" -p %s %s@%s', pub_key_path, port, user, ip)
	vim.cmd("new")
	vim.fn.termopen(cmd)
	vim.cmd("startinsert")
end

function ssh_terminal(direction)
	local session = getActiveSession()
	if not session then
		return
	end

	local ip = session.ip
	local port = tostring(session.port)
	local user = session.user

	if not ip or not user then
		vim.notify("SSH session is missing ip or user", vim.log.levels.ERROR)
		return
	end

	local size = 30
	if direction == "vertical" then
		size = math.floor(vim.o.columns * 0.5)
	elseif direction == "horizontal" then
		size = math.floor(vim.o.lines * 0.3)
	end

	-- Create a new ToggleTerm terminal with SSH command
	local term = require("toggleterm.terminal").Terminal:new({
		cmd = string.format("ssh -p %s %s@%s", port, user, ip),
		hidden = true, -- Ensure the terminal is not shown initially
		direction = direction, -- Make the terminal float and take full screen
		size = size,
	})
	term:toggle() -- Toggle the terminal to show it
end

function transfer_file(file, local_to_remote)
	local session = getActiveSession()
	if not session then
		return
	end

	local ip = session.ip
	local port = tostring(session.port)
	local path = session.path
	local user = session.user

	if not (ip and path and file) then
		vim.notify("Missing parameters: ip, path, or file", vim.log.levels.ERROR)
		return
	end

	if local_to_remote == true then
		os.execute(string.format("/usr/bin/scp -P %s '%s' %s@%s:'%s'", port, file, user, ip, path))
		vim.notify("File sent successfully", vim.log.levels.INFO)
	else
		os.execute(string.format("/usr/bin/scp -P %s %s@%s:'%s' '%s'", port, user, ip, path, vim.fn.expand("%:p:h")))
		vim.notify("File received successfully", vim.log.levels.INFO)
	end
end

-- Ssh Terminal
vim.keymap.set("n", "<C-t>rj", function()
	ssh_terminal("horizontal")
end, { silent = true, noremap = true })

vim.keymap.set("n", "<C-t>rl", function()
	ssh_terminal("vertical")
end, { silent = true, noremap = true })

vim.keymap.set("n", "<C-t>rf", function()
	ssh_terminal("float")
end, { silent = true, noremap = true })

-- Transfer current file
vim.keymap.set("n", "<C-t>af", function()
	local file = vim.api.nvim_buf_get_name(0)
	if file == "" then
		print("File not detected")
		return
	end
	transfer_file(file, true)
end, { silent = true, noremap = true })

-- Show selection files menu
vim.keymap.set("n", "<C-t>f", function()
	-- Directorio en el que buscar los archivos
	local file_or_dir = vim.fn.input("Enter directory path: ", vim.fn.expand("%:p:h"), "file")
	if file_or_dir == "" then
		print("No directory entered")
		return
	end
	if vim.fn.filereadable(file_or_dir) == 1 or vim.fn.isdirectory(file_or_dir) == 1 then
		transfer_file(file_or_dir, true)
	else
		print("File or directory does not exist")
	end
end, { silent = true, noremap = true })

-- Función para transferir ficheros del servidor ssh a nuestra máquina local
vim.keymap.set("n", "<C-g>f", function()
	transfer_file(vim.fn.input("Enter gettting directory path: "), false)
end, { silent = true, noremap = true })

return {
    ssh_terminal = ssh_terminal,
    transfer_file = transfer_file,
    share_pub_key = share_pub_key,
}
