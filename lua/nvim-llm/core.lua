local M = {}
local config = require("nvim-llm.config")
local ui = require("nvim-llm.ui")
local api = require("nvim-llm.api")
local utils = require("nvim-llm.utils")

local function create_or_get_buffer()
	local bufnr = vim.fn.bufnr(config.config.bufname)
	if bufnr == -1 then
		bufnr = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_name(bufnr, config.config.bufname)
		vim.api.nvim_buf_set_option(bufnr, "filetype", "markdown")
		vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")
		vim.api.nvim_buf_set_option(bufnr, "swapfile", false)

		-- Keymaps and buffer setup
		local function map(mode, lhs, rhs, opts)
			opts = opts or {}
			opts.buffer = bufnr
			vim.keymap.set(mode, lhs, rhs, opts)
		end

		map("n", "<leader>ls", M.submit_prompt, { desc = "Submit to LLM" })
		map("n", "<leader>lc", function()
			vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
		end, { desc = "Clear chat" })
		map("n", "<leader>lq", "<cmd>quit<CR>", { desc = "Quit chat" })
		map("n", "<leader>lf", ui.show_file_picker, { desc = "Add file reference" })
		map("n", "<leader>lb", function()
			M.add_file_reference(vim.fn.expand("%:p"))
		end, { desc = "Add current buffer" })
		map("n", "<leader>lm", ui.select_model, { desc = "Select Model" })
		map("n", "<leader>lu", function()
			local url = vim.fn.input({ prompt = "Enter URL: ", default = "" })
			if url ~= "" then
				M.add_url_reference(url)
			end
		end, { desc = "Add URL reference" })

		M.setup_session_autocmds(bufnr)
		M.load_last_session(bufnr)
	end
	return bufnr
end

function M.open_llm_chat()
	local function open()
		local bufnr = create_or_get_buffer()
		vim.cmd("botright vsplit")
		local win = vim.api.nvim_get_current_win()
		vim.api.nvim_win_set_buf(win, bufnr)
		vim.wo[win].wrap = true
		vim.wo[win].linebreak = true
		vim.wo[win].breakindent = true
		vim.cmd("stopinsert")
	end

	if not config.config.api_key then
		vim.notify("OpenRouter API key not found", "warn")
		M.prompt_api_key(open)
	else
		open()
	end
end

function M.submit_prompt()
	local bufnr = create_or_get_buffer()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local content = table.concat(lines, "\n")

	-- Process file/URL references (from original implementation)
	content = content:gsub(
		"```(%w+)\n// File: ([^\n]+) %((%d+) lines%)\n// Content hidden for brevity%. Full content will be sent to the API%.\n```",
		function(ext, filepath, line_count)
			local file_content = vim.api.nvim_buf_get_var(bufnr, "file_content_" .. vim.fn.fnamemodify(filepath, ":t"))
			return "```"
				.. ext
				.. "\n// File: "
				.. filepath
				.. " ("
				.. line_count
				.. " lines)\n"
				.. file_content
				.. "\n```"
		end
	)

	content = content:gsub("```html\n// URL: ([^\n]+) %((%d+) lines%)\n```", function(url, line_count)
		local url_content = vim.api.nvim_buf_get_var(bufnr, "url_content_" .. url)
		return "```html\n// URL: " .. url .. " (" .. line_count .. " lines)\n" .. url_content .. "\n```"
	end)

	if content:gsub("%s+", "") == "" then
		vim.notify("Cannot send empty prompt!", "error")
		return
	end

	M.update_buffer(bufnr, "Processing request...")

	local messages = {}
	if config.config.system_prompt then
		table.insert(messages, { role = "system", content = config.config.system_prompt })
	end
	table.insert(messages, { role = "user", content = content })

	api.send_chat_request(messages, function(accumulated_content)
		M.update_buffer(bufnr, accumulated_content)
	end, function(error)
		vim.notify("Request failed: " .. vim.inspect(error), "error")
		M.update_buffer(bufnr, "Error: Request failed\n" .. vim.inspect(error))
	end)
end

