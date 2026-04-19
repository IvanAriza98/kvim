-- =============================================================================
-- Code Projects: Sub-workspaces dentro de Code
-- =============================================================================
-- Persiste proyectos en configs.json bajo:
--   code.projects = { { id, name, root, buffers = {} }, ... }
--   code.active   = "project_id"

local M = {}

local config_utils = require("kvim.utils.config-utils")

local DEFAULT_PROJECT_NAME = "workspace1"

local function get_cwd()
    local uv = vim.uv or vim.loop
    if uv and type(uv.cwd) == "function" then
        return uv.cwd()
    end
    return vim.fn.getcwd()
end

local function normalize_path(path)
    if not path or path == "" then
        return nil
    end
    return vim.fn.fnamemodify(path, ":p")
end

local function path_exists(path)
    local uv = vim.uv or vim.loop
    return type(path) == "string" and path ~= "" and uv and uv.fs_stat(path) ~= nil
end

local function is_normal_file_buffer(bufnr)
    if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
        return false
    end

    local buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr })
    if buftype ~= "" then
        return false
    end

    local name = vim.api.nvim_buf_get_name(bufnr)
    return name ~= ""
end

local function is_code_workspace()
    local ok, title = pcall(vim.api.nvim_tabpage_get_var, 0, "title")
    return ok and title == "Code"
end

local function ensure_code_config()
    local code = config_utils.getConfigField("code")
    if type(code) ~= "table" then
        code = {}
    end

    if type(code.projects) ~= "table" then
        code.projects = {}
    end

    if code.active ~= nil and type(code.active) ~= "string" then
        code.active = nil
    end

    return code
end

local function save_code_config(code)
    config_utils.setConfigField(code, "code")
end

local function make_project(name, root)
    local safe_name = (name and name ~= "") and name or DEFAULT_PROJECT_NAME
    local safe_root = normalize_path(root) or normalize_path(get_cwd())

    return {
        id = tostring(vim.fn.localtime()) .. "-" .. tostring(math.random(1000, 9999)),
        name = safe_name,
        root = safe_root,
        buffers = {},
    }
end

local function get_projects_and_active()
    local code = ensure_code_config()
    local projects = code.projects
    local active = code.active
    return code, projects, active
end

local function get_project_by_id(projects, project_id)
    for _, project in ipairs(projects) do
        if project.id == project_id then
            return project
        end
    end
    return nil
end

local function ensure_active_project(code)
    local projects = code.projects

    if #projects == 0 then
        local default_project = make_project(DEFAULT_PROJECT_NAME, get_cwd())
        table.insert(projects, default_project)
        code.active = default_project.id
        return default_project
    end

    local active = get_project_by_id(projects, code.active)
    if active then
        return active
    end

    code.active = projects[1].id
    return projects[1]
end

local function save_project_buffers(project, buffer_paths)
    project.buffers = buffer_paths
end

local function load_project_buffers(project)
    if type(project.buffers) ~= "table" then
        project.buffers = {}
    end

    local first_valid = nil
    local valid_count = 0
    local loaded_bufnrs = {}

    for _, buffer_path in ipairs(project.buffers) do
        local abs_path = normalize_path(buffer_path)
        if abs_path and path_exists(abs_path) then
            local bufnr = vim.fn.bufadd(abs_path)
            if bufnr and bufnr > 0 then
                valid_count = valid_count + 1
                table.insert(loaded_bufnrs, bufnr)
                if not first_valid then
                    first_valid = abs_path
                end
            end
        end
    end

    if first_valid then
        vim.cmd("edit " .. vim.fn.fnameescape(first_valid))
    end

    return valid_count, loaded_bufnrs
end

local function open_project_root_in_current_window(root)
    -- Intentamos abrir el root en la ventana actual para evitar flotantes.
    local ok_edit = pcall(vim.cmd, "edit " .. vim.fn.fnameescape(root))
    if ok_edit then
        return true
    end

    -- Fallback robusto: abrir buffer vacío en ventana principal y avisar.
    pcall(vim.cmd, "enew")
    vim.notify(
        "Proyecto sin buffers persistidos y no se pudo abrir el directorio raíz en la ventana actual",
        vim.log.levels.WARN
    )
    return false
end

local function add_buffer_to_project(project, path)
    local abs_path = normalize_path(path)
    if not abs_path then
        return false
    end

    if type(project.buffers) ~= "table" then
        project.buffers = {}
    end

    for _, existing in ipairs(project.buffers) do
        if normalize_path(existing) == abs_path then
            return false
        end
    end

    table.insert(project.buffers, abs_path)
    return true
end

function M.setup()
    local code = ensure_code_config()
    local _ = ensure_active_project(code)
    save_code_config(code)
end

function M.list_projects()
    local _, projects, _ = get_projects_and_active()
    return projects
