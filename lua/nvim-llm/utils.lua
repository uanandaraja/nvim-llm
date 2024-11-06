local M = {}
local config = require("nvim-llm.config")
local curl = require("plenary.curl")

function M.get_buffer_content(filepath)
	local bufnr = vim.fn.bufnr(filepath)

	if bufnr ~= -1 then
		return table.concat(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false), "\n")
	end

	local lines = vim.fn.readfile(filepath)
	if lines then
		return table.concat(lines, "\n")
	end

	return nil
end

function M.get_url_content(url)
	if not url:match("^https?://") then
		url = "https://" .. url
	end

	local res = curl.get("https://r.jina.ai/" .. url, {
		headers = {
			Authorization = "Bearer jina_dd21154a3e894eb68f03f8f9edf1f9bc7iNfgNdB_gS4RrcsXmnf7XE9kQdD",
			Accept = "text/plain",
		},
	})

	if res.status == 200 then
		return res.body
	end

	return nil, "HTTP error: " .. tostring(res.status)
end

return M
