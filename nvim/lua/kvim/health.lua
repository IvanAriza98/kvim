-- lua/kvim/health.lua

local M = {}

local health = require("kvim.core.health")

local module_dependency_specs = {
    git = {
        { cmd = "lazygit", label = "git module: lazygit" },
    },
    svn = {
        { cmd = "svn", label = "svn module: svn" },
        { cmd = "lazysvn", label = "svn module: lazysvn" },
    },
    connections = {
        { cmd = "ssh", label = "connections module: ssh" },
        { cmd = "scp", label = "connections module: scp" },
        { cmd = "ssh-keygen", label = "connections module: ssh-keygen" },
        { cmd = "ssh-copy-id", label = "connections module: ssh-copy-id" },
        { cmd = "picocom", label = "connections module: picocom" },
    },
}

local function sorted_enabled_module_names(config)
    local enabled = {}

    for module_name, module_opts in pairs(config.modules or {}) do
        if type(module_opts) == "table" and module_opts.enabled then
            table.insert(enabled, module_name)
        end
    end

    table.sort(enabled)

    return enabled
end

local function check_appname()
    local appname = vim.env.NVIM_APPNAME or "nvim"

    if appname == "kvim" then
        health.ok("NVIM_APPNAME is set to 'kvim'")
        return
    end

    health.warn("NVIM_APPNAME is '" .. appname .. "' instead of recommended 'kvim'")
end

local function check_core_dependencies()
    health.check_executable("git", { required = true })
    health.check_executable("neovide", { label = "neovide" })
end

local function check_enabled_module_dependencies(config)
    local enabled_modules = sorted_enabled_module_names(config)

    if #enabled_modules == 0 then
        health.warn("No KVIM modules enabled")
        return
    end

    health.ok("Enabled modules: " .. table.concat(enabled_modules, ", "))

    for _, module_name in ipairs(enabled_modules) do
        local specs = module_dependency_specs[module_name]

        if specs then
            for _, spec in ipairs(specs) do
                health.check_executable(spec.cmd, spec)
            end
        end
    end
end

local function check_connections_health(config)
    local connections_config = config.modules and config.modules.connections

    if not (type(connections_config) == "table" and connections_config.enabled) then
        return
    end

    local ok, module_health = pcall(require, "kvim.modules.connections.health")

    if not ok then
        health.error("Failed to load connections health check: " .. tostring(module_health))
        return
    end

    if type(module_health) ~= "table" or type(module_health.check) ~= "function" then
        health.error("Connections health check is not available")
        return
    end

    local ok_check, err = pcall(module_health.check, connections_config)

    if not ok_check then
        health.error("Connections health check failed: " .. tostring(err))
    end
end

function M.check()
    local config = require("kvim.config").get()

    health.start("KVIM")
    check_appname()
    check_core_dependencies()
    check_enabled_module_dependencies(config)
    check_connections_health(config)
end

return M
