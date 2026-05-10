-- lua/kvim/core/terminal.lua

local M = {}

function M.setup_highlights()
  vim.api.nvim_set_hl(0, "KvimTerminalNormal", {
    bg = "#111111",
  })

  vim.api.nvim_set_hl(0, "KvimTerminalSignColumn", {
    bg = "#111111",
  })

  vim.api.nvim_set_hl(0, "KvimTerminalStatusLine", {
    fg = "#fab387",
    bg = "#181825",
    bold = true,
  })

  vim.api.nvim_set_hl(0, "KvimTerminalStatusLineNC", {
    fg = "#6c7086",
    bg = "#111111",
  })

  vim.api.nvim_set_hl(0, "KvimTerminalWinSeparator", {
    fg = "#fab387",
    bg = "#111111",
  })

  vim.api.nvim_set_hl(0, "KvimTerminalCursor", {
    fg = "#111111",
    bg = "#fab387",
  })
end

function M.apply_style()
  vim.opt_local.winhighlight = table.concat({
    "Normal:KvimTerminalNormal",
    "NormalNC:KvimTerminalNormal",
    "SignColumn:KvimTerminalSignColumn",
    "EndOfBuffer:KvimTerminalNormal",
    "StatusLine:KvimTerminalStatusLine",
    "StatusLineNC:KvimTerminalStatusLineNC",
    "WinSeparator:KvimTerminalWinSeparator",
    "TermCursor:KvimTerminalCursor",
  }, ",")

  vim.opt_local.number = false
  vim.opt_local.relativenumber = false
  vim.opt_local.signcolumn = "yes:1"
  vim.opt_local.foldcolumn = "0"
end

function M.open(position)
  if position == "right" then
    vim.cmd("rightbelow vsplit")
  elseif position == "left" then
    vim.cmd("leftabove vsplit")
  elseif position == "top" then
    vim.cmd("leftabove split")
  elseif position == "bottom" then
    vim.cmd("botright split")
  else
    vim.cmd("botright split")
  end

  vim.cmd("terminal")
  M.apply_style()
  vim.cmd("startinsert")
end

function M.setup()
  M.setup_highlights()
end

return M
