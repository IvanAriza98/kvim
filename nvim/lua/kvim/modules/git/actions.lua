local M = {}

M.open = {
  callback = function()
    vim.cmd("LazyGit")
  end,
}

M.open_current_file = {
  callback = function()
    vim.cmd("LazyGitCurrentFile")
  end,
}

M.config = {
  callback = function()
    vim.cmd("LazyGitConfig")
  end,
}

return M
