return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
  },

  {
    "nvim-lualine/lualine.nvim",
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
  },

  {
    "rcarriga/nvim-notify",
    event = "VeryLazy",
    config = function()
      local ok, notify = pcall(require, "notify")
      if not ok then
        return
      end

      notify.setup({
        timeout = 3000,
        render = "default",
        stages = "fade_in_slide_out",
      })

      vim.notify = notify
    end,
  },

  {
    "sphamba/smear-cursor.nvim",
    event = "VeryLazy",
    opts = {
      stiffness = 0.8,
      trailing_stiffness = 0.5,
      distance_stop_animating = 0.5,
      hide_target_hack = true,
    },
  },
}
