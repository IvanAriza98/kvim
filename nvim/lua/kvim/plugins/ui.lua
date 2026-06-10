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
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      local ok, wk = pcall(require, "which-key")
      if not ok then
        return
      end

      wk.setup({})
      wk.add({
        { "<leader>c", group = "Connections" },
        { "<leader>ck", group = "Connections SSH Keys" },
        { "<leader>w", group = "Workspaces" },
      })
    end,
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
    enabled = function()
      return not vim.g.neovide
    end,
    event = "VeryLazy",
    opts = {
      stiffness = 0.8,
      trailing_stiffness = 0.5,
      distance_stop_animating = 0.5,
      hide_target_hack = true,
    },
  },
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
    opts = {
      cmdline = {
        enabled = true,
        view = "cmdline_popup",
        format = {
          cmdline = {
            pattern = "^:",
            icon = "",
            lang = "vim",
          },
          search_down = {
            pattern = "^/",
            icon = " ",
            lang = "regex",
          },
          search_up = {
            pattern = "^%?",
            icon = " ",
            lang = "regex",
          },
          filter = {
            pattern = "^:%s*!",
            icon = "$",
            lang = "bash",
          },
          lua = {
            pattern = "^:%s*lua%s+",
            icon = "",
            lang = "lua",
          },
        },
      },

      views = {
        cmdline_popup = {
          position = {
            row = "50%",
            col = "50%",
          },
          size = {
            width = 60,
            height = "auto",
          },
          border = {
            style = "rounded",
          },
        },
      },

      messages = {
        enabled = true,
      },

      popupmenu = {
        enabled = true,
      },

      notify = {
        enabled = true,
      },

      presets = {
        bottom_search = false,
        command_palette = true,
        long_message_to_split = true,
        inc_rename = false,
        lsp_doc_border = true,
      },
    },
  },
}
