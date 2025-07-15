local M = {}

-- Log levels
M.levels = {
	TRACE = 0,
	DEBUG = 1,
	INFO = 2,
	WARN = 3,
	ERROR = 4,
}

-- Log level names
M.level_names = {
	[0] = "TRACE",
	[1] = "DEBUG",
	[2] = "INFO",
	[3] = "WARN",
	[4] = "ERROR",
}

-- Default configuration
M._config = {
	level = M.levels.INFO,
	file_logging = false,
	console_logging = true,
	log_file = vim.fn.stdpath("log") .. "/claude-fzf-history.log",
	max_file_size = 1024 * 1024, -- 1MB
	show_caller = true,
	timestamp = true,
}

function M.setup(opts)
	M._config = vim.tbl_deep_extend("force", M._config, opts or {})

	-- Ensure log directory exists
	if M._config.file_logging and M._config.log_file then
		-- Validate log file path
		local log_file = M._config.log_file
		if not log_file or log_file == "" or log_file:match("^/path") then
			-- Fallback to a safe default path
			local safe_path = vim.fn.stdpath("state")
			if safe_path and safe_path ~= "" then
				log_file = safe_path .. "/claude-fzf-history.log"
			else
				log_file = vim.fn.expand("~/.local/state/nvim/claude-fzf-history.log")
			end
			M._config.log_file = log_file
		end

		local log_dir = vim.fn.fnamemodify(log_file, ":h")
		-- Only create directory if path is valid and not root
		if log_dir and log_dir ~= "" and log_dir ~= "/" then
			local success, err = pcall(vim.fn.mkdir, log_dir, "p")
			if not success then
				-- Disable file logging if we can't create the directory
				M._config.file_logging = false
				if M._config.console_logging then
					print(
						"[claude-fzf-history] Warning: Could not create log directory, disabling file logging: "
							.. (err or "unknown error")
					)
				end
			end
		end
	end
end

function M.get_caller_info()
	if not M._config.show_caller then
		return ""
	end

	local info = debug.getinfo(4, "Sl")
	if info then
		local file = vim.fn.fnamemodify(info.source:sub(2), ":t")
		return string.format("[%s:%d] ", file, info.currentline or 0)
	end
	return ""
end

function M.format_message(level, msg, ...)
	local timestamp = ""
	if M._config.timestamp then
		timestamp = os.date("[%Y-%m-%d %H:%M:%S] ")
	end

	local caller = M.get_caller_info()
	local level_name = M.level_names[level] or "UNKNOWN"
	local formatted_msg = string.format(msg, ...)

	return string.format("%s[claude-fzf-history] [%s] %s%s", timestamp, level_name, caller, formatted_msg)
end

function M.should_log(level)
	return level >= M._config.level
end

function M.log_to_file(message)
	if not M._config.file_logging then
		return
	end

	-- Check file size, rotate if too large
	local stat = vim.loop.fs_stat(M._config.log_file)
	if stat and stat.size > M._config.max_file_size then
		local backup_file = M._config.log_file .. ".old"
		vim.loop.fs_rename(M._config.log_file, backup_file)
	end

	local file = io.open(M._config.log_file, "a")
	if file then
		file:write(message .. "\n")
		file:close()
	end
end

function M.log_to_console(level, message)
	if not M._config.console_logging then
		return
	end

	local vim_level
	if level >= M.levels.ERROR then
		vim_level = vim.log.levels.ERROR
	elseif level >= M.levels.WARN then
		vim_level = vim.log.levels.WARN
	else
		vim_level = vim.log.levels.INFO
	end

	vim.notify(message, vim_level)
end

function M.write_log(level, msg, ...)
	if not M.should_log(level) then
		return
	end

	local message = M.format_message(level, msg, ...)

	M.log_to_file(message)
	M.log_to_console(level, message)
end

-- Convenient log functions
function M.trace(msg, ...)
	M.write_log(M.levels.TRACE, msg, ...)
end

function M.debug(msg, ...)
	M.write_log(M.levels.DEBUG, msg, ...)
end

function M.info(msg, ...)
	M.write_log(M.levels.INFO, msg, ...)
end

function M.warn(msg, ...)
	M.write_log(M.levels.WARN, msg, ...)
end

function M.error(msg, ...)
	M.write_log(M.levels.ERROR, msg, ...)
end

-- Wrap function calls to capture errors
function M.safe_call(func, context, ...)
	local ok, result = pcall(func, context, ...)
	if not ok then
		M.error("Error in %s: %s", context or "unknown", result)
		return false, result
	end
	M.debug("Successfully executed %s", context or "unknown")
	return true, result
end

-- Performance timing
function M.time_call(func, context, ...)
	local start_time = vim.loop.hrtime()
	local ok, result = M.safe_call(func, context, ...)
	local end_time = vim.loop.hrtime()
	local duration = (end_time - start_time) / 1e6 -- Convert to milliseconds

	if ok then
		M.debug("%s completed in %.2f ms", context or "unknown", duration)
	else
		M.error("%s failed after %.2f ms", context or "unknown", duration)
	end

	return ok, result
