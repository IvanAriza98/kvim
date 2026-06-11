-- lua/kvim/core/health.lua

local M = {}

local function report(method, fallback, message)
    if vim.health and vim.health[method] then
        vim.health[method](message)
        return
    end

    vim.fn[fallback](message)
end

function M.start(name)
    if vim.health and vim.health.start then
        vim.health.start(name)
        return
    end

    vim.fn["health#report_start"](name)
end

function M.ok(message)
    report("ok", "health#report_ok", message)
end

function M.warn(message)
    report("warn", "health#report_warn", message)
end

function M.error(message)
    report("error", "health#report_error", message)
end

function M.executable_exists(cmd)
    return vim.fn.executable(cmd) == 1
end

function M.check_executable(cmd, opts)
    opts = opts or {}

    if M.executable_exists(cmd) then
        M.ok((opts.label or cmd) .. " executable found")
        return true
    end

    local message = (opts.label or cmd) .. " executable not found"

    if opts.required then
        M.error(message)
    else
        M.warn(message)
    end

    return false
end

return M
