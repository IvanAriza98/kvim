local M = {}

function M.setup(opts)
  opts = opts or {}

  local actions = require("kvim.modules.svn.actions")

  vim.api.nvim_create_user_command("KvimLazySvn", function()
    actions.open_lazysvn()
  end, {
    desc = "Open LazySVN",
  })

  vim.api.nvim_create_user_command("KvimSvnInfo", function()
    actions.open_svn_info()
  end, {
    desc = "Show SVN info",
  })

  vim.api.nvim_create_user_command("KvimSvnStatus", function()
    actions.open_svn_status()
  end, {
    desc = "Show SVN status",
  })
end

return M
