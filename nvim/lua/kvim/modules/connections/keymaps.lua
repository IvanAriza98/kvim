-- lua/kvim/modules/connections/keymaps.lua

local M = {}

local function map(mode, lhs, rhs, opts)
  if not lhs or lhs == "" then
    return
  end

  vim.keymap.set(mode, lhs, rhs, opts)
end

function M.setup(opts)
  opts = opts or {}

  local prefix = opts.prefix or "<leader>c"

  local keymap_opts = {
    silent = true,
    noremap = true,
  }

  map("n", prefix .. "c", "<cmd>KvimConnections<CR>", vim.tbl_extend("force", keymap_opts, {
    desc = "Connections: Open picker",
  }))

  map("n", prefix .. "s", "<cmd>KvimSshConnections<CR>", vim.tbl_extend("force", keymap_opts, {
    desc = "Connections: SSH picker",
  }))

  map("n", prefix .. "u", "<cmd>KvimSerialConnections<CR>", vim.tbl_extend("force", keymap_opts, {
    desc = "Connections: Serial picker",
  }))

  map("n", prefix .. "r", "<cmd>KvimConnectionsReload<CR>", vim.tbl_extend("force", keymap_opts, {
    desc = "Connections: Reload config",
  }))

  map("n", prefix .. "kg", "<cmd>KvimConnectionsGenerateKey<CR>", vim.tbl_extend("force", keymap_opts, {
    desc = "Connections: Generate SSH key",
  }))

  map("n", prefix .. "ki", "<cmd>KvimConnectionsInstallKey<CR>", vim.tbl_extend("force", keymap_opts, {
    desc = "Connections: Install SSH key",
  }))

  map("n", prefix .. "ks", "<cmd>KvimConnectionsSetupSshKey<CR>", vim.tbl_extend("force", keymap_opts, {
    desc = "Connections: Setup SSH key",
  }))

  map("n", prefix .. "kt", "<cmd>KvimConnectionsTestSsh<CR>", vim.tbl_extend("force", keymap_opts, {
    desc = "Connections: Test SSH connection",
  }))
end

return M
