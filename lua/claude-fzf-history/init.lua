local M = {}

M._config = {}

function M.setup(opts)
	local config = require("claude-fzf-history.config")
	M._config = config.setup(opts)

	vim.validate({
		fzf_lua = { pcall(require, "fzf-lua"), "boolean" },
	})

	require("claude-fzf-history.commands").setup()
end

function M.history(opts)
	return require("claude-fzf-history.history").open_picker(opts)
end

function M.get_config()
	return M._config
end

-- Debug functionality API
function M.enable_debug()
	local config = require("claude-fzf-history.config")
	config.enable_debug()
end

function M.disable_debug()
	local config = require("claude-fzf-history.config")
	config.disable_debug()
end

function M.get_debug_info()
	local logger = require("claude-fzf-history.logger")
	return logger.export_debug_info()
end

function M.open_log_file()
	local logger = require("claude-fzf-history.logger")
	logger.open_log_file()
end

return M
