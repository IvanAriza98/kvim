local M = {}

local function map(mode, lhs, rhs, opts)
    if not lhs or lhs == "" then
        return
    end

    vim.keymap.set(mode, lhs, rhs, opts)
end

function M.setup(opts)
    opts = opts or {}

    local module_config = require("kvim.modules.workspaces.config").get()
    local prefix = opts.prefix or module_config.prefix or "<leader>w"

    map("n", prefix .. "s", "<cmd>KvimWorkspaceSave<CR>", {
        silent = true,
        noremap = true,
        desc = "Workspaces: Guardar workspace actual",
    })

    map("n", prefix .. "l", "<cmd>KvimWorkspaceList<CR>", {
        silent = true,
        noremap = true,
        desc = "Workspaces: Listar workspaces",
    })

    map("n", prefix .. "c", "<cmd>KvimWorkspaceCurrent<CR>", {
        silent = true,
        noremap = true,
        desc = "Workspaces: Mostrar workspace actual",
    })
end

return M
