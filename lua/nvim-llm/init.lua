local M = {}

-- Import submodules
local core = require("nvim-llm.core")
local config = require("nvim-llm.config")
local ui = require("nvim-llm.ui")
local api = require("nvim-llm.api")
local utils = require("nvim-llm.utils")

function M.setup(opts)
	opts = opts or {}
	config.setup(opts)
	ui.setup()

	if not M.load_api_key() then
		core.prompt_api_key()
	end

	-- Create user commands
	vim.api.nvim_create_user_command("LLM", function()
		core.open_llm_chat()
	end, {})

	-- Global keymappings
	vim.keymap.set("n", "<leader>lo", "<cmd>LLM<CR>", { desc = "Open LLM Chat" })
	vim.keymap.set("n", "<leader>lp", function()
		ui.configure_system_prompt()
	end, { desc = "Configure System Prompt" })

	-- Return public API
	return {
		submit_prompt = core.submit_prompt,
		add_file_reference = core.add_file_reference,
		show_file_picker = ui.show_file_picker,
		select_model = ui.select_model,
		configure_system_prompt = ui.configure_system_prompt,
	}
end

return M
