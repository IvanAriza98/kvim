-- typst.vim: Soporte para Typst (lenguaje de composición tipográfica)
-- Alternativa moderna a LaTeX para documentos científicos/técnicos
return {
  'kaarmu/typst.vim',
  ft = 'typst',  -- Solo se carga para archivos .typ (Tipo de archivo Typst)
  lazy = true,   -- Carga perezosa

  config = function()
    -- Función que compila Typst y abre visor PDF con watch mode
    local function TypstWatch()
        -- Compila el documento actual a PDF
        vim.fn.system("typst compile " .. vim.fn.expand("%:p"))
        -- Abre el PDF en Zathura (visor de PDF) en segundo plano
        vim.cmd("silent !zathura --fork " .. vim.fn.expand("%:p:r") .. ".pdf &")
        -- Crea terminal en panel inferior para watch mode
        vim.cmd("botright split")     -- Panel en la parte inferior
        vim.cmd("resize 10")          -- Altura del panel (10 líneas)
        vim.cmd("terminal typst watch " .. vim.fn.expand("%:")) -- Watch mode en terminal
        vim.cmd("norm! <C-w>h")       -- Vuelve al buffer anterior
    end

    -- <Leader>tw = Compila y abre Typst con watch mode
    vim.keymap.set("n", "<leader>tw", TypstWatch, { silent = true })
  end
}
