local M = {}

local storage = require("kvim.modules.workspaces.storage")
local state = require("kvim.modules.workspaces.state")

local function get_resession()
    local ok, resession = pcall(require, "resession")
    if not ok then
        return nil, "resession.nvim is not available"
    end

    return resession
end

local function derive_name_from_cwd()
    local cwd = vim.fn.getcwd()
    local name = vim.fn.fnamemodify(cwd, ":t")
    if not name or name == "" then
        return "workspace"
    end

    return name
end

local function build_workspace(name)
    local workspace_name = name
    if not workspace_name or workspace_name == "" then
        workspace_name = derive_name_from_cwd()
    end

    return {
        name = workspace_name,
        root = vim.fn.getcwd(),
        session = workspace_name,
        version = 1,
        connections = {
            active = nil,
        },
        terminals = {},
        tasks = {},
    }
end

M.save_current = {
    callback = function(name)
        local resession, resession_err = get_resession()
        if not resession then
            vim.notify("KVIM Workspaces: " .. resession_err, vim.log.levels.ERROR)
            return nil, resession_err
        end

        local workspace = build_workspace(name)
        local ok_save, err_save = storage.save(workspace)
        if not ok_save then
            vim.notify("KVIM Workspaces: failed to save workspace: " .. tostring(err_save), vim.log.levels.ERROR)
            return nil, err_save
        end

        local ok_session, err_session = pcall(resession.save, workspace.session)
        if not ok_session then
            vim.notify("KVIM Workspaces: failed to save session: " .. tostring(err_session), vim.log.levels.ERROR)
            return nil, tostring(err_session)
        end

        state.set_current(workspace)
        vim.notify("KVIM Workspaces: saved workspace '" .. workspace.name .. "'", vim.log.levels.INFO)
        return workspace
    end,
}

M.load = {
    callback = function(name)
        if not name or name == "" then
            vim.notify("KVIM Workspaces: workspace name is required", vim.log.levels.ERROR)
            return nil, "workspace name is required"
        end

        local resession, resession_err = get_resession()
        if not resession then
            vim.notify("KVIM Workspaces: " .. resession_err, vim.log.levels.ERROR)
            return nil, resession_err
        end

        local workspace, load_err = storage.load(name)
        if not workspace then
            vim.notify("KVIM Workspaces: failed to load workspace: " .. tostring(load_err), vim.log.levels.ERROR)
            return nil, load_err
        end

        if workspace.root and workspace.root ~= "" and vim.fn.isdirectory(workspace.root) == 1 then
            vim.cmd("cd " .. vim.fn.fnameescape(workspace.root))
        end

        local session_name = workspace.session or workspace.name
        local ok_session, err_session = pcall(resession.load, session_name)
        if not ok_session then
            vim.notify("KVIM Workspaces: failed to load session: " .. tostring(err_session), vim.log.levels.ERROR)
            return nil, tostring(err_session)
        end

        state.set_current(workspace)
        vim.notify("KVIM Workspaces: loaded workspace '" .. workspace.name .. "'", vim.log.levels.INFO)
        return workspace
    end,
}

M.list = {
    callback = function()
        local workspaces, err = storage.list()
        if not workspaces then
            vim.notify("KVIM Workspaces: failed to list workspaces: " .. tostring(err), vim.log.levels.ERROR)
            return nil, err
        end

        if #workspaces == 0 then
            vim.notify("KVIM Workspaces: no workspaces found", vim.log.levels.INFO)
            return workspaces
        end

        vim.notify("KVIM Workspaces: " .. table.concat(workspaces, ", "), vim.log.levels.INFO)
        return workspaces
    end,
}

M.delete = {
    callback = function(name)
        if not name or name == "" then
            vim.notify("KVIM Workspaces: workspace name is required", vim.log.levels.ERROR)
            return nil, "workspace name is required"
        end

        local ok_delete, err_delete = storage.delete(name)
        if not ok_delete then
            vim.notify("KVIM Workspaces: failed to delete workspace: " .. tostring(err_delete), vim.log.levels.ERROR)
            return nil, err_delete
        end

        local current = state.get_current()
        if current and current.name == name then
            state.clear_current()
        end

        vim.notify("KVIM Workspaces: deleted workspace '" .. name .. "'", vim.log.levels.INFO)
        return true
    end,
}

M.current = {
    callback = function()
        local current = state.get_current()
        if not current then
            vim.notify("KVIM Workspaces: no active workspace", vim.log.levels.INFO)
            return nil
        end

        vim.notify("KVIM Workspaces: current workspace '" .. current.name .. "'", vim.log.levels.INFO)
        return current
    end,
}

return M