function M.update_buffer(bufnr, content)
	vim.schedule(function()
		if not vim.api.nvim_buf_is_valid(bufnr) then
			return
		end

		local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
		local cursor_pos = vim.api.nvim_win_get_cursor(0)
		local current_line = cursor_pos[1]

		local last_separator = -1
		local has_new_question = false

		for i = #lines, 1, -1 do
			if lines[i] == "---" then
				last_separator = i
				for j = current_line - 1, last_separator + 1, -1 do
					if j < #lines and lines[j] and lines[j]:match("%S") then
						has_new_question = true
						break
					end
				end
				break
			end
		end

		local content_lines = type(content) == "string" and vim.split(content, "\n", { plain = true }) or { content }

		if last_separator == -1 or has_new_question then
			if content == "Thinking..." or content == "Processing request..." then
				vim.api.nvim_buf_set_lines(bufnr, #lines, -1, false, { "", "---", content })
			else
				local thinking_line = -1
				for i = #lines, 1, -1 do
					if lines[i] == "Thinking..." or lines[i] == "Processing request..." then
						thinking_line = i
						break
					end
				end

				if thinking_line ~= -1 then
					vim.api.nvim_buf_set_lines(bufnr, thinking_line, thinking_line + 1, false, content_lines)
				else
					vim.api.nvim_buf_set_lines(bufnr, #lines, -1, false, { "", "---", unpack(content_lines) })
				end
			end
		else
			local start_line = last_separator + 1
			if lines[start_line] == "Thinking..." or lines[start_line] == "Processing request..." then
				vim.api.nvim_buf_set_lines(bufnr, start_line, start_line + 1, false, content_lines)
			else
				vim.api.nvim_buf_set_lines(bufnr, start_line, -1, false, content_lines)
			end
		end

		local line_count = vim.api.nvim_buf_line_count(bufnr)
		vim.api.nvim_win_set_cursor(vim.fn.win_getid(), { line_count, 0 })
	end)
end

function M.add_file_reference(filepath)
	local bufnr = create_or_get_buffer()
	local content = utils.get_buffer_content(filepath)

	if content then
		local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
		local line_count = #vim.split(content, "\n")
		local file_ext = vim.fn.fnamemodify(filepath, ":e")
		local file_block = {
			"",
			"```" .. file_ext,
			"// File: " .. filepath .. " (" .. line_count .. " lines)",
			"// Content hidden for brevity. Full content will be sent to the API.",
			"```",
			"",
		}

		vim.api.nvim_buf_set_lines(bufnr, #lines, #lines, false, file_block)
		vim.notify("Added file reference: " .. filepath, "info")

		vim.api.nvim_buf_set_var(bufnr, "file_content_" .. vim.fn.fnamemodify(filepath, ":t"), content)
	else
		vim.notify("Could not read file: " .. filepath, "error")
	end
end

function M.add_url_reference(url)
	local bufnr = create_or_get_buffer()
	local content, err = utils.get_url_content(url)

	if content then
		local line_count = #vim.split(content, "\n")
		local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
		local file_block = {
			"",
			"```html",
			"// URL: " .. url .. " (" .. line_count .. " lines)",
			"```",
			"",
		}

		vim.api.nvim_buf_set_lines(bufnr, #lines, #lines, false, file_block)
		vim.notify("Added URL reference: " .. url, "info")
		vim.api.nvim_buf_set_var(bufnr, "url_content_" .. url, content)
	else
		vim.notify("Could not load URL: " .. url .. ". Error: " .. tostring(err), "error")
	end
end

function M.prompt_api_key(callback)
	local Input = require("nui.input")
	local input = Input({
		position = "50%",
		size = { width = 60 },
		border = {
			style = "rounded",
			text = { top = "[OpenRouter API Key]", top_align = "center" },
		},
		win_options = { winhighlight = "Normal:Normal,FloatBorder:Normal" },
	}, {
		prompt = "> ",
		default_value = "",
		on_submit = function(value)
			if value and value ~= "" then
				config.save_api_key(value)
				config.config.api_key = value
				vim.env.OPENROUTER_API_KEY = value
				vim.notify("API key saved", "info")
				if callback then
					callback()
				end
			end
		end,
	})
	input:mount()
end

function M.save_api_key(key)
	local config_dir = vim.fn.stdpath("data")
	local config_file = config_dir .. "/openrouter_key"
	vim.fn.writefile({ key }, config_file)
end

function M.setup_session_autocmds(bufnr)
	vim.api.nvim_create_autocmd({ "BufUnload" }, {
		buffer = bufnr,
		callback = function()
			M.save_session(bufnr)
		end,
	})
end

function M.save_session(bufnr)
	local session_dir = vim.fn.stdpath("data") .. "/llm_sessions"
	vim.fn.mkdir(session_dir, "p")

	local timestamp = os.date("%Y%m%d_%H%M%S")
	local session_file = session_dir .. "/session_" .. timestamp .. ".md"

	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	vim.fn.writefile(lines, session_file)
end

function M.load_last_session(bufnr)
	local session_dir = vim.fn.stdpath("data") .. "/llm_sessions"
	local files = vim.fn.glob(session_dir .. "/*", 0, 1)

	if #files > 0 then
		table.sort(files)
		local last_session = files[#files]
		local lines = vim.fn.readfile(last_session)
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
	end
end

return M
