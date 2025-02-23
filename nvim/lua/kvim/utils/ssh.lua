local vars = require('kvim.config.environment-vars')

function ssh_terminal(direction)
    local targetIp = getConfigField(vars.id.SSH, vars.key.TARGET_IP)
    local targetUser = getConfigField(vars.id.SSH, vars.key.TARGET_USER)
    -- Create a new ToggleTerm terminal with SSH command
    local term = require("toggleterm.terminal").Terminal:new({
        cmd = string.format("ssh %s@%s -p 10022", targetUser, targetIp),
        hidden = true,  -- Ensure the terminal is not shown initially
        direction = direction,  -- Make the terminal float and take full screen
	size = 40
    })
    term:toggle()  -- Toggle the terminal to show it
end

function transfer_file(file)
    local targetIp = getConfigField(vars.id.SSH, vars.key.TARGET_IP)
    local targetDir = getConfigField(vars.id.SSH, vars.key.TARGET_DIR)
    local targetUser = getConfigField(vars.id.SSH, vars.key.TARGET_USER)

    if not (targetIp and targetDir and file) then
	print("Error: Missing parameters ...")
	return
    end
    os.execute(string.format("scp -P 10022 -r %s %s@%s:%s", file, targetUser, targetIp, targetDir))
end

-- Ssh Connection 
vim.keymap.set('n', "<C-c>hr", function()
    ssh_terminal("horizontal")
end, {silent = true, noremap = true});

vim.keymap.set('n', "<C-c>vr", function()
    ssh_terminal("vertical")
end, {silent = true, noremap = true});

vim.keymap.set('n', "<C-c>fr", function()
    ssh_terminal("float")
end, {silent = true, noremap = true});

-- Transfer actual file
vim.keymap.set('n', "<C-t>af", function()
    local file = vim.api.nvim_buf_get_name(0)
    print(file)
    if file == "" then
	print("File not detected")
	return
    end
    transfer_file(file)
end, {silent = true, noremap = true});

-- Mostrar menú de selección de archivos
vim.keymap.set('n', "<C-t>f", function()
    -- Directorio en el que buscar los archivos
    local file_or_dir = vim.fn.input("Enter directory path: ", vim.fn.expand("%:p:h"), "file")
    if file_or_dir == "" then
        print("No directory entered")
        return
    end
    if vim.fn.filereadable(file_or_dir) == 1 or vim.fn.isdirectory(file_or_dir) == 1 then
	transfer_file(file_or_dir)
    else
	print("File or directory does not exist")
    end
end, {silent = true, noremap = true})


