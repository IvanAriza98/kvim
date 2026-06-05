local M = {}

local current_workspace = nil
local tab_roles = {}
local active_tab_role = nil

local function tabnr_exists(tabnr)
    for _, tabpage in ipairs(vim.api.nvim_list_tabpages()) do
        if vim.api.nvim_tabpage_get_number(tabpage) == tabnr then
            return true
        end
    end

    return false
end

function M.set_current(workspace)
    current_workspace = workspace
end

function M.get_current()
    return current_workspace
end

function M.clear_current()
    current_workspace = nil
end

function M.set_tab_role(tabnr, role)
    if type(tabnr) ~= "number" or tabnr < 1 then
        return
    end

    tab_roles[tabnr] = role
end

function M.get_tab_role(tabnr)
    return tab_roles[tabnr]
end

function M.find_tab_by_role(role)
    for tabnr, tab_role in pairs(tab_roles) do
        if not tabnr_exists(tabnr) then
            tab_roles[tabnr] = nil
        elseif tab_role == role then
            return tabnr
        end
    end

    return nil
end

function M.prune_invalid_tab_roles()
    for tabnr, _ in pairs(tab_roles) do
        if not tabnr_exists(tabnr) then
            tab_roles[tabnr] = nil
        end
    end
end

function M.get_all_tab_roles()
    return vim.deepcopy(tab_roles)
end

function M.clear_tab_roles()
    tab_roles = {}
end

function M.set_active_tab_role(role)
    if type(role) ~= "string" or role == "" then
        active_tab_role = nil
        return
    end

    active_tab_role = role
end

function M.get_active_tab_role()
    return active_tab_role
end

return M
