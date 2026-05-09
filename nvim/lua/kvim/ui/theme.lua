-- lua/kvim/ui/theme.lua

local M = {}

local function setup_tokyonight(theme)
  local ok, tokyonight = pcall(require, "tokyonight")

  if not ok then
    vim.notify("Kvim: tokyonight.nvim not found", vim.log.levels.WARN)
    return
  end

  tokyonight.setup({
    style = theme.style or "moon",
    transparent = theme.transparent or false,
  })

  vim.cmd.colorscheme("tokyonight")
end


local function setup_catppuccin(theme)
  local ok, catppuccin = pcall(require, "catppuccin")

  if not ok then
    vim.notify("Kvim: catppuccin.nvim not found", vim.log.levels.WARN)
    return
  end

  catppuccin.setup({
    flavour = theme.style or "mocha",
    transparent_background = theme.transparent or false,

    no_italic = false,
    no_bold = false,
    no_underline = false,

    styles = {
      comments = { "italic" },
      conditionals = { },
      loops = { },
      functions = { "bold" },
      keywords = { "bold" },
      strings = {},
      variables = { "italic" },
      numbers = {},
      booleans = { "bold" },
      properties = {},
      types = { "italic" },
      operators = {},
    },

    integrations = {
      treesitter = true,
      native_lsp = {
        enabled = true,
      },
      telescope = true,
      neo_tree = true,
      lualine = true,
      bufferline = true,
      markdown = true,
    },
  })

  vim.cmd.colorscheme("catppuccin")
end

function M.setup()
  local config = require("kvim.config").get()
  local theme = config.ui.theme or {}

  if not theme.enabled then
    return
  end

  if theme.name == "tokyonight" then
    setup_tokyonight(theme)
    return
  end

  if theme.name == "catppuccin" then
    setup_catppuccin(theme)
    return
  end

  vim.notify("Kvim: unknown theme " .. tostring(theme.name), vim.log.levels.WARN)
end

return M
