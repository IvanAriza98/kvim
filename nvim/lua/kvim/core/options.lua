vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

vim.opt.wrap = true         --- Permite que las lineas largas se visualicen en varias lineas
vim.opt.linebreak = true    --- Evita que corte palabras a la mitad
vim.opt.breakindent = true  --- mantiene el estilo de indentanción en las líneas envueltas

vim.opt.cursorline = true
vim.opt.syntax = "on"
vim.opt.expandtab = true
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4
vim.opt.softtabstop = 4
vim.opt.smarttab = true
vim.opt.hlsearch = true
vim.opt.incsearch = true
vim.opt.compatible = false

vim.opt.termguicolors = true

--- lines customization
vim.wo.number = true
vim.wo.relativenumber = true

--- Paths
local kvim_home = vim.env.KVIM_HOME
if not kvim_home or kvim_home == "" then
	vim.notify(
		"Env variable KVIM_HOME is not set. Please set it to the path of your KVIM installation.",
		vim.log.levels.ERROR
	)
	return
end

vim.g.kvim_home = kvim_home
vim.g.configs_path = vim.g.kvim_home .. "nvim/configs.json"

vim.opt.tabline = "%!v:lua.MyTabline()"

function _G.MyTabline()
    local s = ""

    for i, tab in ipairs(vim.api.nvim_list_tabpages()) do
        local ok, title = pcall(vim.api.nvim_tabpage_get_var, tab, "title")
        local name = (ok and title) or ("Tab " .. i)

        if i == vim.fn.tabpagenr() then
            s = s .. "%#TabLineSel#"
        else
            s = s .. "%#TabLine#"
        end

        s = s .. " " .. name .. " %*"
    end

    return s
end
