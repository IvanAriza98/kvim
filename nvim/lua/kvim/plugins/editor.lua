return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },

    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
            "bash",
            "regex",
            "lua",
            "vim",
            "vimdoc",
            "c",
            "cpp",
            "python",
            "json",
            "yaml",
            "markdown",
            "markdown_inline",
        },

        highlight = {
            enable = true,
            disable = { "bash" },
        },

        indent = {
            enable = true,
            disable = { "bash" },
        },
      })
    end,
    },
    {
        {
            "kevinhwang91/nvim-ufo",
            event = { "BufReadPost", "BufNewFile" },
            dependencies = {
                "kevinhwang91/promise-async",
            },

            init = function()
                vim.o.foldcolumn = "0"
                vim.o.foldlevel = 99
                vim.o.foldlevelstart = 99
                vim.o.foldenable = true
                -- Evitamos que el nvim-ufo uso su foldtext propio
                vim.o.foldtext = ""
            end,

            opts = {
                provider_selector = function(_, filetype, _)
                    if filetype == "bash" or filetype == "sh" then
                        return { "indent" }
                    end

                    return { "treesitter", "indent" }
                end,
            },

            config = function(_, opts)
                local ufo = require("ufo")

                ufo.setup(opts)

                vim.keymap.set("n", "zR", ufo.openAllFolds, {
                    desc = "Open all folds",
                })

                vim.keymap.set("n", "zM", ufo.closeAllFolds, {
                    desc = "Close all folds",
                })

                vim.keymap.set("n", "zr", ufo.openFoldsExceptKinds, {
                    desc = "Open folds except selected kinds",
                })

                vim.keymap.set("n", "zm", ufo.closeFoldsWith, {
                    desc = "Close folds with level",
                })

                vim.keymap.set("n", "K", function()
                    local winid = ufo.peekFoldedLinesUnderCursor()
                    if not winid then
                        vim.lsp.buf.hover()
                    end
                end, {
                    desc = "Peek fold or LSP hover",
                })
            end,
        },
    },
    {
        {
            "shellRaining/hlchunk.nvim",
            event = { "BufReadPre", "BufNewFile" },

            config = function()
                require("hlchunk").setup({
                    chunk = {
                        enable = true,
                        notify = false,
                        priority = 15,
                    },

                    indent = {
                        enable = true,
                        notify = false,
                        priority = 10,
                    },

                    line_num = {
                        enable = false,
                    },

                    blank = {
                        enable = false,
                    },
                })
            end,
        },
    },
    {
        {
            "m4xshen/smartcolumn.nvim",
            event = { "BufReadPost", "BufNewFile", "InsertEnter" },

            opts = {
                colorcolumn = "100",

                disabled_filetypes = {
                    "help",
                    "text",
                    "markdown",
                    "dashboard",
                    "lazy",
                    "mason",
                    "neo-tree",
                    "NvimTree",
                    "terminal",
                    "toggleterm",
                    "Trouble",
                    "alpha",
                    "starter",
                    "checkhealth",
                    "lspinfo",
                    "snacks_dashboard",
                    "kvim-term",
                    "kvim-term-sessions",
                },

                scope = "file",

                custom_colorcolumn = function()
                    local programming_filetypes = {
                        python = true,
                        lua = true,
                        c = true,
                        cpp = true,
                        sh = true,
                        bash = true,
                        javascript = true,
                        typescript = true,
                        javascriptreact = true,
                        typescriptreact = true,
                        go = true,
                        rust = true,
                        java = true,
                        json = true,
                        yaml = true,
                        toml = true,
                    }

                    local ft = vim.bo.filetype
                    if programming_filetypes[ft] then
                        return "100"
                    end

                    if ft == "gitcommit" then
                        return "72"
                    end

                    return "9999"
                end,

                editorconfig = true,
            },
        },
    },

    {
        "mg979/vim-visual-multi",
        branch = "master",
        event = "VeryLazy",
        init = function()
            vim.g.VM_maps = {
                ["Add Cursor Down"] = "<C-j>",
                ["Add Cursor Up"] = "<C-k>",
            }
        end,
    },

    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",

        opts = {
            check_ts = true,

            disable_filetype = {
                "TelescopePrompt",
                "spectre_panel",
                "vim",
            },

            fast_wrap = {},
        },

        config = function(_, opts)
            require("nvim-autopairs").setup(opts)
        end,
    },
}
