return {
	-- The Java LSP plugin
	{
		"mfussenegger/nvim-jdtls",
	},

	-- Async build task runner for Maven/Gradle
	{
		"stevearc/overseer.nvim",
		opts = {},
		keys = {
			{ "<leader>mr", "<cmd>OverseerRun<cr>",    desc = "Run Build Task" },
			{ "<leader>mt", "<cmd>OverseerToggle<cr>", desc = "Toggle Task List" },
		},
	},
}
