return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
        local configs = require("nvim-treesitter.configs")
        configs.setup({
	    modules = {},
            auto_install = true,
	    ignore_install = {},
	    ensure_installed = {
                "c", "lua", "vim", "vimdoc", "query", "elixir", "heex", "javascript", "html", "cpp", "python"
            },
            sync_install = false,
            highlight = { enable = true },
            indent = { enable = true },
        })
    end
}

