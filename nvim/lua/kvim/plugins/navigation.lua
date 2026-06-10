return {
    {
        "nvim-neo-tree/neo-tree.nvim",
        branch = "v3.x",
        dependencies = {
            "MunifTanjim/nui.nvim",
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons",
        },
        opts = {
            close_if_last_window = false,
            enable_git_status = true,
            git_status_async = true,
            git_status_scope_to_path = true,
            filesystem = {
                async_directory_scan = "auto",
                scan_mode = "shallow",
                follow_current_file = {
                    enabled = false,
                    leave_dirs_open = false,
                },
                filtered_items = {
                    visible = false,
                    hide_dotfiles = true,
                    hide_gitignored = true,
                    hide_hidden = true,
                },
                use_libuv_file_watcher = false,
            },
            window = {
                width = 32,
                auto_expand_width = false,
            },
        },
    },

    {
        "mikavilpas/yazi.nvim",
        event = "VeryLazy",
        dependencies = {
            "folke/snacks.nvim",
        },
        opts = {},
    },

    {
        "nvim-telescope/telescope.nvim",
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        config = function()
            local config = require("kvim.config").get()
            local telescope_config = config.ui.telescope or {}

            if not telescope_config.enabled then
                return
            end

            require("telescope").setup({
                defaults = telescope_config.defaults or {},
            })
        end,
    },
}
