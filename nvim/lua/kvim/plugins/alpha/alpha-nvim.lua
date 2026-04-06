  return {
    "goolord/alpha-nvim",
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    lazy = false,
    config = function()
	    require("kvim.plugins.alpha.alpha-config")
    end,
  }
