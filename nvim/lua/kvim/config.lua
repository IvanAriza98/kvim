-- lua/kvim/config.lua

local M = {}

local defaults = {
	ui = {
		enabled = true,
        editor = {
			numbers = {
				enabled = true,
				mode = "hybrid", -- "absolute", "relative", "hybrid", "none"
			},

			indentation = {
				tabstop = 4,
				shiftwidth = 4,
				softtabstop = 4,
				expandtab = true,
				smartindent = true,
				autoindent = true
			},

			cursorline = true,
			signcolumn = "yes",
			wrap = false,
			scrolloff = 8,
			sidescrolloff = 8,
			termguicolors = true,
	    },
        explorer = {
            enabled = true,

            sidebar = {
                enabled = true,
                provider = "neo-tree",
                width = 32,
                position = "left",
            },

            file_manager = {
                enabled = true,
                provider = "yazi",

                yazi = {
                    open_for_directories = true,
                    floating_window_scaling_factor = 0.9,
                    keymaps_help = "<f1>",
                },
            },

            telescope = {
              enabled = true,

              defaults = {
                prompt_prefix = "  ",
                selection_caret = " ",
                path_display = { "smart" },
                layout_strategy = "horizontal",

                layout_config = {
                  horizontal = {
                    preview_width = 0.55,
                  },
                  width = 0.87,
                  height = 0.80,
                },
              },
            },
        },

        theme = {
            enabled = true,
            name = "catppuccin",
            style = "mocha", -- mocha, macchiato, frappe, latte
        },

        neovide = {
            enabled = true,
            scale_factor = 1.0,
            transparency = 1.0,
            cursor_animation_length = 0.08,
            scroll_animation_length = 0.15,
            hide_mouse_when_typing = true,
            remember_window_size = true,
            fullscreen = false,
        },
	},

	keymaps = {
		enabled = true,

		opts = {
			noremap = true,
			silent = true,
		},

		presets = {
			personal = true,
			core = true,
			ui = true,
            terminal = true,
		},

		mappings = {
			personal = {
				save = "s",
				close_buffer = "qq",
				quit_all = "qe",
				clear_search = "<Esc>",
                delete_all_lines = "da",
			},

			core = {
				modules = "<leader>km",
				action = "<leader>ka",
			},

            ui = {
                -- neo-tree
                explorer_toggle = "<leader>e",
                explorer_focus  = "<leader>E",
                explorer_reveal = "<leader>fe",
                explorer_close  = "<leader>ec",
                explorer_git_status = "<leader>eg",
                explorer_buffers    = "<leader>eb",
                -- yazi explorer
                yazi = "<leader>y",
                yazi_cwd = "<leader>Y",
                -- telescope
                find_files = "<leader>ff",
                live_grep = "<leader>fg",
                find_buffers = "<leader>fb",
                recent_files = "<leader>fr",
                help_tags = "<leader>fh",
            },

            terminal = {
                exit_terminal   = "<C-x>",
                open_right      = "<C-t>l",
                open_left       = "<C-t>h",
                open_top        = "<C-t>k",
                open_bottom     = "<C-t>j",

            },
		},
	},

    lsp = {
        enabled = true,

        servers = {
            "lua_ls",
            "clangd",
            "pyright",
            "ts_ls",
            "bashls",
            "jsonls",
            "yamlls",
        },
    },

	terminal = {
		height = 12,
		position = "bottom",
	},

    modules = {
        workspaces = {
            enabled = true,
            prefix = "<leader>w",
        },

        git = {
            enabled = true,
            prefix = "<leader>g",
        },

        svn = {
            enabled = true,
        },

        connections = {
            enabled = true,
            prefix = "<leader>c",
        },
    },
}

local options = vim.deepcopy(defaults)

function M.setup(opts)
	options = vim.tbl_deep_extend("force", defaults, opts or {})
end

function M.get()
	return options
end

return M