end

-- Set log level
function M.set_level(level)
	M._config.level = level
	M.info("Log level set to %s", M.level_names[level])
end

-- Enable/disable file logging
function M.set_file_logging(enabled)
	M._config.file_logging = enabled

	if enabled then
		-- Ensure log directory exists when enabling
		local log_dir = vim.fn.fnamemodify(M._config.log_file, ":h")
		vim.fn.mkdir(log_dir, "p")
	end

	M.info("File logging %s", enabled and "enabled" or "disabled")
end

-- Enable/disable console logging
function M.set_console_logging(enabled)
	M._config.console_logging = enabled
	if enabled then
		M.info("Console logging enabled")
	end
end

-- Clear log file
function M.clear_log_file()
	if M._config.file_logging then
		local file = io.open(M._config.log_file, "w")
		if file then
			file:close()
			M.info("Log file cleared")
		end
	end
end

-- Enable debug mode
function M.enable_debug()
	M._config.level = M.levels.DEBUG
	M._config.file_logging = true
	M._config.console_logging = true

	-- Ensure log directory exists
	local log_dir = vim.fn.fnamemodify(M._config.log_file, ":h")
	vim.fn.mkdir(log_dir, "p")

	M.info("Debug mode enabled - log level: DEBUG, file logging: ON")
	M.debug("Debug mode is now active")
end

-- Disable debug mode
function M.disable_debug()
	M._config.level = M.levels.INFO
	M._config.file_logging = false

	M.info("Debug mode disabled - log level: INFO, file logging: OFF")
end

-- Export debug information
function M.export_debug_info()
	local info = {
		config = M._config,
		current_level = M._config.level,
		level_name = M.level_names[M._config.level],
		log_file_exists = vim.fn.filereadable(M._config.log_file) == 1,
		log_file_path = M._config.log_file,
	}

	-- Add log file size if it exists
	if info.log_file_exists then
		local stat = vim.loop.fs_stat(M._config.log_file)
		if stat then
			info.log_file_size = stat.size
		end
	end

	return info
end

-- Open log file in editor
function M.open_log_file()
	if M._config.file_logging and vim.fn.filereadable(M._config.log_file) == 1 then
		vim.cmd("edit " .. M._config.log_file)
	else
		vim.notify("Log file not found: " .. M._config.log_file, vim.log.levels.WARN)
	end
end

-- Log plugin state information
function M.log_plugin_state(module_name, state_info)
	M.debug("[%s] State: %s", module_name, vim.inspect(state_info))
end

-- Log function entry and exit
function M.log_function_call(module_name, func_name, args)
	M.debug("[%s] Calling %s with args: %s", module_name, func_name, vim.inspect(args or {}))
end

function M.log_function_return(module_name, func_name, result)
	M.debug(
		"[%s] %s returned: %s",
		module_name,
		func_name,
		type(result) == "table" and vim.inspect(result) or tostring(result)
	)
end

-- Log error with context
function M.log_error_with_context(module_name, func_name, error_msg, context)
	M.error("[%s] Error in %s: %s | Context: %s", module_name, func_name, error_msg, vim.inspect(context or {}))
end

-- Log system information for debugging
function M.log_system_info()
	M.debug("=== System Information ===")
	M.debug("Neovim version: %s", vim.version())
	M.debug("Operating system: %s", vim.loop.os_uname().sysname)
	M.debug("Working directory: %s", vim.loop.cwd())
	M.debug("Log file: %s", M._config.log_file)
	M.debug("Lua path: %s", package.path)
	M.debug("========================")
end

-- Log buffer information
function M.log_buffer_info(bufnr)
	bufnr = bufnr or vim.api.nvim_get_current_buf()
	if not vim.api.nvim_buf_is_valid(bufnr) then
		M.warn("Invalid buffer number: %s", bufnr)
		return
	end

	local bufname = vim.api.nvim_buf_get_name(bufnr)
	local filetype = vim.api.nvim_buf_get_option(bufnr, "filetype")
	local line_count = vim.api.nvim_buf_line_count(bufnr)

	M.debug("=== Buffer Information ===")
	M.debug("Buffer number: %d", bufnr)
	M.debug("Buffer name: %s", bufname)
	M.debug("File type: %s", filetype)
	M.debug("Line count: %d", line_count)
	M.debug("========================")
end

-- Export log content for debugging
function M.export_debug_info()
	local info = {
		timestamp = os.date("%Y-%m-%d %H:%M:%S"),
		system = vim.loop.os_uname(),
		neovim_version = vim.version(),
		log_config = M._config,
		log_stats = {},
	}

	-- Get log file stats
	local stat = vim.loop.fs_stat(M._config.log_file)
	if stat then
		info.log_stats = {
			size_bytes = stat.size,
			size_kb = stat.size / 1024,
			modified = os.date("%Y-%m-%d %H:%M:%S", stat.mtime.sec),
		}
	end

	return info
end

-- Get log file path
function M.get_log_file()
	return M._config.log_file
end

return M
