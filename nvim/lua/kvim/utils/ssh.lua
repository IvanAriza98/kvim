local vars = require("kvim.config.environment-vars")

function share_pub_key(key_type, user, ip, port)
	local key_path = os.getenv("HOME") .. "/.ssh/id_" .. key_type
	local pub_key_path = key_path .. ".pub"

    if not key_type or key_type == "" then
		print("❌ SSH key type is not defined")
		return
    end
	if not ip or ip == "" then
		print("❌ SSH ip is not defined")
		return
	end
	if not user or user == "" then
		print("❌ SSH user is not defined")
		return
	end

	if vim.fn.filereadable(key_path) == 0 then
		print(string.format("🔑 Generating %s key...", key_type:upper()))
		os.execute(string.format('ssh-keygen -t %s -b 4096 -f "%s" -N ""', key_type, key_path))
	end

	local cmd = string.format('ssh-copy-id -f -i "%s" -p %s %s@%s', pub_key_path, port, user, ip)
    vim.cmd("new")
    vim.fn.termopen(cmd)
    vim.cmd("startinsert")
end

function ssh_terminal(direction)
	local ip = getConfigField(vars.id.SSH, vars.key.SSH_IP)
	local port = getConfigField(vars.id.SSH, vars.key.SSH_PORT)
	local user = getConfigField(vars.id.SSH, vars.key.SSH_USER)

	local size = 30
	if direction == "vertical" then
		size = math.floor(vim.o.columns * 0.3)
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
	local ip = getConfigField(vars.id.SSH, vars.key.SSH_IP)
	local port = getConfigField(vars.id.SSH, vars.key.SSH_PORT)
	local path = getConfigField(vars.id.SSH, vars.key.SSH_PATH)
	local user = getConfigField(vars.id.SSH, vars.key.SSH_USER)

	if not (ip and path and file) then
		print("Error: Missing parameters ...")
		return
	end

	if local_to_remote == true then
		os.execute(string.format("/usr/bin/scp -P %s '%s' %s@%s:'%s'", port, file, user, ip, path))
		print("Sended OK.")
	else
		os.execute(string.format("/usr/bin/scp -P %s %s@%s:'%s' '%s'", port, user, ip, path, vim.fn.expand("%:p:h")))
		print("Sended OK.")
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