end

function M.get_projects()
    return M.list_projects()
end

function M.get_active_project()
    local code, projects, _ = get_projects_and_active()
    return ensure_active_project(code) or projects[1]
end

function M.get_active_project_name()
    local project = M.get_active_project()
    return project and project.name or nil
end

function M.get_active_project_id()
    local project = M.get_active_project()
    return project and project.id or nil
end

function M.switch_project(project_id)
    local code, projects, _ = get_projects_and_active()
    local project = get_project_by_id(projects, project_id)
    if not project then
        return false
    end

    local changing_project = code.active ~= project.id

    code.active = project.id

    if not path_exists(project.root) then
        project.root = normalize_path(get_cwd())
    end

    save_code_config(code)

    pcall(vim.cmd, "tcd " .. vim.fn.fnameescape(project.root))
    local loaded_count = 0
    local loaded_bufnrs = {}
    if changing_project then
        loaded_count, loaded_bufnrs = load_project_buffers(project)
    end

    for _, bufnr in ipairs(loaded_bufnrs) do
        if vim.api.nvim_buf_is_valid(bufnr) then
            vim.b[bufnr].kvim_workspace = "code"
            vim.b[bufnr].kvim_code_project = project.id
        end
    end

    local current_buf = vim.api.nvim_get_current_buf()
    if is_normal_file_buffer(current_buf) then
        vim.b[current_buf].kvim_workspace = "code"
        vim.b[current_buf].kvim_code_project = project.id
    end

    if changing_project and loaded_count == 0 then
        open_project_root_in_current_window(project.root)
    end

    return true
end

function M.next_project()
    local code, projects, _ = get_projects_and_active()
    local active = ensure_active_project(code)
    if #projects <= 1 then
        return
    end

    local index = 1
    for i, project in ipairs(projects) do
        if project.id == active.id then
            index = i
            break
        end
    end

    local next_index = (index % #projects) + 1
    M.switch_project(projects[next_index].id)
end

function M.prev_project()
    local code, projects, _ = get_projects_and_active()
    local active = ensure_active_project(code)
    if #projects <= 1 then
        return
    end

    local index = 1
    for i, project in ipairs(projects) do
        if project.id == active.id then
            index = i
            break
        end
    end

    local prev_index = ((index - 2 + #projects) % #projects) + 1
    M.switch_project(projects[prev_index].id)
end

function M.add_project(name, root)
    local code, projects, _ = get_projects_and_active()
    local project = make_project(name, root)

    table.insert(projects, project)
    code.active = project.id
    save_code_config(code)

    M.switch_project(project.id)

    return project
end

function M.rename_project(project_id, new_name)
    if not new_name or new_name == "" then
        return false
    end

    local code, projects, _ = get_projects_and_active()
    local project = get_project_by_id(projects, project_id)
    if not project then
        return false
    end

    project.name = new_name
    save_code_config(code)
    return true
end

function M.delete_project(project_id)
    local code, projects, _ = get_projects_and_active()
    if #projects <= 1 then
        vim.notify("No se puede borrar el último proyecto", vim.log.levels.WARN)
        return false
    end

    local remove_index = nil
    for i, project in ipairs(projects) do
        if project.id == project_id then
            remove_index = i
            break
        end
    end

    if not remove_index then
        return false
    end

    local removed_id = projects[remove_index].id
    table.remove(projects, remove_index)

    if code.active == removed_id then
        code.active = projects[1].id
    end

    save_code_config(code)
    M.switch_project(code.active)
    return true
end

function M.on_buffer_enter(bufnr)
    if not is_code_workspace() then
        return
    end

    if not is_normal_file_buffer(bufnr) then
        return
    end

    local code, projects, _ = get_projects_and_active()
    local active = ensure_active_project(code)
    if not active then
        return
    end

    vim.b[bufnr].kvim_workspace = "code"
    vim.b[bufnr].kvim_code_project = active.id

    local path = normalize_path(vim.api.nvim_buf_get_name(bufnr))
    if not path then
        return
    end

    if add_buffer_to_project(active, path) then
        save_project_buffers(active, active.buffers)
        save_code_config(code)
    end
end

function M.show_project_picker()
    local code, projects, _ = get_projects_and_active()
    local active = ensure_active_project(code)

    local items = {}
    for _, project in ipairs(projects) do
        table.insert(items, {
            id = project.id,
            name = project.name,
            root = project.root,
            active = active and project.id == active.id,
        })
    end

    vim.ui.select(items, {
        prompt = "Selecciona proyecto (Code)",
        format_item = function(item)
            local marker = item.active and "* " or "  "
            return marker .. item.name .. " — " .. item.root
        end,
    }, function(choice)
        if not choice then
            return
        end
        M.switch_project(choice.id)
    end)
end

return M
