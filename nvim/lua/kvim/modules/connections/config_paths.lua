local M = {}

local function file_exists(path)
    return type(path) == "string" and path ~= "" and vim.fn.filereadable(path) == 1
end

local function parent_dir(path)
    return vim.fn.fnamemodify(path, ":h")
end

local function ensure_parent_dir(path)
    local dir = parent_dir(path)
    if vim.fn.isdirectory(dir) == 1 then
        return true
    end

    return vim.fn.mkdir(dir, "p") == 1
end

local function backup_path(path)
    return path .. ".bak"
end

function M.user_config_path()
    return vim.fn.stdpath("config") .. "/connections.lua"
end

function M.legacy_config_path()
    return vim.fn.stdpath("config") .. "/lua/kvim/connections.lua"
end

function M.default_config_path()
    local source = debug.getinfo(1, "S").source:sub(2)
    local dir = vim.fn.fnamemodify(source, ":h")
    return dir .. "/defaults/connections.lua"
end

function M.create_backup(path)
    if not file_exists(path) then
        return true
    end

    local lines = vim.fn.readfile(path)
    return vim.fn.writefile(lines, backup_path(path)) == 0
end

function M.initialize_user_config()
    local target = M.user_config_path()
    if file_exists(target) then
        return target
    end

    local default_path = M.default_config_path()
    if not file_exists(default_path) then
        return nil, "default connections template not found: " .. default_path
    end

    if not ensure_parent_dir(target) then
        return nil, "failed to create config dir for: " .. target
    end

    local lines = vim.fn.readfile(default_path)
    if vim.fn.writefile(lines, target) ~= 0 then
        return nil, "failed to create user config: " .. target
    end

    vim.notify("KVIM Connections: created user config from default template", vim.log.levels.INFO)
    return target
end

function M.migrate_legacy_config()
    local target = M.user_config_path()
    if file_exists(target) then
        return target, false
    end

    local legacy = M.legacy_config_path()
    if not file_exists(legacy) then
        return nil, false
    end

    if not ensure_parent_dir(target) then
        return nil, "failed to create config dir for: " .. target
    end

    if not M.create_backup(legacy) then
        return nil, "failed to create legacy backup for: " .. legacy
    end

    local lines = vim.fn.readfile(legacy)
    if vim.fn.writefile(lines, target) ~= 0 then
        return nil, "failed to migrate legacy config to: " .. target
    end

    vim.notify(
        "KVIM Connections: migrated legacy config to " .. target,
        vim.log.levels.INFO
    )

    return target, true
end

function M.ensure_user_config()
    local current = M.user_config_path()
    if file_exists(current) then
        return current
    end

    local migrated, migrated_err = M.migrate_legacy_config()
    if migrated then
        return migrated
    end
    if migrated_err then
        return nil, migrated_err
    end

    return M.initialize_user_config()
end

return M
