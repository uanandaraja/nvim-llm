local M = {}
local curl = require("plenary.curl")
local config = require("nvim-llm.config")

function M.send_chat_request(messages, on_chunk, on_error)
	local accumulated_content = ""

	local handle_chunk = vim.schedule_wrap(function(chunk)
		if chunk:match("^: OPENROUTER PROCESSING") then
			return
		end
		local json_str = chunk:gsub("^data: ", "")
		if json_str == "" or json_str == "[DONE]" then
			return
		end

		local ok, decoded = pcall(vim.fn.json_decode, json_str)
		if not ok then
			return
		end

		if decoded.choices and #decoded.choices > 0 then
			local choice = decoded.choices[1]
			if choice.delta and choice.delta.content then
				accumulated_content = accumulated_content .. choice.delta.content
				on_chunk(accumulated_content)
			end
		end
	end)

	curl.post("https://openrouter.ai/api/v1/chat/completions", {
		headers = {
			Authorization = "Bearer " .. config.config.api_key,
			["HTTP-Referer"] = config.config.site_url,
			["X-Title"] = config.config.site_name,
			["Content-Type"] = "application/json",
		},
		body = vim.fn.json_encode({
			model = config.config.default_model,
			messages = messages,
			stream = true,
		}),
		stream = function(_, chunk)
			handle_chunk(chunk)
		end,
		on_error = vim.schedule_wrap(function(error)
			on_error(error)
		end),
	})
end

return M
