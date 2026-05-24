return {
    {
        "stevearc/resession.nvim",
        config = function()
            local ok, resession = pcall(require, "resession")
            if not ok then
                vim.notify("KVIM Workspaces: resession.nvim no disponible", vim.log.levels.WARN)
                return
            end

            resession.setup({
                autosave = {
                    enabled = false,
                },
            })
        end,
    },
}
