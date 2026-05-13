local test_dir = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h")
local repo_root = vim.fn.fnamemodify(test_dir, ":h")
local nvim_dir = repo_root .. "/nvim"

package.path = nvim_dir .. "/lua/?.lua;"
  .. nvim_dir .. "/lua/?/init.lua;"
  .. nvim_dir .. "/lua/?/?.lua;"
  .. package.path

local plenary_path = vim.fn.stdpath("data") .. "/lazy/plenary.nvim"

if vim.fn.isdirectory(plenary_path) == 0 then
  error("plenary.nvim not found at: " .. plenary_path)
end

vim.opt.runtimepath:prepend(plenary_path)

require("plenary.busted")
