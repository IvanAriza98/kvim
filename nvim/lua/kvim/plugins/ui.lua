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
    "stevearc/dressing.nvim",
    event = "VeryLazy",
    opts = {
      input = {
        enabled = true,
        default_prompt = "❯ ",
        border = "rounded",
        relative = "editor",
        prefer_width = 52,
        width = nil,
        max_width = { 100, 0.6 },
        min_width = { 40, 0.3 },
        win_options = {
          winblend = 0,
          winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
        },
      },
      select = {
        enabled = true,
        backend = { "telescope", "builtin" },
        builtin = {
          relative = "editor",
          border = "rounded",
          winblend = 0,
          win_options = {
            winhighlight = "Normal:NormalFloat,FloatBorder:FloatBorder",
          },
          width = 0.42,
          min_width = 40,
          max_width = 84,
        },
      },
    },
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
    opts = function()
      local palette_width = math.max(52, math.min(84, math.floor(vim.o.columns * 0.42)))

      return {
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
            input = {
              view = "cmdline",
              icon = "",
            },
          },
        },

        views = {
          cmdline_popup = {
            relative = "editor",
            position = {
              row = "50%",
              col = "50%",
            },
            size = {
              width = palette_width,
              height = "auto",
            },
            border = {
              style = "rounded",
              padding = { 0, 1 },
            },
            win_options = {
              winblend = 0,
              winhighlight = {
                Normal = "NormalFloat",
                FloatBorder = "FloatBorder",
              },
            },
          },
          popupmenu = {
            relative = "editor",
            position = {
              row = "53%",
              col = "50%",
            },
            size = {
              width = palette_width,
              height = 8,
            },
            border = {
              style = "rounded",
              padding = { 0, 1 },
            },
            win_options = {
              winblend = 0,
              winhighlight = {
                Normal = "NormalFloat",
                FloatBorder = "FloatBorder",
              },
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
      }
    end,
  },
}
