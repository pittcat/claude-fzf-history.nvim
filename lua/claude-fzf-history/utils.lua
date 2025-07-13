local M = {}

local function get_logger()
  return require('claude-fzf-history.logger')
end

function M.trim(str)
  if not str then return "" end
  return str:gsub("^%s*(.-)%s*$", "%1")
end

function M.split_lines(str)
  if not str then return {} end
  local lines = {}
  for line in str:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end
  return lines
end

function M.truncate_string(str, max_length)
  if not str then return "" end
  if #str <= max_length then
    return str
  end
  
  -- Safely truncate string, avoiding truncation in the middle of multi-byte characters
  local ellipsis = "..."
  local target_length = max_length - #ellipsis
  
  -- Search forward from target position to find a safe truncation point
  local safe_pos = target_length
  
  -- Search backward to find a position that won't break multi-byte characters
  while safe_pos > 1 do
    local byte = str:byte(safe_pos)
    -- If this is a continuation byte of a multi-byte character (0x80-0xBF), continue searching forward
    if byte and byte >= 0x80 and byte <= 0xBF then
      safe_pos = safe_pos - 1
    else
      break
    end
  end
  
  -- Ensure we don't truncate to an empty string
  if safe_pos < 1 then
    safe_pos = 1
  end
  
  local truncated = str:sub(1, safe_pos)
  
  -- Verify again if the truncated string is valid
  -- If the last character is an incomplete multi-byte character, adjust again
  local last_byte = truncated:byte(-1)
  if last_byte and last_byte >= 0xC0 then
    -- This is a start byte of a multi-byte character, but may be incomplete
    truncated = truncated:sub(1, -2)
  end
  
  return truncated .. ellipsis
end

function M.format_timestamp(timestamp, format)
  if not timestamp then return "" end
  format = format or "%Y-%m-%d %H:%M"
  return os.date(format, timestamp)
end

function M.escape_pattern(str)
  if not str then return "" end
  return str:gsub("([%^%$%(%)%%%.%[%]%*%+%-%?])", "%%%1")
end

