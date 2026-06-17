describe("kvim.modules.connections.config", function()
  local config
  local paths
  local original_stdpath
  local original_filereadable
  local original_isdirectory
  local original_mkdir
  local original_readfile
  local original_writefile
  local original_notify
  local original_dofile

  local notifications
  local files
  local directories

  local function set_file(path, lines)
    files[path] = vim.deepcopy(lines)
    directories[vim.fn.fnamemodify(path, ":h")] = true
  end

  before_each(function()
    package.loaded["kvim.modules.connections.config"] = nil
    package.loaded["kvim.modules.connections.config_paths"] = nil

    notifications = {}
    files = {}
    directories = {}

    original_stdpath = vim.fn.stdpath
    original_filereadable = vim.fn.filereadable
    original_isdirectory = vim.fn.isdirectory
    original_mkdir = vim.fn.mkdir
    original_readfile = vim.fn.readfile
    original_writefile = vim.fn.writefile
    original_notify = vim.notify
    original_dofile = _G.dofile

    vim.notify = function(message, level)
      table.insert(notifications, { message = message, level = level })
    end

    vim.fn.stdpath = function(kind)
      if kind == "config" then
        return "/tmp/kvim-config"
      end
      return original_stdpath(kind)
    end

    vim.fn.filereadable = function(path)
      return files[path] and 1 or 0
    end

    vim.fn.isdirectory = function(path)
      return directories[path] and 1 or 0
    end

    vim.fn.mkdir = function(path)
      directories[path] = true
      return 1
    end

    vim.fn.readfile = function(path)
      local value = files[path]
      if not value then
        error("file not found: " .. tostring(path))
      end
      return vim.deepcopy(value)
    end

    vim.fn.writefile = function(lines, path)
      set_file(path, lines)
      return 0
    end

    _G.dofile = function(path)
      if path == "/tmp/kvim-config/connections.lua" then
        return {
          connections = {
            { type = "ssh", name = "srv", host = "127.0.0.1", user = "test", port = 22 },
          },
        }
      end

      if path == "/tmp/kvim-config/lua/kvim/connections.lua" then
        return {
          { type = "ssh", name = "legacy", host = "127.0.0.2", user = "old", port = 22 },
        }
      end

      error("unexpected dofile: " .. tostring(path))
    end

    config = require("kvim.modules.connections.config")
    paths = require("kvim.modules.connections.config_paths")
  end)

  after_each(function()
    vim.fn.stdpath = original_stdpath
    vim.fn.filereadable = original_filereadable
    vim.fn.isdirectory = original_isdirectory
    vim.fn.mkdir = original_mkdir
    vim.fn.readfile = original_readfile
    vim.fn.writefile = original_writefile
    vim.notify = original_notify
    _G.dofile = original_dofile

    package.loaded["kvim.modules.connections.config"] = nil
    package.loaded["kvim.modules.connections.config_paths"] = nil
  end)

  it("resolves canonical and legacy config paths", function()
    assert.are.equal("/tmp/kvim-config/connections.lua", paths.user_config_path())
    assert.are.equal("/tmp/kvim-config/lua/kvim/connections.lua", paths.legacy_config_path())
    assert.matches("defaults/connections.lua$", paths.default_config_path())
  end)

  it("creates user config from default template when missing", function()
    local default_path = paths.default_config_path()
    set_file(default_path, { "return {", "    connections = {},", "}" })

    local path = paths.ensure_user_config()

    assert.are.equal("/tmp/kvim-config/connections.lua", path)
    assert.is_truthy(files["/tmp/kvim-config/connections.lua"])
  end)

  it("migrates legacy config when canonical is missing", function()
    set_file("/tmp/kvim-config/lua/kvim/connections.lua", { "return {}" })

    local path = paths.ensure_user_config()

    assert.are.equal("/tmp/kvim-config/connections.lua", path)
    assert.is_truthy(files["/tmp/kvim-config/connections.lua"])
    assert.is_truthy(files["/tmp/kvim-config/lua/kvim/connections.lua.bak"])
  end)

  it("loads normalized connections from canonical config", function()
    set_file("/tmp/kvim-config/connections.lua", { "return {}" })

    local result = config.load({})

    assert.are.equal(1, #result)
    assert.are.equal("srv", result[1].name)
  end)

  it("normalizes legacy flat format", function()
    local result = config.normalize({
      { type = "ssh", name = "legacy", host = "127.0.0.1", user = "test", port = 22 },
    })

    assert.are.equal(1, #result)
    assert.are.equal("legacy", result[1].name)
  end)

  it("ignores invalid connections during normalize", function()
    local result = config.normalize({
      connections = {
        { type = "ssh", name = "ok", host = "127.0.0.1", user = "test", port = 22 },
        { type = "ssh", name = "broken", host = "", user = "test" },
      },
    })

    assert.are.equal(1, #result)
    assert.are.equal("ok", result[1].name)
    assert.is_true(#notifications >= 1)
  end)

  it("serializes connections in wrapped format", function()
    local content = config.serialize({
      { type = "ssh", name = "srv", host = "127.0.0.1", user = "test", port = 22 },
    })

    assert.matches("connections", content)
    assert.matches("srv", content)
  end)

  it("filters connections by type", function()
    local connections = {
      { name = "SSH Test", type = "ssh" },
      { name = "Serial Test", type = "serial" },
      { name = "Other", type = "unknown" },
    }

    local result = config.filter_by_type(connections, "ssh")

    assert.are.equal(1, #result)
    assert.are.equal("SSH Test", result[1].name)
  end)
end)
