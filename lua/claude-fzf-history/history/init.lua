local M = {}

local parser = require('claude-fzf-history.history.parser')
local picker = require('claude-fzf-history.history.picker')
local manager = require('claude-fzf-history.history.manager')

function M.open_picker(opts)
  opts = opts or {}
  
  -- Get history records
  local history_items = manager.get_history(opts)
  
  if not history_items or #history_items == 0 then
    vim.notify("No Claude conversation history found", vim.log.levels.WARN)
    return
  end
  
  -- Open picker
  picker.create_history_picker(history_items, opts)
end

function M.refresh_history()
  manager.refresh_cache()
end

function M.get_qa_items(bufnr)
  return parser.parse_claude_terminal(bufnr)
end

return M