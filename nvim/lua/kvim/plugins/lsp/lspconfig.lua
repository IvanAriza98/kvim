-- LSP Config: Language Server Protocol para autocompletado, diagnóstico, etc.
-- Proporciona funcionalidades de IDE (ir a definición, rename, errores, etc.)
return {
  "neovim/nvim-lspconfig",
  event = { "BufReadPre", "BufNewFile" }, -- Se activa al abrir un archivo
  dependencies = {
    "hrsh7th/cmp-nvim-lsp",              -- Fuente LSP para nvim-cmp
    { "antosha417/nvim-lsp-file-operations", config = true }, -- Operaciones de archivo con LSP
    { "folke/neodev.nvim", opts = {} },  -- Configuración LSP para Neovim (desarrollo de plugins)
  },
  config = function()
    local lspconfig = require("lspconfig")
    local mason_lspconfig = require("mason-lspconfig")
    local cmp_nvim_lsp = require("cmp_nvim_lsp")

    local keymap = vim.keymap -- Acceso directo a vim.keymap

    -- Atajos de teclado LSP (se aplican por buffer)
    vim.api.nvim_create_autocmd("LspAttach", {
      group = vim.api.nvim_create_augroup("UserLspConfig", {}),
      callback = function(ev)
        local opts = { buffer = ev.buf, silent = true } -- Opciones: buffer actual, sin mostrar comandos

        -- gR = Mostrar referencias (where this symbol is used)
        opts.desc = "Show LSP references"
        keymap.set("n", "gR", "<cmd>Telescope lsp_references<CR>", opts)

        -- gD = Ir a declaración
        opts.desc = "Go to declaration"
        keymap.set("n", "gD", vim.lsp.buf.declaration, opts)

        -- gd = Mostrar definiciones (where symbol is defined)
        opts.desc = "Show LSP definitions"
        keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<CR>", opts)

        -- gi = Mostrar implementaciones
        opts.desc = "Show LSP implementations"
        keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<CR>", opts)

        -- gt = Mostrar tipos (type definitions)
        opts.desc = "Show LSP type definitions"
        keymap.set("n", "gt", "<cmd>Telescope lsp_type_definitions<CR>", opts)

        -- <Leader>ca = Acciones de código (quick fixes, refactors)
        opts.desc = "See available code actions"
        keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)

        -- <Leader>rn = Renombrar símbolo (refactor)
        opts.desc = "Smart rename"
        keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

        -- <Leader>D = Ver diagnósticos del archivo actual
        opts.desc = "Show buffer diagnostics"
        keymap.set("n", "<leader>D", "<cmd>Telescope diagnostics bufnr=0<CR>", opts)

        -- <Leader>d = Ver diagnóstico de la línea actual
        opts.desc = "Show line diagnostics"
        keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)

        -- [d / ]d = Ir al error anterior/siguiente
        opts.desc = "Go to previous diagnostic"
        keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)

        opts.desc = "Go to next diagnostic"
        keymap.set("n", "]d", vim.diagnostic.goto_next, opts)

        -- K = Mostrar documentación del símbolo bajo cursor
        opts.desc = "Show documentation for what is under cursor"
        keymap.set("n", "K", vim.lsp.buf.hover, opts)

        -- <Leader>rs = Reiniciar LSP (útil si falla)
        opts.desc = "Restart LSP"
        keymap.set("n", "<leader>rs", ":LspRestart<CR>", opts)
      end,
    })

    -- Configuración de iconos de diagnóstico en la gutter
    vim.diagnostic.config({ 
        signs = {
            text = {
                [vim.diagnostic.severity.ERROR]= "", -- Error
                [vim.diagnostic.severity.WARN] = "", -- Warning
                [vim.diagnostic.severity.INFO] = "", -- Info
                [vim.diagnostic.severity.HINT] = "󰠠", -- Hint
            },
        },
        update_in_insert = false,    -- No actualizar diagnósticos mientras se escribe
        float = { debounce = 100 },  -- Debounce para ventana flotante de diagnóstico
    })

    -- Configuración de Mason-LSPConfig para instalar servers automáticamente
    mason_lspconfig.setup({
        automatic_installation = true, -- Instala servers LSP definidos en Mason
        handlers = {
            -- Configura cada servidor LSP con opciones por defecto
            function(server_name)
            require("lspconfig")[server_name].setup({})
            end,
        },
    })
  end,
}
