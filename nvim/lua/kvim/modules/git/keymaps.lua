local M = {}

function M.setup(opts)
  opts = opts or {}

  local kvim = require("kvim")

  vim.keymap.set("n", "<leader>g", function()
    kvim.run_action("git", "open")
  end, {
    desc = "Git: Open LazyGit",
  })

  vim.keymap.set("n", "<leader>f", function()
    kvim.run_action("git", "open_current_file")
  end, {
    desc = "Git: Current file",
  })

  vim.keymap.set("n", "<leader>c", function()
    kvim.run_action("git", "config")
  end, {
    desc = "Git: LazyGit config",
  })
end

return M
