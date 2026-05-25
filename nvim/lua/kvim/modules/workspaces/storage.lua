local M = {}

local function base_dir()
    return vim.fn.stdpath("state") .. "/kvim/workspaces"
end

local function file_exists(path)
    return vim.fn.filereadable(path) == 1
end

local function sanitize_name(name)
    return tostring(name):gsub("[^%w%._-]", "_")
end

function M.ensure_dir()
    local dir = base_dir()
    if vim.fn.isdirectory(dir) == 0 then
        local ok = vim.fn.mkdir(dir, "p")
        if ok == 0 then
            return nil, "failed to create workspaces dir: " .. dir
        end
    end

    return dir
end

function M.workspace_path(name)
    if type(name) ~= "string" or name == "" then
        return nil, "workspace name is required"
    end

    local dir, err = M.ensure_dir()
    if not dir then
        return nil, err
    end

    return dir .. "/" .. sanitize_name(name) .. ".json"
end

function M.save(workspace)
    if type(workspace) ~= "table" then
        return nil, "workspace must be a table"
    end

    if type(workspace.name) ~= "string" or workspace.name == "" then
        return nil, "workspace.name is required"
    end

    local path, path_err = M.workspace_path(workspace.name)
    if not path then
        return nil, path_err
    end

    local ok_encode, encoded = pcall(vim.json.encode, workspace)
    if not ok_encode then
        return nil, "failed to encode workspace: " .. tostring(encoded)
    end

    local ok_write, write_err = pcall(vim.fn.writefile, { encoded }, path)
    if not ok_write then
        return nil, "failed to write workspace: " .. tostring(write_err)
    end

    return true
end

function M.load(name)
    local path, path_err = M.workspace_path(name)
    if not path then
        return nil, path_err
    end

    if not file_exists(path) then
        return nil, "workspace not found: " .. tostring(name)
    end

    local ok_read, lines = pcall(vim.fn.readfile, path)
    if not ok_read then
        return nil, "failed to read workspace: " .. tostring(lines)
    end

    local ok_decode, workspace = pcall(vim.json.decode, table.concat(lines, "\n"))
    if not ok_decode then
        return nil, "failed to decode workspace: " .. tostring(workspace)
    end

    if type(workspace.terminals) ~= "table" then
        workspace.terminals = {}
    end

    return workspace
end

function M.list()
    local dir, err = M.ensure_dir()
    if not dir then
        return nil, err
    end

    local files = vim.fn.globpath(dir, "*.json", false, true)
    local names = {}

    for _, file in ipairs(files) do
        local filename = vim.fn.fnamemodify(file, ":t")
        local name = filename:gsub("%.json$", "")
        table.insert(names, name)
    end

    table.sort(names)
    return names
end

function M.delete(name)
    local path, path_err = M.workspace_path(name)
    if not path then
        return nil, path_err
    end

    if not file_exists(path) then
        return nil, "workspace not found: " .. tostring(name)
    end

    local ok, rm_err = pcall(vim.fn.delete, path)
    if not ok or rm_err ~= 0 then
        return nil, "failed to delete workspace: " .. tostring(name)
    end

    return true
end

return M
