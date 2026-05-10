local M = {}

function M.setup()
	vim.api.nvim_create_autocmd("LspAttach", {
		group = vim.api.nvim_create_augroup("KvimLspKeymaps", { clear = true }),

		callback = function(event)
			local opts = {
				buffer = event.buf,
				silent = true,
			}

			vim.keymap.set(
				"n",
				"gd",
				vim.lsp.buf.definition,
				vim.tbl_extend("force", opts, {
					desc = "LSP: Go to definition",
				})
			)

			vim.keymap.set(
				"n",
				"gD",
				vim.lsp.buf.declaration,
				vim.tbl_extend("force", opts, {
					desc = "LSP: Go to declaration",
				})
			)

			vim.keymap.set(
				"n",
				"gr",
				vim.lsp.buf.references,
				vim.tbl_extend("force", opts, {
					desc = "LSP: References",
				})
			)

			vim.keymap.set(
				"n",
				"gi",
				vim.lsp.buf.implementation,
				vim.tbl_extend("force", opts, {
					desc = "LSP: Implementation",
				})
			)

			vim.keymap.set(
				"n",
				"K",
				vim.lsp.buf.hover,
				vim.tbl_extend("force", opts, {
					desc = "LSP: Hover",
				})
			)

			vim.keymap.set(
				"n",
				"<leader>rn",
				vim.lsp.buf.rename,
				vim.tbl_extend("force", opts, {
					desc = "LSP: Rename",
				})
			)

			vim.keymap.set(
				{ "n", "v" },
				"<leader>ca",
				vim.lsp.buf.code_action,
				vim.tbl_extend("force", opts, {
					desc = "LSP: Code action",
				})
			)

			vim.keymap.set(
				"n",
				"<leader>lf",
				function()
					vim.lsp.buf.format({
						async = true,
					})
				end,
				vim.tbl_extend("force", opts, {
					desc = "LSP: Format buffer",
				})
			)

			vim.keymap.set(
				"n",
				"<leader>ld",
				vim.diagnostic.open_float,
				vim.tbl_extend("force", opts, {
					desc = "LSP: Line diagnostics",
				})
			)

			vim.keymap.set(
				"n",
				"[d",
				function()
					vim.diagnostic.jump({ count = -1, float = true })
				end,
				vim.tbl_extend("force", opts, {
					desc = "LSP: Previous diagnostic",
				})
			)

			vim.keymap.set(
				"n",
				"]d",
				function()
					vim.diagnostic.jump({ count = -1, float = true })
				end,
				vim.tbl_extend("force", opts, {
					desc = "LSP: Next diagnostic",
				})
			)
		end,
	})
end

return M
