return {
  {
    "folke/snacks.nvim",
    priority = 1000,
    lazy = false,
    opts = {
      dashboard = {
        enabled = true,
        preset = {
          header = [[
██╗  ██╗██╗   ██╗██╗███╗   ███╗
██║ ██╔╝██║   ██║██║████╗ ████║
█████╔╝ ██║   ██║██║██╔████╔██║
██╔═██╗ ╚██╗ ██╔╝██║██║╚██╔╝██║
██║  ██╗ ╚████╔╝ ██║██║ ╚═╝ ██║
╚═╝  ╚═╝  ╚═══╝  ╚═╝╚═╝     ╚═╝
          ]],
          keys = {
            { icon = " ", key = "f", desc = "Find File", action = ":Telescope find_files" },
            { icon = "󰈞 ", key = "r", desc = "Recent Files", action = ":Telescope oldfiles" },
            { icon = "󰱼 ", key = "g", desc = "Live Grep", action = ":Telescope live_grep" },
            { icon = " ", key = "e", desc = "Explorer", action = ":Neotree toggle" },
            { icon = " ", key = "c", desc = "Config", action = ":e ~/.config/nvim/init.lua" },
            { icon = " ", key = "q", desc = "Quit", action = ":qa" },
          },
        },
      },
    },
  },
}
