local M = {}

local function map(mode, lhs, rhs, opts)
    if not lhs or lhs == "" then
        return
    end

    vim.keymap.set(mode, lhs, rhs, opts)
end

local function refresh_tabline()
    pcall(vim.cmd, "redrawtabline")
    pcall(function()
        local bufferline = require("bufferline")
        if type(bufferline.refresh) == "function" then
            bufferline.refresh()
        end
    end)
end

local function list_role_buffers(role)
    local buffers = {}
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(bufnr) and vim.bo[bufnr].buflisted then
            local is_terminal = vim.bo[bufnr].buftype == "terminal"
            if (role == "term" and is_terminal) or (role ~= "term" and not is_terminal) then
                table.insert(buffers, bufnr)
            end
        end
    end

    table.sort(buffers)
    return buffers
end

local function cycle_role_buffer(step)
    local ok_state, ws_state = pcall(require, "kvim.modules.workspaces.state")
    if not ok_state then
        vim.cmd(step > 0 and "bnext" or "bprevious")
        return
    end

    local current_tabnr = vim.fn.tabpagenr()
    local role = ws_state.get_tab_role(current_tabnr)
    if role ~= "code" and role ~= "term" then
        vim.cmd(step > 0 and "bnext" or "bprevious")
        return
    end

    local buffers = list_role_buffers(role)
    if #buffers == 0 then
        return
    end

    local current = vim.api.nvim_get_current_buf()
    local index = 1
    for i, bufnr in ipairs(buffers) do
        if bufnr == current then
            index = i
            break
        end
    end

    local next_index = ((index - 1 + step) % #buffers) + 1
    vim.api.nvim_set_current_buf(buffers[next_index])
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

    map("n", prefix .. "n", "<cmd>KvimWorkspaceNext<CR>", {
        silent = true,
        noremap = true,
        desc = "Workspaces: Siguiente workspace",
    })

    map("n", prefix .. "p", "<cmd>KvimWorkspacePrev<CR>", {
        silent = true,
        noremap = true,
        desc = "Workspaces: Workspace anterior",
    })

    map("n", prefix .. "t", "<cmd>KvimWorkspaceTerminalList<CR>", {
        silent = true,
        noremap = true,
        desc = "Workspaces: Listar recetas de terminal",
    })

    map("n", prefix .. "a", "<cmd>KvimWorkspaceTerminalAdd<CR>", {
        silent = true,
        noremap = true,
        desc = "Workspaces: Añadir receta de terminal",
    })

    map("n", prefix .. "r", "<cmd>KvimWorkspaceTerminalRestore<CR>", {
        silent = true,
        noremap = true,
        desc = "Workspaces: Restaurar terminales",
    })

    map("n", prefix .. "h", "<cmd>KvimWorkspaceTermHome<CR>", {
        silent = true,
        noremap = true,
        desc = "Workspaces: Ir al hub Term",
    })

    map("n", "<leader>1", function()
        vim.cmd("KvimWorkspaceTabCode")
        refresh_tabline()
    end, {
        silent = true,
        noremap = true,
        desc = "Workspaces: Ir a tab code",
    })

    map("n", "<leader>2", function()
        vim.cmd("KvimWorkspaceTabTerm")
        refresh_tabline()
    end, {
        silent = true,
        noremap = true,
        desc = "Workspaces: Ir a tab term",
    })

    map("n", "]b", function()
        cycle_role_buffer(1)
    end, {
        silent = true,
        noremap = true,
        desc = "Buffers: Ir al siguiente buffer",
    })

    map("n", "[b", function()
        cycle_role_buffer(-1)
    end, {
        silent = true,
        noremap = true,
        desc = "Buffers: Ir al buffer anterior",
    })

    map("n", "<Tab>", function()
        cycle_role_buffer(1)
    end, {
        silent = true,
        noremap = true,
        desc = "Buffers: Siguiente buffer (rápido)",
    })

    map("n", "<S-Tab>", function()
        cycle_role_buffer(-1)
    end, {
        silent = true,
        noremap = true,
        desc = "Buffers: Buffer anterior (rápido)",
    })
end

return M
