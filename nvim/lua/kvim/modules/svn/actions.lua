local M = {}

local function executable_exists(cmd)
  return vim.fn.executable(cmd) == 1
end

local function open_floating_terminal(cmd, title)
  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.85)

  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local buf = vim.api.nvim_create_buf(false, true)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " " .. title .. " ",
    title_pos = "center",
  })

  vim.bo[buf].bufhidden = "wipe"

  vim.fn.termopen(cmd, {
    on_exit = function()
      -- Solo cerramos automáticamente si es lazysvn.
      -- Para svn info/status interesa dejar visible la salida.
      if cmd == "lazysvn" and vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end,
  })

  vim.cmd("startinsert")

  vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], {
    buffer = buf,
    silent = true,
  })

  vim.keymap.set("n", "q", function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
  end, {
    buffer = buf,
    silent = true,
  })

  return buf, win
end

function M.is_svn_working_copy()
  local result = vim.system({ "svn", "info" }, { text = true }):wait()
  return result.code == 0
end

function M.check_requirements()
  if not executable_exists("svn") then
    vim.notify("KVIM SVN: svn not installed", vim.log.levels.ERROR)
    return false
  end

  if not M.is_svn_working_copy() then
    vim.notify("KVIM SVN: directory is not a working copy SVN", vim.log.levels.WARN)
    return false
  end

  return true
end

function M.check_lazysvn_requirements()
  if not M.check_requirements() then
    return false
  end

  if not executable_exists("lazysvn") then
    vim.notify("KVIM SVN: lazysvn not installed", vim.log.levels.ERROR)
    return false
  end

  return true
end

function M.open_lazysvn()
  if not M.check_lazysvn_requirements() then
    return
  end

  open_floating_terminal("lazysvn", "LazySVN")
end

function M.open_svn_info()
  if not M.check_requirements() then
    return
  end

  open_floating_terminal("svn info", "SVN Info")
end

function M.open_svn_status()
  if not M.check_requirements() then
    return
  end

  open_floating_terminal("svn status", "SVN Status")
end

return M
