local M = {}

local utils = require('claude-fzf-history.utils')
local parser = require('claude-fzf-history.history.parser')

local function get_logger()
  return require('claude-fzf-history.logger')
end

-- Cache management
local cache = {
  items = {},
  last_updated = 0,
  buffer_info = {}
}

function M.get_history(opts)
  local logger = get_logger()
  logger.log_function_call("manager", "get_history", opts)
  
  opts = opts or {}
  local config = require('claude-fzf-history.config')
  local history_opts = config.get_history_opts()
  
  logger.log_plugin_state("manager", {
    cache_items_count = #cache.items,
    cache_last_updated = cache.last_updated,
    history_opts = history_opts
  })
  
  -- Check if cache needs refresh
  local current_time = os.time()
  local cache_expired = (current_time - cache.last_updated) > history_opts.cache_timeout
  
  logger.debug("Cache status: expired=%s, items=%d, force_refresh=%s", 
    tostring(cache_expired), #cache.items, tostring(opts.force_refresh))
  
  if cache_expired or #cache.items == 0 or opts.force_refresh then
    logger.debug("Refreshing cache...")
    cache.items = M.collect_history_from_buffers()
    cache.last_updated = current_time
    logger.debug("Cache refreshed with %d items", #cache.items)
  else
    logger.debug("Using cached items (%d total)", #cache.items)
  end
  
  -- Apply filtering and limits
  local filtered_items = M.filter_items(cache.items, opts)
  logger.debug("Filtered to %d items", #filtered_items)
  
  -- Limit maximum number of items
  if #filtered_items > history_opts.max_items then
    local start_index = #filtered_items - history_opts.max_items + 1
    filtered_items = vim.list_slice(filtered_items, start_index)
    logger.debug("Limited to %d items (max_items=%d)", #filtered_items, history_opts.max_items)
  end
  
  logger.log_function_return("manager", "get_history", {
    result_count = #filtered_items,
    cache_used = not (cache_expired or #cache.items == 0 or opts.force_refresh)
  })
  
  return filtered_items
end

function M.collect_history_from_buffers()
  local logger = get_logger()
  logger.log_function_call("manager", "collect_history_from_buffers", {})
  
  local claude_buffers = utils.find_claude_buffers()
  logger.debug("Found %d Claude buffers", #claude_buffers)
  
  local all_items = {}
  
  for i, buffer_info in ipairs(claude_buffers) do
    logger.debug("Processing buffer %d/%d: %s (bufnr=%d)", 
      i, #claude_buffers, buffer_info.name, buffer_info.bufnr)
    
    local items, err = parser.parse_claude_terminal(buffer_info.bufnr)
    
    if items then
      logger.debug("Parsed %d items from buffer %s", #items, buffer_info.name)
      
      -- Add buffer information to each item
      for _, item in ipairs(items) do
        item.metadata.buffer_name = buffer_info.name
        item.metadata.buffer_filetype = buffer_info.filetype
        table.insert(all_items, item)
      end
    else
      logger.log_error_with_context("manager", "collect_history_from_buffers", 
        "Failed to parse buffer", {
          buffer_name = buffer_info.name,
          bufnr = buffer_info.bufnr,
          error = err
        })
      
      vim.notify(
        string.format("Failed to parse buffer %s: %s", 
          buffer_info.name, err or "unknown error"),
        vim.log.levels.WARN
      )
    end
  end
  
  logger.debug("Collected %d total items from all buffers", #all_items)
  
  -- Sort by timestamp (newest first)
  table.sort(all_items, function(a, b)
    return a.timestamp > b.timestamp
  end)
  
  logger.debug("Sorted items by timestamp (newest first)")
  logger.log_function_return("manager", "collect_history_from_buffers", {
    total_items = #all_items,
    buffers_processed = #claude_buffers
  })
  
  return all_items
end

function M.filter_items(items, opts)
  local logger = get_logger()
  logger.log_function_call("manager", "filter_items", {
    items_count = #items,
    opts = opts
  })
  
  local config = require('claude-fzf-history.config')
  local history_opts = config.get_history_opts()
  
  local filtered = {}
  local filter_stats = {
    total_processed = 0,
    excluded_by_min_length = 0,
    excluded_by_search = 0,
    excluded_by_time = 0,
    included = 0
  }
  
  for _, item in ipairs(items) do
    filter_stats.total_processed = filter_stats.total_processed + 1
    local should_include = true
    local exclude_reason = ""
    
    -- Minimum length filter
    local total_length = #item.question + #item.answer
    if total_length < history_opts.min_item_length then
      should_include = false
      exclude_reason = "min_length"
      filter_stats.excluded_by_min_length = filter_stats.excluded_by_min_length + 1
    end
    
    -- Keyword filter
    if should_include and opts.search_term then
      local search_lower = opts.search_term:lower()
      local question_lower = item.question:lower()
      local answer_lower = item.answer:lower()
      
      if not (question_lower:find(search_lower, 1, true) or 
              answer_lower:find(search_lower, 1, true)) then
        should_include = false
        exclude_reason = "search_term"
        filter_stats.excluded_by_search = filter_stats.excluded_by_search + 1
      end
    end
    
    -- Time range filter
    if should_include and opts.start_time and item.timestamp < opts.start_time then
      should_include = false
      exclude_reason = "time_range"
      filter_stats.excluded_by_time = filter_stats.excluded_by_time + 1
    end
    
    if opts.end_time and item.timestamp > opts.end_time then
      should_include = false
      exclude_reason = "time_range"
      filter_stats.excluded_by_time = filter_stats.excluded_by_time + 1
    end
    
    -- Tag filter
    if opts.tags and #opts.tags > 0 then
      local has_tag = false
      for _, tag in ipairs(opts.tags) do
        if vim.tbl_contains(item.tags, tag) then
          has_tag = true
          break
        end
      end
      if not has_tag then
        should_include = false
        exclude_reason = "tag"
      end
    end
    
    if should_include then
      table.insert(filtered, item)
      filter_stats.included = filter_stats.included + 1
    end
  end
  
  logger.log_function_return("manager", "filter_items", {
    filtered_count = #filtered,
    filter_stats = filter_stats
  })
  
  return filtered
end

function M.jump_to_qa(qa_item)
  local logger = get_logger()
  logger.log_function_call("manager", "jump_to_qa", {
    qa_item = qa_item and {
      buffer_line_start = qa_item.buffer_line_start,
      buffer_line_end = qa_item.buffer_line_end,
      bufnr = qa_item.metadata and qa_item.metadata.bufnr,
      question_preview = qa_item.question and qa_item.question:sub(1, 50)
    } or nil
  })
  
  if not qa_item or not qa_item.metadata or not qa_item.metadata.bufnr then
    logger.log_error_with_context("manager", "jump_to_qa", "Invalid QA item or missing buffer information", {
      qa_item = qa_item,
      has_metadata = qa_item and qa_item.metadata ~= nil,
      has_bufnr = qa_item and qa_item.metadata and qa_item.metadata.bufnr ~= nil
    })
    vim.notify("Invalid QA item or missing buffer information", vim.log.levels.ERROR)
    return false
  end
  
  local bufnr = qa_item.metadata.bufnr
  local line_num = qa_item.buffer_line_start
  
  logger.debug("Attempting to jump to buffer %d, line %d", bufnr, line_num)
  
  -- Validate buffer and line number
  if not vim.api.nvim_buf_is_valid(bufnr) then
    logger.log_error_with_context("manager", "jump_to_qa", "Target buffer is invalid", {
      bufnr = bufnr,
      line_num = line_num
    })
    vim.notify("Target buffer is no longer valid", vim.log.levels.ERROR)
    return false
  end
  
  local buf_lines = vim.api.nvim_buf_line_count(bufnr)
  if line_num > buf_lines then
    logger.log_error_with_context("manager", "jump_to_qa", "Line number out of range", {
      bufnr = bufnr,
      line_num = line_num,
      buf_lines = buf_lines
    })
    vim.notify(string.format("Line number %d is out of range (buffer has %d lines)", line_num, buf_lines), vim.log.levels.ERROR)
    return false
  end
  
  -- Jump to specified position
  local success = utils.jump_to_buffer_line(bufnr, line_num)
  
  if success then
    logger.debug("Successfully jumped to line %d", line_num)
    
    -- Highlight Q&A area
    local start_line = qa_item.buffer_line_start
    local end_line = qa_item.buffer_line_end
    
    if start_line and end_line then
      logger.debug("Highlighting lines %d to %d", start_line, end_line)
      utils.highlight_line_range(bufnr, start_line, end_line, 3000)
    end
    
    vim.notify(
      string.format("Jumped to Q&A at line %d", line_num),
      vim.log.levels.INFO
    )
    
    logger.log_function_return("manager", "jump_to_qa", {
      success = true,
      bufnr = bufnr,
      line_num = line_num
    })
    
    return true
  else
    logger.log_error_with_context("manager", "jump_to_qa", "Failed to jump to buffer line", {
      bufnr = bufnr,
      line_num = line_num
    })
    vim.notify("Failed to jump to the specified location", vim.log.levels.ERROR)
    return false
  end
end

function M.export_qa(qa_items, format, output_path)
  format = format or "markdown"
  
  if not qa_items or #qa_items == 0 then
    vim.notify("No Q&A items to export", vim.log.levels.WARN)
    return false
  end
  
  local content = M.format_qa_export(qa_items, format)
  
  if output_path then
    -- Save to file
    local file = io.open(output_path, "w")
    if file then
      file:write(content)
      file:close()
      return true, string.format("Successfully exported %d Q&A items to %s", #qa_items, output_path)
    else
      return false, "Failed to write export file: " .. output_path
    end
  else
    -- Copy to clipboard
    local success = pcall(function()
      vim.fn.setreg('+', content)
    end)
    if success then
      return true, string.format("Successfully copied %d Q&A items to clipboard", #qa_items)
    else
      return false, "Failed to copy to clipboard"
    end
  end
end

function M.format_qa_export(qa_items, format)
  local config = require('claude-fzf-history.config')
  local display_opts = config.get_display_opts()
  
  local lines = {}
  
  if format == "markdown" then
    table.insert(lines, "# Claude Conversation History")
    table.insert(lines, "")
    table.insert(lines, string.format("Exported: %s", os.date("%Y-%m-%d %H:%M:%S")))
    table.insert(lines, string.format("Total Q&A pairs: %d", #qa_items))
    table.insert(lines, "")
    
    for i, item in ipairs(qa_items) do
      local timestamp = utils.format_timestamp(item.timestamp, display_opts.date_format)
      
      table.insert(lines, string.format("## Q&A %d - %s", i, timestamp))
      table.insert(lines, "")
      table.insert(lines, "**Question:**")
      table.insert(lines, "")
      table.insert(lines, item.question)
      table.insert(lines, "")
      table.insert(lines, "**Answer:**")
      table.insert(lines, "")
      table.insert(lines, item.answer)
      table.insert(lines, "")
      table.insert(lines, "---")
      table.insert(lines, "")
    end
  elseif format == "plain" then
    for i, item in ipairs(qa_items) do
      local timestamp = utils.format_timestamp(item.timestamp, display_opts.date_format)
      
      table.insert(lines, string.format("=== Q&A %d - %s ===", i, timestamp))
      table.insert(lines, "")
      table.insert(lines, "Question:")
      table.insert(lines, item.question)
      table.insert(lines, "")
      table.insert(lines, "Answer:")
      table.insert(lines, item.answer)
      table.insert(lines, "")
    end
  end
  
  return table.concat(lines, "\n")
end

function M.refresh_cache()
  cache.items = {}
  cache.last_updated = 0
  cache.buffer_info = {}
end

function M.get_cache_info()
  return {
    item_count = #cache.items,
    last_updated = cache.last_updated,
    buffers = cache.buffer_info
  }
end

return M