-- General
vim.api.nvim_set_keymap('n', '<C-s>', ':w!<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<C-e>', ':q!<CR>', { noremap = true })
vim.api.nvim_set_keymap('n', '<ESC>', ':noh<CR>', { noremap = true })
		
--- Upload
--- Configures
vim.g.target_ip = '172.28.1.1'
vim.api.nvim_set_keymap('n', '<C-1>', ':lua vim.g.target_ip = vim.fn.input("New Target IP: ")<CR>', { noremap = true })

local function UploadFile()
    local ip = vim.g.target_ip
    local file_path = vim.fn.expand('%:p')
    local cmd = 'term python "C:\\Users\\iariza\\OneDrive - Teltronic S.A. Unipersonal\\Scripts\\Uploader\\main.py" -m 0 -p \"' .. file_path .. '\" -t \"' .. ip .. '\"'
    vim.api.nvim_command('tabnew')
    vim.api.nvim_command(cmd)
end
_G.UploadFile = UploadFile

vim.api.nvim_set_keymap('n', '<C-t>f', ':lua UploadFile()<CR>', { noremap = true })


--- target debugger esp32
vim.g.esp32_mode = 'build'
vim.g.esp32_target_port = '/dev/ttyUSB1'
vim.api.nvim_set_keymap('n', '<C-2>', ':lua vim.g.esp32_target_port = vim.fn.input("[ESP32] New Debugger Port [/dev/ttyUSBX]: ")<CR>', { noremap = true, silent = true})
vim.api.nvim_set_keymap('n', '<C-3>', ':lua vim.g.esp32_mode = vim.fn.input("[ESP32] Select IDF mode [build | flash | bflash | monitor]: ")<CR>', { noremap = true, silent = true})

local function UtilityIDF()
    local mode = vim.g.esp32_mode
    local port = vim.g.esp32_target_port
    local file_path = vim.fn.fnamemodify(vim.fn.expand('%:p'), ':h')
    local cmd = 'term python "/home/kodvmv/Documentos/GitHub/kvim/esp-idf-util.py" --port \"' .. port ..'\" --path \"' .. file_path .. '\" --mode \"' .. mode .. '\"'
    vim.api.nvim_command('tabnew')
    vim.api.nvim_command(cmd)
end
_G.UtilityIDF = UtilityIDF
vim.api.nvim_set_keymap('n', '<C-p>p', ':lua UtilityIDF()<CR>', { noremap = true })
