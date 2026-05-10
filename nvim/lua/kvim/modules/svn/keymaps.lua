local M = {}

function M.setup(opts)
  opts = opts or {}

  local prefix = opts.prefix or "<leader>s"

  vim.keymap.set("n", prefix .. "v", "<cmd>KvimLazySvn<CR>", {
    desc = "SVN: Open LazySVN",
    silent = true,
  })

  vim.keymap.set("n", prefix .. "i", "<cmd>KvimSvnInfo<CR>", {
    desc = "SVN: Info",
    silent = true,
  })

  vim.keymap.set("n", prefix .. "s", "<cmd>KvimSvnStatus<CR>", {
    desc = "SVN: Status",
    silent = true,
  })
end

return M