function M.find_claude_buffers()
  local logger = get_logger()
  logger.log_function_call("utils", "find_claude_buffers", {})
  
  local claude_buffers = {}
  local all_buffers = vim.api.nvim_list_bufs()
  
  logger.debug("Scanning %d total buffers for Claude content", #all_buffers)
  
  local scan_stats = {
    total_buffers = #all_buffers,
    loaded_buffers = 0,
    buffers_with_claude_names = 0,
    buffers_with_claude_content = 0,
    final_claude_buffers = 0
  }
  
  for i, bufnr in ipairs(all_buffers) do
    logger.debug("Checking buffer %d/%d (bufnr=%d)", i, #all_buffers, bufnr)
    
    if vim.api.nvim_buf_is_loaded(bufnr) then
      scan_stats.loaded_buffers = scan_stats.loaded_buffers + 1
      
      local bufname = vim.api.nvim_buf_get_name(bufnr)
      local filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')
      
      logger.debug("Buffer %d: name='%s', filetype='%s'", bufnr, bufname, filetype)
      
      -- Detect characteristics of Claude terminal buffer
      local matches_name_pattern = filetype == 'term' or 
                                   bufname:match('claude') or 
                                   bufname:match('terminal')
      
      if matches_name_pattern then
        scan_stats.buffers_with_claude_names = scan_stats.buffers_with_claude_names + 1
        logger.debug("Buffer %d matches name pattern", bufnr)
        
        -- Further validate buffer content
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 100, false)
        local has_claude_content = false
        
        logger.debug("Scanning first 100 lines of buffer %d for Claude content", bufnr)
        
        for line_num, line in ipairs(lines) do
          if line:match('^>%s') or line:match('^Claude:') or line:match('^⏺') then
            has_claude_content = true
            logger.debug("Found Claude content in buffer %d at line %d: '%s'", 
              bufnr, line_num, line:sub(1, 50))
            break
          end
        end
        
        if has_claude_content then
          scan_stats.buffers_with_claude_content = scan_stats.buffers_with_claude_content + 1
          scan_stats.final_claude_buffers = scan_stats.final_claude_buffers + 1
          
          local buffer_info = {
            bufnr = bufnr,
            name = bufname,
            filetype = filetype
          }
          
          table.insert(claude_buffers, buffer_info)
          logger.debug("Added Claude buffer: %s", vim.inspect(buffer_info))
        else
          logger.debug("Buffer %d matches name pattern but has no Claude content", bufnr)
        end
      else
        logger.debug("Buffer %d does not match name pattern", bufnr)
      end
    else
      logger.debug("Buffer %d is not loaded, skipping", bufnr)
    end
  end
  
  logger.log_function_return("utils", "find_claude_buffers", {
    found_buffers = #claude_buffers,
    scan_stats = scan_stats
  })
  
  return claude_buffers
end

function M.get_buffer_content(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return nil
  end
  
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  return table.concat(lines, '\n')
end

function M.jump_to_buffer_line(bufnr, line_num)
  local logger = get_logger()
  logger.log_function_call("utils", "jump_to_buffer_line", {
    bufnr = bufnr,
    line_num = line_num
  })
  
  if not vim.api.nvim_buf_is_valid(bufnr) then
    logger.log_error_with_context("utils", "jump_to_buffer_line", "Invalid buffer", {bufnr = bufnr})
    return false
  end
  
  -- Get buffer information
  local buf_name = vim.api.nvim_buf_get_name(bufnr)
  local buf_filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')
  local is_terminal = buf_filetype == 'terminal' or buf_filetype == 'snacks_terminal' or buf_name:match('^term://')
  
  logger.debug("Buffer info: name='%s', filetype='%s', is_terminal=%s", buf_name, buf_filetype, tostring(is_terminal))
  
  -- Find window containing this buffer
  local win_id = nil
  for _, winid in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_buf(winid) == bufnr then
      win_id = winid
      break
    end
  end
  
  -- If no window found, open buffer in current window
  if not win_id then
    logger.debug("No window found for buffer, opening in current window")
    vim.api.nvim_set_current_buf(bufnr)
    win_id = vim.api.nvim_get_current_win()
  else
    logger.debug("Found existing window %d for buffer", win_id)
    vim.api.nvim_set_current_win(win_id)
  end
  
  -- Jump to specified line
  local success, err = pcall(function()
    vim.api.nvim_win_set_cursor(win_id, {line_num, 0})
  end)
  
  if not success then
    logger.log_error_with_context("utils", "jump_to_buffer_line", "Failed to set cursor", {
      error = err,
      bufnr = bufnr,
      line_num = line_num,
      win_id = win_id
    })
    return false
  end
  
  logger.debug("Successfully set cursor to line %d", line_num)
  
  -- Center display - only execute in non-terminal mode
  if not is_terminal then
    local center_success, center_err = pcall(function()
      vim.cmd('normal! zz')
    end)
    
    if not center_success then
      logger.warn("Failed to center view: %s", center_err)
      -- Not a fatal error, continue execution
    else
      logger.debug("Successfully centered view")
    end
  else
    logger.debug("Skipping center view for terminal buffer")
  end
  
  logger.log_function_return("utils", "jump_to_buffer_line", {
    success = true,
    is_terminal = is_terminal,
    final_line = line_num
  })
  
  return true
end

function M.highlight_line_range(bufnr, start_line, end_line, duration)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  
  duration = duration or 2000
  
  local ns_id = vim.api.nvim_create_namespace('claude_history_highlight')
  
  -- Add highlighting
  for line = start_line, end_line do
    vim.api.nvim_buf_add_highlight(bufnr, ns_id, 'Search', line - 1, 0, -1)
  end
  
  -- Clear highlighting after delay
  vim.defer_fn(function()
    if vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
    end
  end, duration)
end

return M