if vim.g.loaded_nvim_llm == 1 then
	return
end
vim.g.loaded_nvim_llm = 1

require("nvim-llm").setup()
