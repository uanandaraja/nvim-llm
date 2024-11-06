local M = {}
local curl = require("plenary.curl")

-- Get content from a buffer or file
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

-- Get content from a URL
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

-- Get visible buffers
function M.get_visible_buffers()
	local visible_buffers = {}
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		local name = vim.api.nvim_buf_get_name(buf)
		if name and name ~= "" then
			table.insert(visible_buffers, {
				bufnr = buf,
				name = name,
				text = vim.fn.fnamemodify(name, ":."),
			})
		end
	end
	return visible_buffers
end

-- Get all loaded buffers
function M.get_loaded_buffers()
	local buffers = {}
	for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(bufnr) then
			local name = vim.api.nvim_buf_get_name(bufnr)
			if name and name ~= "" then
				table.insert(buffers, {
					bufnr = bufnr,
					name = name,
					text = vim.fn.fnamemodify(name, ":."),
				})
			end
		end
	end
	return buffers
end

return M
