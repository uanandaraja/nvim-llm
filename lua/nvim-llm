local M = {}

function M.setup(opts)
	local config
	-- Modules
	local curl = require("plenary.curl")
	local Menu = require("nui.menu")
	local event = require("nui.utils.autocmd").event

	-- Session Management
	local function save_session(bufnr)
		local session_dir = vim.fn.stdpath("data") .. "/llm_sessions"
		vim.fn.mkdir(session_dir, "p")

		local timestamp = os.date("%Y%m%d_%H%M%S")
		local session_file = session_dir .. "/session_" .. timestamp .. ".md"

		local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
		vim.fn.writefile(lines, session_file)
	end

	local function load_last_session(bufnr)
		local session_dir = vim.fn.stdpath("data") .. "/llm_sessions"
		local files = vim.fn.glob(session_dir .. "/*", 0, 1)

		if #files > 0 then
			table.sort(files)
			local last_session = files[#files]
			local lines = vim.fn.readfile(last_session)
			vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
		end
	end

	local function setup_session_autocmds(bufnr)
		vim.api.nvim_create_autocmd({ "BufUnload" }, {
			buffer = bufnr,
			callback = function()
				save_session(bufnr)
			end,
		})
	end

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

	local function save_config(system_prompt, default_model)
		local config_file = vim.fn.stdpath("data") .. "/llm_config.json"
		local data = vim.fn.json_encode({
			system_prompt = system_prompt,
			default_model = default_model,
		})
		vim.fn.writefile({ data }, config_file)
	end

	local function save_api_key(key)
		local config_dir = vim.fn.stdpath("data")
		local config_file = config_dir .. "/openrouter_key"
		vim.fn.writefile({ key }, config_file)
	end

	local function load_api_key()
		local config_file = vim.fn.stdpath("data") .. "/openrouter_key"
		if vim.fn.filereadable(config_file) == 1 then
			local lines = vim.fn.readfile(config_file)
			return lines[1]
		end
		return nil
	end

	-- Configuration
	local saved_prompt, saved_model = load_saved_config()
	config = {
		api_key = load_api_key() or vim.env.OPENROUTER_API_KEY,
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
		system_prompt = saved_prompt,
		default_model = saved_model or "anthropic/claude-3.5-sonnet",
	}

	local function select_model()
		local menu_items = {}
		for _, model in ipairs(config.models) do
			local indicator = model.id == config.default_model and "● " or "  "
			table.insert(menu_items, Menu.item(indicator .. model.name, { id = model.id }))
		end

		local menu = Menu({
			position = "50%",
			size = {
				width = 60,
				height = #menu_items + 2,
			},
			border = {
				style = "rounded",
				text = {
					top = "[Select Model]",
					top_align = "center",
				},
			},
			win_options = {
				winhighlight = "Normal:Normal,FloatBorder:Normal",
			},
		}, {
			lines = menu_items,
			max_width = 60,
			keymap = {
				focus_next = { "j", "<Down>", "<Tab>" },
				focus_prev = { "k", "<Up>", "<S-Tab>" },
				close = { "<Esc>", "<C-c>" },
				submit = { "<CR>", "<Space>" },
			},
			on_submit = function(item)
				config.default_model = item.id
				save_config(config.system_prompt, config.default_model)
				vim.notify("Model changed to: " .. item.text:sub(3), "info") -- Remove indicator from notification
			end,
		})

		menu:mount()
		menu:on(event.BufLeave, menu.menu_props.on_close, { once = true })
	end

	local function configure_system_prompt()
		local Popup = require("nui.popup")
		local event = require("nui.utils.autocmd").event

		local popup = Popup({
			enter = true,
			position = "50%",
			size = {
				width = "80%",
				height = "60%",
			},
			border = {
				style = "rounded",
				text = {
					top = "[System Prompt]",
					top_align = "center",
				},
			},
			buf_options = {
				modifiable = true,
				readonly = false,
			},
			win_options = {
				winhighlight = "Normal:Normal,FloatBorder:Normal",
				wrap = true,
				linebreak = true,
			},
		})

		popup:mount()

		if config.system_prompt then
			vim.api.nvim_buf_set_lines(popup.bufnr, 0, -1, false, vim.split(config.system_prompt, "\n"))
		end

		popup:map("n", "<CR>", function()
			local content = table.concat(vim.api.nvim_buf_get_lines(popup.bufnr, 0, -1, false), "\n")
			config.system_prompt = content ~= "" and content or nil
			save_config(config.system_prompt)
			vim.notify("System prompt " .. (content ~= "" and "updated" or "cleared"), "info")
			popup:unmount()
		end, { noremap = true })

		popup:map("n", "<Esc>", function()
			popup:unmount()
		end, { noremap = true })

		popup:on(event.BufLeave, function()
			popup:unmount()
		end)
	end

	-- Setup notifications
	vim.notify = require("notify")

	-- Forward declarations
	local submit_prompt
	local create_or_get_buffer
	local add_file_reference

	-- File browser functions
	local function get_directory_contents(path)
		local handle = vim.loop.fs_scandir(path)
		local contents = {}

		if handle then
			while true do
				local name, type = vim.loop.fs_scandir_next(handle)
				if not name then
					break
				end

				table.insert(contents, {
					name = name,
					type = type,
					full_path = path .. "/" .. name,
				})
			end
		end

		table.sort(contents, function(a, b)
			if a.type == b.type then
				return a.name < b.name
			end
			return a.type == "directory"
		end)

		return contents
	end

	local function show_directory_menu(path)
		local contents = get_directory_contents(path)
		local menu_items = {}

		if path ~= "/" then
			table.insert(
				menu_items,
				Menu.item("..", {
					full_path = vim.fn.fnamemodify(path, ":h"),
					is_directory = true,
				})
			)
		end

		for _, item in ipairs(contents) do
			local display_name = item.type == "directory" and item.name .. "/" or item.name
			table.insert(
				menu_items,
				Menu.item(display_name, {
					full_path = item.full_path,
					is_directory = item.type == "directory",
				})
			)
		end

		local menu = Menu({
			position = "50%",
			size = {
				width = 60,
				height = math.min(#menu_items + 2, 20),
			},
			border = {
				style = "rounded",
				text = {
					top = "[Browse Files] " .. vim.fn.fnamemodify(path, ":."),
					top_align = "center",
				},
			},
			win_options = {
				winhighlight = "Normal:Normal,FloatBorder:Normal",
			},
		}, {
			lines = menu_items,
			max_width = 60,
			keymap = {
				focus_next = { "j", "<Down>", "<Tab>" },
				focus_prev = { "k", "<Up>", "<S-Tab>" },
				close = { "<Esc>", "<C-c>" },
				submit = { "<CR>", "<Space>" },
			},
			on_submit = function(item)
				if item.is_directory then
					show_directory_menu(item.full_path)
				else
					add_file_reference(item.full_path)
				end
			end,
		})

		menu:mount()
		menu:on(event.BufLeave, menu.menu_props.on_close, { once = true })
	end

	local function show_buffer_picker()
		local buffers = {}
		for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
			local name = vim.api.nvim_buf_get_name(bufnr)
			if name and name ~= "" and vim.api.nvim_buf_is_loaded(bufnr) then
				local relative_path = vim.fn.fnamemodify(name, ":.")
				table.insert(buffers, {
					text = relative_path,
					full_path = name,
				})
			end
		end

		local menu_items = {}
		for _, buf in ipairs(buffers) do
			table.insert(menu_items, Menu.item(buf.text, { full_path = buf.full_path }))
		end

		local menu = Menu({
			position = "50%",
			size = {
				width = 60,
				height = math.min(#menu_items + 2, 20),
			},
			border = {
				style = "rounded",
				text = {
					top = "[Select Buffer]",
					top_align = "center",
				},
			},
			win_options = {
				winhighlight = "Normal:Normal,FloatBorder:Normal",
			},
		}, {
			lines = menu_items,
			max_width = 60,
			keymap = {
				focus_next = { "j", "<Down>", "<Tab>" },
				focus_prev = { "k", "<Up>", "<S-Tab>" },
				close = { "<Esc>", "<C-c>" },
				submit = { "<CR>", "<Space>" },
			},
			on_submit = function(item)
				add_file_reference(item.full_path)
			end,
		})

		menu:mount()
		menu:on(event.BufLeave, menu.menu_props.on_close, { once = true })
	end

	local function show_file_picker()
		local menu = Menu({
			position = "50%",
			size = {
				width = 40,
				height = 4,
			},
			border = {
				style = "rounded",
				text = {
					top = "[Select Source]",
					top_align = "center",
				},
			},
		}, {
			lines = {
				Menu.item("Open Buffers", { id = "buffers" }),
				Menu.item("Browse Files", { id = "files" }),
			},
			on_submit = function(item)
				if item.id == "buffers" then
					show_buffer_picker()
				else
					show_directory_menu(vim.fn.getcwd())
				end
			end,
		})

		menu:mount()
	end

	local function get_url_content(url)
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

	local function add_url_reference(url)
		local bufnr = create_or_get_buffer()
		local content, err = get_url_content(url)

		if not content then
			vim.notify("Could not load URL: " .. url .. ". Error: " .. tostring(err), "error")
			return
		end

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
	end

	local function get_diagnostic_text(diagnostic)
		local severity = vim.diagnostic.severity
		local severity_text = {
			[severity.ERROR] = "ERROR",
			[severity.WARN] = "WARNING",
			[severity.INFO] = "INFO",
			[severity.HINT] = "HINT",
		}

		return string.format("[%s] %s", severity_text[diagnostic.severity], diagnostic.message)
	end

	local function format_diagnostics(bufnr, range)
		local diagnostics = vim.diagnostic.get(bufnr)
		if #diagnostics == 0 then
			return nil
		end

		local content = {}
		local context_lines = 2 -- lines before/after error
		local file_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
		local filepath = vim.api.nvim_buf_get_name(bufnr)
		local file_ext = vim.fn.fnamemodify(filepath, ":e")

		for _, diag in ipairs(diagnostics) do
			local start_line = math.max(0, diag.lnum - context_lines)
			local end_line = math.min(#file_lines, diag.lnum + context_lines + 1)

			table.insert(content, string.format("In file %s:", filepath))
			table.insert(content, get_diagnostic_text(diag))
			table.insert(content, "```" .. file_ext)

			for i = start_line, end_line - 1 do
				local prefix = i == diag.lnum and ">" or " "
				table.insert(content, string.format("%s %4d │ %s", prefix, i + 1, file_lines[i + 1]))
			end

			table.insert(content, "```\n")
		end

		return table.concat(content, "\n")
	end

	local function add_error_reference(bufnr, range)
		local diagnostic_text = format_diagnostics(bufnr, range)
		if not diagnostic_text then
			vim.notify("No diagnostics found in buffer", "warn")
			return
		end

		local llm_bufnr = create_or_get_buffer()
		local lines = vim.api.nvim_buf_get_lines(llm_bufnr, 0, -1, false)
		local error_block = vim.split(diagnostic_text, "\n")

		vim.api.nvim_buf_set_lines(llm_bufnr, #lines, #lines, false, error_block)
		vim.notify("Added error reference", "info")
	end

	local function show_error_buffer_picker()
		local buffers_with_errors = {}
		for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
			if vim.api.nvim_buf_is_loaded(bufnr) then
				local diagnostics = vim.diagnostic.get(bufnr)
				if #diagnostics > 0 then
					local name = vim.api.nvim_buf_get_name(bufnr)
					if name and name ~= "" then
						table.insert(buffers_with_errors, {
							text = string.format("%s (%d issues)", vim.fn.fnamemodify(name, ":."), #diagnostics),
							bufnr = bufnr,
						})
					end
				end
			end
		end

		if #buffers_with_errors == 0 then
			vim.notify("No buffers with errors found", "warn")
			return
		end

		local menu = Menu({
			position = "50%",
			size = {
				width = 60,
				height = math.min(#buffers_with_errors + 2, 20),
			},
			border = {
				style = "rounded",
				text = {
					top = "[Select Buffer with Errors]",
					top_align = "center",
				},
			},
			win_options = {
				winhighlight = "Normal:Normal,FloatBorder:Normal",
			},
		}, {
			lines = vim.tbl_map(function(buf)
				return Menu.item(buf.text, { bufnr = buf.bufnr })
			end, buffers_with_errors),
			keymap = {
				focus_next = { "j", "<Down>", "<Tab>" },
				focus_prev = { "k", "<Up>", "<S-Tab>" },
				close = { "<Esc>", "<C-c>" },
				submit = { "<CR>", "<Space>" },
			},
			on_submit = function(item)
				add_error_reference(item.bufnr)
			end,
		})

		menu:mount()
		menu:on(event.BufLeave, menu.menu_props.on_close, { once = true })
	end

	-- Buffer content functions
	local function get_buffer_content(filepath)
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

	-- Add file reference function
	add_file_reference = function(filepath)
		local bufnr = create_or_get_buffer()
		local content = get_buffer_content(filepath)

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

			-- Store the full content in a hidden variable
			vim.api.nvim_buf_set_var(bufnr, "file_content_" .. vim.fn.fnamemodify(filepath, ":t"), content)
		else
			vim.notify("Could not read file: " .. filepath, "error")
		end
	end

	-- Create or get buffer function
	create_or_get_buffer = function()
		local bufnr = vim.fn.bufnr(config.bufname)
		if bufnr == -1 then
			bufnr = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_buf_set_name(bufnr, config.bufname)
			vim.api.nvim_buf_set_option(bufnr, "filetype", "markdown")
			vim.api.nvim_buf_set_option(bufnr, "buftype", "nofile")
			vim.api.nvim_buf_set_option(bufnr, "swapfile", false)

			-- Set up keymaps
			local function map(mode, lhs, rhs, opts)
				opts = opts or {}
				opts.buffer = bufnr
				vim.keymap.set(mode, lhs, rhs, opts)
			end

			map("n", "<leader>ls", function()
				submit_prompt()
			end, { desc = "Submit to LLM" })
			map("n", "<leader>lc", function()
				vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
			end, { desc = "Clear chat" })
			map("n", "<leader>lq", "<cmd>quit<CR>", { desc = "Quit chat" })
			map("n", "<leader>lf", function()
				show_file_picker()
			end, { desc = "Add file reference" })
			map("n", "<leader>lb", function()
				add_file_reference(vim.fn.expand("%:p"))
			end, { desc = "Add current buffer" })
			map("n", "<leader>lm", function()
				select_model()
			end, { desc = "Select Model" })
			map("n", "<leader>lu", function()
				local url = vim.fn.input({
					prompt = "Enter URL: ",
					default = "",
				})
				if url ~= "" then
					add_url_reference(url)
				end
			end, { desc = "Add URL reference" })

			map("n", "<leader>le", function()
				add_error_reference(vim.fn.bufnr())
			end, { desc = "Add errors from current buffer" })

			map("n", "<leader>lE", function()
				show_error_buffer_picker()
			end, { desc = "Add errors from any buffer" })

			-- Optional: Add selected range errors
			map("v", "<leader>le", function()
				local start_pos = vim.fn.getpos("'<")
				local end_pos = vim.fn.getpos("'>")
				local range = {
					start = start_pos[2] - 1,
					["end"] = end_pos[2],
				}
				add_error_reference(vim.fn.bufnr(), range)
			end, { desc = "Add errors from selection" })

			setup_session_autocmds(bufnr)
			load_last_session(bufnr)
		end
		return bufnr
	end

	-- Buffer update function
	local function update_buffer(bufnr, content)
		vim.schedule(function()
			if vim.api.nvim_buf_is_valid(bufnr) then
				if content == nil then
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

				local content_lines = type(content) == "string" and vim.split(content, "\n", { plain = true })
					or { content }

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
			end
		end)
	end

	-- Submit prompt function
	submit_prompt = function()
		local bufnr = create_or_get_buffer()
		local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
		local content = table.concat(lines, "\n")

		content = content:gsub(
			"```(%w+)\n// File: ([^\n]+) %((%d+) lines%)\n// Content hidden for brevity%. Full content will be sent to the API%.\n```",
			function(ext, filepath, line_count)
				local file_content =
					vim.api.nvim_buf_get_var(bufnr, "file_content_" .. vim.fn.fnamemodify(filepath, ":t"))
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

		local accumulated_content = ""
		vim.notify("Sending request to LLM...", "info")
		update_buffer(bufnr, "Thinking...")

		local messages = {}
		if config.system_prompt then
			table.insert(messages, { role = "system", content = config.system_prompt })
		end
		table.insert(messages, { role = "user", content = content })

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
					local content_lines = vim.split(accumulated_content, "\n", { plain = true })

					local buffer_lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
					local separator_line = -1
					for i = #buffer_lines, 1, -1 do
						if buffer_lines[i] == "---" then
							separator_line = i
							break
						end
					end

					if separator_line ~= -1 then
						vim.api.nvim_buf_set_lines(bufnr, separator_line + 1, -1, false, content_lines)
					end
				end
			end
		end)

		curl.post("https://openrouter.ai/api/v1/chat/completions", {
			headers = {
				Authorization = "Bearer " .. config.api_key,
				["HTTP-Referer"] = config.site_url,
				["X-Title"] = config.site_name,
				["Content-Type"] = "application/json",
			},
			body = vim.fn.json_encode({
				model = config.default_model,
				messages = messages,
				stream = true,
			}),
			stream = function(_, chunk)
				handle_chunk(chunk)
			end,
			on_error = vim.schedule_wrap(function(error)
				vim.notify("Request failed: " .. vim.inspect(error), "error")
				update_buffer(bufnr, "Error: Request failed\n" .. vim.inspect(error))
			end),
		})
	end

	-- Set up the command and keymaps
	vim.api.nvim_create_user_command("LLM", function()
		local function open_llm()
			local bufnr = create_or_get_buffer()
			vim.cmd("botright vsplit")
			local win = vim.api.nvim_get_current_win()
			vim.api.nvim_win_set_buf(win, bufnr)
			vim.wo[win].wrap = true
			vim.wo[win].linebreak = true
			vim.wo[win].breakindent = true
			vim.cmd("stopinsert")
		end

		if not config.api_key then
			vim.notify("OpenRouter API key not found", "warn")
			prompt_api_key(open_llm)
		else
			open_llm()
		end
	end, {})

	vim.keymap.set("n", "<leader>lo", function()
		vim.cmd("LLM")
	end, { desc = "Open LLM Chat" })

	vim.keymap.set("n", "<leader>lp", function()
		configure_system_prompt()
	end, { desc = "Configure System Prompt" })

	-- Store functions we want to expose
	M.submit_prompt = submit_prompt
	M.add_file_reference = add_file_reference
	M.show_file_picker = show_file_picker
	M.select_model = select_model
	M.configure_system_prompt = configure_system_prompt
end

return M
