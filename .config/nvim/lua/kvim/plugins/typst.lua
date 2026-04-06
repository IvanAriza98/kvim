return {
  'kaarmu/typst.vim',
  ft = 'typst',
  lazy = false,

  config = function()
    local function TypstWatch()
        -- initial compile
        vim.fn.system("typst compile " .. vim.fn.expand("%:p"))

        -- open zathura if not already running
        vim.cmd("silent !zathura --fork " .. vim.fn.expand("%:p:r") .. ".pdf &")

        -- open watch terminal
        -- vim.cmd("vsp")
        -- vim.cmd("vertical resize 20")
        vim.cmd("botright split")
        vim.cmd("resize 10")
        vim.cmd("terminal typst watch " .. vim.fn.expand("%:"))
        vim.cmd("norm! <C-w>h")
    end

    vim.keymap.set("n", "<leader>tw", TypstWatch, { silent = true })
  end
}
