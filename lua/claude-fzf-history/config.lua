local M = {}

M.defaults = {
	-- History parsing settings
	history = {
		max_items = 1000, -- Maximum number of history items
		min_item_length = 10, -- Minimum Q&A length
		cache_timeout = 300, -- Cache timeout (seconds)
		auto_refresh = true, -- Auto refresh history
	},

	-- Logging settings
	logging = {
		level = "INFO", -- TRACE, DEBUG, INFO, WARN, ERROR
		file_logging = false, -- Enable file logging
		console_logging = true, -- Enable console logging
		show_caller = true, -- Show caller information
		timestamp = true, -- Show timestamps
		log_file = nil, -- Auto set log file path
	},

	-- Display settings
	display = {
		max_question_length = 80, -- Maximum question display length
		show_timestamp = true, -- Show timestamps
		show_line_numbers = true, -- Show line numbers
		date_format = "%Y-%m-%d %H:%M", -- Time format
	},

	-- FZF settings
	fzf_opts = {
		-- Enable multi-select functionality
		["--multi"] = true, -- Enable multi-select mode
		["--ansi"] = "",
		["--info"] = "inline",
		["--height"] = "100%",
		["--layout"] = "reverse",
		["--border"] = "none",
		silent = true, -- Hide deprecation warnings
		winopts = {
			height = 0.7,
			width = 0.8,
			row = 0.35,
			col = 0.50,
		},
	},

	-- Preview settings
	preview = {
		enabled = true, -- Enable preview
		hidden = false, -- Start with preview visible
		position = "right:60%", -- Preview window position
		wrap = true, -- Enable line wrapping
		toggle_key = "ctrl-/", -- Key to toggle preview
		scroll_up = "shift-up", -- Preview scroll up
		scroll_down = "shift-down", -- Preview scroll down
		-- Preview command type: 'builtin' or 'external'
		-- 'builtin' uses fzf-lua's preview, 'external' uses native fzf preview
		type = "external",
		-- Syntax highlighting settings
		syntax_highlighting = {
			enabled = true, -- Enable syntax highlighting with bat
			fallback = true, -- Fallback to plain text if bat unavailable
			theme = "Monokai Extended Bright", -- bat theme
			language = "markdown", -- Default language for Q&A content
			show_line_numbers = true, -- Show line numbers in bat output
		},
	},

	-- FZF keyboard mapping
	keymap = {
		fzf = {
			["tab"] = "toggle", -- Tab key for multi-select
			-- Removed Ctrl-Y preview function, no longer needed
		},
	},

	-- Shortcut key settings
	keymaps = {
		history = "<leader>ch",
	},

	-- Parser settings
	parser = {
		patterns = {
			-- Claude CLI standard output format
			question_start = "^>%s*(.+)$",
			answer_start = "^Claude:",
			answer_continuation = "^%s*(.+)$",
		},
		ignore_patterns = {
			"^%s*$", -- Empty lines
			"^%-%-%-+$", -- Separator lines
			"^%[%d+%-%d+%-%d+", -- Timestamp lines
		},
	},

	-- Action settings
	actions = {
		jump_to_qa = "default", -- Jump to Q&A (Enter key)
		-- Removed preview_qa function, no longer need Ctrl-Y preview
		export_qa = "ctrl-e", -- Export Q&A
		search_qa = "ctrl-/", -- Search Q&A
		filter_qa = "ctrl-f", -- Filter Q&A
	},
}

M._config = {}

function M.setup(opts)
	M._config = vim.tbl_deep_extend("force", M.defaults, opts or {})

	-- Initialize logging system
	M.init_logging()

	M.validate_config()
	return M._config
end

function M.init_logging()
	local logger = require("claude-fzf-history.logger")
	local log_config = M._config.logging

	-- Set default log file path with fallback
	if not log_config.log_file then
		local log_dir = vim.fn.stdpath("log")
		if not log_dir or log_dir == "" then
			-- Fallback to state directory
			log_dir = vim.fn.stdpath("state")
			if not log_dir or log_dir == "" then
				-- Final fallback to home directory
				log_dir = vim.fn.expand("~/.local/state/nvim")
			end
		end
		log_config.log_file = log_dir .. "/claude-fzf-history.log"
	end

	-- Convert string level to number
	local log_level = logger.levels[log_config.level:upper()] or logger.levels.INFO

	logger.setup({
		level = log_level,
		file_logging = log_config.file_logging,
		console_logging = log_config.console_logging,
		show_caller = log_config.show_caller,
		timestamp = log_config.timestamp,
		log_file = log_config.log_file,
	})

	logger.info("claude-fzf-history.nvim initialized successfully")
	logger.debug("Configuration: %s", vim.inspect(M._config))
end

function M.validate_config()
	local ok, err = pcall(function()
		vim.validate({
			history = { M._config.history, "table" },
			display = { M._config.display, "table" },
			fzf_opts = { M._config.fzf_opts, "table" },
			keymaps = { M._config.keymaps, "table" },
			parser = { M._config.parser, "table" },
			actions = { M._config.actions, "table" },
		})
	end)

	if not ok then
		error("[claude-fzf-history] Invalid configuration: " .. err)
	end

	if M._config.history.max_items < 1 then
		M._config.history.max_items = 100
	end

	if M._config.display.max_question_length < 10 then
		M._config.display.max_question_length = 50
	end
end

function M.get()
	return M._config
end

function M.get_history_opts()
	return M._config.history
end

function M.get_display_opts()
	return M._config.display
end

function M.get_fzf_opts()
	return M._config.fzf_opts
end

function M.get_parser_opts()
	return M._config.parser
end

function M.get_actions()
	return M._config.actions
end

function M.get_logging_opts()
	return M._config.logging
end

function M.get_keymap()
	return M._config.keymap
end

function M.enable_debug()
	local logger = require("claude-fzf-history.logger")
	logger.enable_debug()
	M._config.logging.level = "DEBUG"
	M._config.logging.file_logging = true
end

function M.get_preview_opts()
	return M._config.preview
end

function M.disable_debug()
	local logger = require("claude-fzf-history.logger")
	logger.disable_debug()
	M._config.logging.level = "INFO"
	M._config.logging.file_logging = false
end

return M
