local M = {}

function M.setup()
  local actions = require("kvim.modules.git.actions")

  vim.api.nvim_create_user_command("KvimGit", function()
    actions.open()
  end, {
    desc = "Open LazyGit",
  })

  vim.api.nvim_create_user_command("KvimGitFile", function()
    actions.open_current_file()
  end, {
    desc = "Open LazyGit for current file",
  })

  vim.api.nvim_create_user_command("KvimGitConfig", function()
    actions.config()
  end, {
    desc = "Open LazyGit config",
  })
end

return M
