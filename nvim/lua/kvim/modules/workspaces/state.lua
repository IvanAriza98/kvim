local M = {}

local current_workspace = nil

function M.set_current(workspace)
    current_workspace = workspace
end

function M.get_current()
    return current_workspace
end

function M.clear_current()
    current_workspace = nil
end

return M
