local M = {}

M.config = {
	api_key = nil,
	models = {
		{
			name = "Claude 3.5 Sonnet New",
			id = "anthropic/claude-3.5-sonnet",
		},
		{
			name = "Claude 3.5 Sonnet Old",
			id = "anthropic/claude-3.5-sonnet-20240620",
		},
		{
			name = "Claude 3.5 Haiku",
			id = "anthropic/claude-3-5-haiku",
		},
		{
			name = "Hermes 3 405B",
			id = "nousresearch/hermes-3-llama-3.1-405b:free",
		},
		{
			name = "GPT-4o",
			id = "openai/gpt-4o",
		},
		{
			name = "Gemini Pro 1.5",
			id = "google/gemini-pro-1.5-exp",
		},
	},
	site_url = "nvim-llm-plugin",
	site_name = "nvim-llm",
	bufname = "LLM.md",
	default_model = "anthropic/claude-3.5-sonnet",
	system_prompt = nil,
}

function M.setup(opts)
	M.config = vim.tbl_deep_extend("force", M.config, opts)

	-- Load saved configuration logic from your original implementation
	local function load_saved_config()
		local config_file = vim.fn.stdpath("data") .. "/llm_config.json"
		if vim.fn.filereadable(config_file) == 1 then
			local content = vim.fn.readfile(config_file)
			local ok, data = pcall(vim.fn.json_decode, table.concat(content))
			if ok then
				return data.system_prompt, data.default_model
			end
		end
		return nil, nil
	end

	local saved_prompt, saved_model = load_saved_config()
	M.config.system_prompt = saved_prompt or M.config.system_prompt
	M.config.default_model = saved_model or M.config.default_model

	return M.config
end

function M.save_config(system_prompt, default_model)
	local config_file = vim.fn.stdpath("data") .. "/llm_config.json"
	local data = vim.fn.json_encode({
		system_prompt = system_prompt,
		default_model = default_model,
	})
	vim.fn.writefile({ data }, config_file)
end

return M
