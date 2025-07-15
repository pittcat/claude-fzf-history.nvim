local M = {}

local utils = require("claude-fzf-history.utils")

-- Build preview window options string for fzf
function M.build_preview_window_opts(preview_opts)
	local opts = { preview_opts.position }

	if preview_opts.hidden then
		table.insert(opts, "hidden")
	end

	if preview_opts.wrap then
		table.insert(opts, "wrap")
	else
		table.insert(opts, "nowrap")
	end

	-- Add border style
	table.insert(opts, "border-rounded")

	return table.concat(opts, ",")
end

-- Build key bindings for preview control
function M.build_preview_bindings(preview_opts)
	local bindings = {}

	-- Toggle preview
	table.insert(bindings, preview_opts.toggle_key .. ":toggle-preview")

	-- Preview scrolling
	table.insert(bindings, preview_opts.scroll_up .. ":preview-page-up")
	table.insert(bindings, preview_opts.scroll_down .. ":preview-page-down")

	-- Additional preview controls
	table.insert(bindings, "ctrl-u:preview-half-page-up")
	table.insert(bindings, "ctrl-d:preview-half-page-down")
	table.insert(bindings, "ctrl-f:preview-page-down")
	table.insert(bindings, "ctrl-b:preview-page-up")

	return bindings
end

-- Create preview script for external preview
function M.create_preview_script(history_items, display_opts)
	-- Create a temporary Lua script that will be executed by fzf
	local script_content = [[
local selected_line = arg[1]
if not selected_line then
  print("No selection")
  os.exit(0)
end

-- Parse the selected line to extract index or identifier
local function extract_item_info(line)
  -- Try to extract timestamp and line number
  local timestamp = line:match("^%[(.-)%]")
  local line_num = line:match("L(%d+)")
  local question_start = line:match("%]%s*L?%d*%s*(.+)$") or line
  
  return {
    timestamp = timestamp,
    line_num = line_num,
    question = question_start
  }
end

local info = extract_item_info(selected_line)

-- Find matching history item
local history_data = vim.fn.json_decode(vim.fn.readfile('%s')[1])
local matched_item = nil

for _, item in ipairs(history_data.items) do
  local item_question = item.question:sub(1, history_data.display_opts.max_question_length)
  if item_question:gsub("%.%.%.$", "") == info.question:gsub("%.%.%.$", "") then
    matched_item = item
    break
  end
end

if not matched_item then
  print("Cannot find corresponding Q&A item")
  os.exit(0)
end

-- Format preview output
local function format_timestamp(ts, format)
  return os.date(format or "%%Y-%%m-%%d %%H:%%M", ts)
end

-- Print preview
print(string.format("Time: %%s", format_timestamp(matched_item.timestamp, history_data.display_opts.date_format)))

if matched_item.metadata and matched_item.metadata.buffer_name then
  print(string.format("Buffer: %%s", matched_item.metadata.buffer_name))
end

if matched_item.buffer_line_start then
  print(string.format("Location: Line %%d-%%d", 
    matched_item.buffer_line_start, 
    matched_item.buffer_line_end or matched_item.buffer_line_start))
end

print("")
print("═══ Question ═══")
print(matched_item.question)
print("")
print("═══ Answer ═══")
print(matched_item.answer)

if matched_item.tags and #matched_item.tags > 0 then
  print("")
  print(string.format("Tags: %%s", table.concat(matched_item.tags, ", ")))
end
]]

	-- Create temp file for history data
	local data_file = vim.fn.tempname()
	local history_data = {
		items = history_items,
		display_opts = display_opts,
	}
	vim.fn.writefile({ vim.fn.json_encode(history_data) }, data_file)

	-- Format the script with the data file path
	script_content = string.format(script_content, data_file)

	-- Create temp script file
	local script_file = vim.fn.tempname() .. ".lua"
	vim.fn.writefile(vim.split(script_content, "\n"), script_file)

	-- Return the command to execute
	return string.format('nvim -u NONE -n --headless --cmd "lua dofile([[%s]])" +q {}', script_file)
end

-- Simple shell-based preview command (fallback)
function M.create_simple_preview_command()
	-- This is a simple preview that just shows the selected line
	-- Used as fallback when we can't create a proper preview
	return 'echo "Preview: {}"'
end

return M
