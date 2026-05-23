local M = {}

function M.setup()
    local signs = {
        [vim.diagnostic.severity.ERROR] = " ",
        [vim.diagnostic.severity.WARN] = " ",
        [vim.diagnostic.severity.INFO] = " ",
        [vim.diagnostic.severity.HINT] = "󰌵 ",
    }


  vim.diagnostic.config({
    virtual_text = {
      spacing = 4,
      prefix = "●",
    },

    -- signs = true,
    signs = {
        text = signs,
    },

    underline = true,
    update_in_insert = false,
    severity_sort = true,

    float = {
      border = "rounded",
      source = "always",
    },
  })
  end

return M
