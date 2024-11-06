local M = {}
local Menu = require("nui.menu")
local Popup = require("nui.popup")
local config = require("nvim-llm.config")
local utils = require("nvim-llm.utils")

function M.show_file_picker()
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
			size = { width = 60, height = math.min(#menu_items + 2, 20) },
			border = {
				style = "rounded",
				text = { top = "[Browse Files] " .. vim.fn.fnamemodify(path, ":."), top_align = "center" },
			},
			win_options = { winhighlight = "Normal:Normal,FloatBorder:Normal" },
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
				-- Placeholder for file/directory handling
				print("Selected: " .. item.full_path)
			end,
		})

		menu:mount()
	end

	show_directory_menu(vim.fn.getcwd())
end

function M.select_model()
	local menu_items = {}
	for _, model in ipairs(config.config.models) do
		local indicator = model.id == config.config.default_model and "● " or "  "
		table.insert(menu_items, Menu.item(indicator .. model.name, { id = model.id }))
	end

	local menu = Menu({
		position = "50%",
		size = { width = 60, height = #menu_items + 2 },
		border = {
			style = "rounded",
			text = { top = "[Select Model]", top_align = "center" },
		},
		win_options = { winhighlight = "Normal:Normal,FloatBorder:Normal" },
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
			config.config.default_model = item.id
			config.save_config(config.config.system_prompt, config.config.default_model)
			vim.notify("Model changed to: " .. item.text:sub(3), "info")
		end,
	})

	menu:mount()
end

function M.configure_system_prompt()
	local popup = Popup({
		enter = true,
		position = "50%",
		size = { width = "80%", height = "60%" },
		border = {
			style = "rounded",
			text = { top = "[System Prompt]", top_align = "center" },
		},
		buf_options = { modifiable = true, readonly = false },
		win_options = {
			winhighlight = "Normal:Normal,FloatBorder:Normal",
			wrap = true,
			linebreak = true,
		},
	})

	popup:mount()

	if config.config.system_prompt then
		vim.api.nvim_buf_set_lines(popup.bufnr, 0, -1, false, vim.split(config.config.system_prompt, "\n"))
	end

	popup:map("n", "<CR>", function()
		local content = table.concat(vim.api.nvim_buf_get_lines(popup.bufnr, 0, -1, false), "\n")
		config.config.system_prompt = content ~= "" and content or nil
		config.save_config(config.config.system_prompt)
		vim.notify("System prompt " .. (content ~= "" and "updated" or "cleared"), "info")
		popup:unmount()
	end, { noremap = true })

	popup:map("n", "<Esc>", function()
		popup:unmount()
	end, { noremap = true })
end

function M.setup()
	-- Add any UI-related setup
	vim.notify = require("notify")
end

return M
