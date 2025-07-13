local M = {}

local utils = require('claude-fzf-history.utils')
local manager = require('claude-fzf-history.history.manager')

local function get_logger()
  return require('claude-fzf-history.logger')
end

function M.create_history_picker(history_items, opts)
  local logger = get_logger()
  logger.log_function_call("picker", "create_history_picker", {
    history_items_count = #history_items,
    opts = opts
  })
  
  logger.debug("=== Starting history picker creation ===")
  logger.debug("History items count: %d", #history_items)
  logger.debug("Opts: %s", vim.inspect(opts))
  
  opts = opts or {}
  
  local config = require('claude-fzf-history.config')
  local fzf_opts = config.get_fzf_opts()
  local display_opts = config.get_display_opts()
  local actions = config.get_actions()
  
  logger.debug("=== Configuration loading completed ===")
  logger.debug("FZF opts multi: %s", fzf_opts["--multi"] and "YES" or "NO")
  logger.debug("FZF opts preview-window: %s", fzf_opts["--preview-window"] or "NOT SET")
  
  logger.log_plugin_state("picker", {
    fzf_opts = fzf_opts,
    display_opts = display_opts,
    actions = actions
  })
  
  local ok, fzf_lua = pcall(require, 'fzf-lua')
  if not ok then
    logger.log_error_with_context("picker", "create_history_picker", "fzf-lua not found", {})
    vim.notify("fzf-lua is required for claude-fzf-history", vim.log.levels.ERROR)
    return
  end
  
  logger.debug("fzf-lua loaded successfully")
  
  -- Format history items for fzf display
  logger.debug("=== Starting data formatting ===")
  logger.debug("Input history_items count: %d", #history_items)
  logger.debug("Display options: %s", vim.inspect(display_opts))
  
  local formatted_items = M.format_items_for_display(history_items, display_opts)
  
  logger.debug("=== Formatting completed ===")
  logger.debug("Formatted %d items for display", #formatted_items)
  
  if #formatted_items > 0 then
    logger.debug("First formatted item: %s", formatted_items[1])
    if #formatted_items > 1 then
      logger.debug("Second formatted item: %s", formatted_items[2])
    end
  end
  
  -- Set key binding configuration (removed Ctrl-Y)
  local keymap = {
    fzf = {
      ["tab"] = "toggle",  -- Tab key for multi-select
      -- Removed Ctrl-Y preview function
    }
  }
  
  logger.debug("=== Key binding configuration ===")
  logger.debug("Manual keymap: %s", vim.inspect(keymap))
  
  -- Configure fzf options
  local fzf_config = vim.tbl_deep_extend('force', fzf_opts, {
    prompt = 'Claude History> ',
    header = 'Tab: Multi-select | Enter: Jump(single only) | Ctrl-E: Export | Ctrl-F: Filter | Esc: Exit',
    fzf_opts = {
      ["--multi"] = true,  -- Correct multi-select configuration
    },
    -- Important: pass keymap configuration
    keymap = keymap,
    
    -- Configure preview function
    fn_preview = function(selected, opts)
      logger.debug("=== FN_PREVIEW called ===")
      logger.debug("Selected parameter: %s", vim.inspect(selected))
      logger.debug("Selected type: %s", type(selected))
      logger.debug("Opts parameter: %s", vim.inspect(opts))
      
      if not selected or selected == "" then
        logger.debug("Selected is empty, returning empty string")
        return ""
      end
      
      logger.debug("Calling preview_qa_content with selected: %s", selected)
      local preview_result = M.preview_qa_content(selected, history_items, display_opts)
      logger.debug("Preview result length: %d", string.len(preview_result))
      logger.debug("Preview result preview (first 100 chars): %s", string.sub(preview_result, 1, 100))
      
      return preview_result
    end,
    
    -- keymap already set above
    
    -- Custom actions configured through actions
    actions = {
      ["default"] = function(selected)
        logger.debug("Default action triggered for: %s", selected)
        logger.debug("Selected items count: %d", #selected)
        
        -- Check if multi-select, prevent jump if multiple items selected
        if #selected > 1 then
          logger.debug("Multi-select prevents jump, selected items count: %d", #selected)
          vim.notify(
            string.format("Selected %d items, cannot jump.\nPlease use Ctrl-E to export or select only one item.", #selected),
            vim.log.levels.WARN,
            { title = "Claude History" }
          )
          return
        end
        
        M.handle_jump_action(selected, history_items)
      end,
      ["ctrl-e"] = function(selected)  -- Export function
        logger.debug("=== CTRL-E export function triggered ===")
        logger.debug("Selected items: %s", vim.inspect(selected))
        logger.debug("Export action triggered for: %s", selected)
        M.handle_export_action(selected, history_items)
      end,
      ["ctrl-f"] = function(selected)  -- Filter function
        logger.debug("=== CTRL-F filter function triggered ===")
        logger.debug("Filter action triggered")
        M.create_filters()
      end,
    }
  })
  
  logger.debug("=== FZF configuration preparation completed ===")
  logger.debug("Actions configured: %s", vim.inspect(vim.tbl_keys(fzf_config.actions)))
  logger.debug("Multi-select fzf_opts configured: %s", vim.inspect(fzf_config.fzf_opts))
  logger.debug("Preview function configured: %s", fzf_config.fn_preview and "YES" or "NO")
  logger.debug("Multi-select option: %s", fzf_config.fzf_opts and fzf_config.fzf_opts["--multi"] and "YES" or "NO")
  logger.debug("Preview window option: %s", fzf_config["--preview-window"] or "NOT SET")
  logger.debug("Winopts: %s", vim.inspect(fzf_config.winopts))
  logger.debug("Formatted items count: %d", #formatted_items)
  
  -- Print complete fzf_config for debugging
  logger.debug("=== Complete FZF configuration ===")
  logger.debug("Keymap in fzf_config: %s", vim.inspect(fzf_config.keymap))
  logger.debug("Full fzf_config: %s", vim.inspect(fzf_config))
  
  if #formatted_items > 0 then
    logger.debug("First formatted item: %s", formatted_items[1])
  end
  
  -- Safe call to fzf_exec
  logger.debug("=== Starting fzf_exec call ===")
  local success, error_msg = pcall(function()
    fzf_lua.fzf_exec(formatted_items, fzf_config)
  end)
  
  if success then
    logger.debug("=== fzf_exec call successful ===")
  else
    logger.debug("=== fzf_exec call failed ===")
  end
  
  if not success then
    logger.log_error_with_context("picker", "create_history_picker", "fzf_exec failed", {
      error = error_msg,
      formatted_items_count = #formatted_items
    })
    vim.notify("Failed to open picker: " .. error_msg, vim.log.levels.ERROR)
  else
    logger.debug("FZF picker opened successfully")
  end
  
  logger.log_function_return("picker", "create_history_picker", "completed")
end

function M.format_items_for_display(history_items, display_opts)
  local logger = get_logger()
  logger.log_function_call("picker", "format_items_for_display", {
    history_items_count = #history_items,
    display_opts = display_opts
  })
  
  local formatted = {}
  
  for i, item in ipairs(history_items) do
    local timestamp = ""
    if display_opts.show_timestamp then
      timestamp = string.format("[%s] ", 
        utils.format_timestamp(item.timestamp, display_opts.date_format))
    end
    
    local line_info = ""
    if display_opts.show_line_numbers and item.buffer_line_start then
      line_info = string.format("L%d ", item.buffer_line_start)
    end
    
    local question_text = utils.truncate_string(
      item.question, 
      display_opts.max_question_length
    )
    
    local formatted_line = string.format("%s%s%s", 
      timestamp, line_info, question_text)
    
    table.insert(formatted, formatted_line)
  end
  
  logger.debug("Formatted %d items for display", #formatted)
  logger.log_function_return("picker", "format_items_for_display", formatted)
  
  return formatted
end

function M.preview_qa_content(selected_line, history_items, display_opts)
  local logger = get_logger()
  logger.log_function_call("picker", "preview_qa_content", {
    selected_line = selected_line,
    history_items_count = #history_items
  })
  
  local index = M.find_item_index_from_line(selected_line, history_items, display_opts)
  if not index then
    logger.warn("Could not find item index for selected line: %s", selected_line)
    return "Cannot find corresponding Q&A item"
  end
  
  local item = history_items[index]
  if not item then
    logger.warn("Item not found at index: %d", index)
    return "Q&A item does not exist"
  end
  
  logger.debug("Previewing item at index %d", index)
  logger.log_function_return("picker", "preview_qa_content", "preview generated")
  
  local preview_lines = {}
  
  -- Add metadata
  local timestamp = utils.format_timestamp(item.timestamp, display_opts.date_format)
  table.insert(preview_lines, string.format("Time: %s", timestamp))
  
  if item.metadata.buffer_name then
    table.insert(preview_lines, string.format("Buffer: %s", item.metadata.buffer_name))
  end
  
  if item.buffer_line_start then
    table.insert(preview_lines, string.format("Location: Line %d-%d", 
      item.buffer_line_start, item.buffer_line_end or item.buffer_line_start))
  end
  
  table.insert(preview_lines, "")
  table.insert(preview_lines, "═══ Question ═══")
  
  -- Add question content
  local question_lines = utils.split_lines(item.question)
  for _, line in ipairs(question_lines) do
    table.insert(preview_lines, line)
  end
  
  table.insert(preview_lines, "")
  table.insert(preview_lines, "═══ Answer ═══")
  
  -- Add answer content
  local answer_lines = utils.split_lines(item.answer)
  for _, line in ipairs(answer_lines) do
    table.insert(preview_lines, line)
  end
  
  -- Add tag information
  if item.tags and #item.tags > 0 then
    table.insert(preview_lines, "")
    table.insert(preview_lines, string.format("Tags: %s", table.concat(item.tags, ", ")))
  end
  
  return table.concat(preview_lines, "\n")
end

function M.find_item_index_from_line(selected_line, history_items, display_opts)
  -- Extract original index from formatted display line
  -- Improved matching logic to better handle strings containing box-drawing content
  local logger = get_logger()
  
  local formatted_items = M.format_items_for_display(history_items, display_opts)
  
  -- Debug: log detailed information about selected line
  logger.debug("Looking for selected line: '%s'", selected_line)
  logger.debug("Selected line length: %d", #selected_line)
  
  -- 1. Exact match
  for i, formatted_line in ipairs(formatted_items) do
    if formatted_line == selected_line then
      logger.debug("Found exact match at index %d", i)
      return i
    end
  end
  
  -- 2. Match after cleaning whitespace
  logger.debug("Exact match failed, trying whitespace-normalized matching...")
  local normalized_selected = selected_line:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
  
  for i, formatted_line in ipairs(formatted_items) do
    local normalized_formatted = formatted_line:gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
    
    if normalized_selected == normalized_formatted then
      logger.debug("Found whitespace-normalized match at index %d", i)
      return i
    end
  end
  
  -- 3. Match based on timestamp and line number
  logger.debug("Whitespace matching failed, trying timestamp and line number matching...")
  local selected_prefix = selected_line:match("^%[.-%]%s+L%d+")
  
  if selected_prefix then
    for i, formatted_line in ipairs(formatted_items) do
      local formatted_prefix = formatted_line:match("^%[.-%]%s+L%d+")
      
      if formatted_prefix and selected_prefix == formatted_prefix then
        logger.debug("Found match based on timestamp and line number at index %d", i)
        return i
      end
    end
  end
  
  -- 4. Partial match based on question text
  logger.debug("Prefix matching failed, trying question text matching...")
  
  -- Extract question text part (remove timestamp and line number)
  local selected_question = selected_line:gsub("^%[.-%]%s*", ""):gsub("^L%d+%s*", "")
  
  for i, item in ipairs(history_items) do
    -- Get truncated version of original question text
    local truncated_question = utils.truncate_string(
      item.question, 
      display_opts.max_question_length
    )
    
    if selected_question == truncated_question then
      logger.debug("Found match based on question text at index %d", i)
      return i
    end
  end
  
  -- 5. Fuzzy match: prefix matching based on question text
  logger.debug("Question text matching failed, trying fuzzy prefix matching...")
  
  if #selected_question > 10 then
    local question_prefix = selected_question:sub(1, 10)
    
    for i, item in ipairs(history_items) do
      if item.question:sub(1, 10) == question_prefix then
        logger.debug("Found fuzzy match based on question prefix at index %d", i)
        return i
      end
    end
  end
  
  -- 6. Last attempt: match based on string similarity
  logger.debug("All matching attempts failed, trying similarity matching...")
  
  local best_match_index = nil
  local best_similarity = 0
  
  for i, formatted_line in ipairs(formatted_items) do
    local similarity = M.calculate_string_similarity(selected_line, formatted_line)
    
    if similarity > best_similarity and similarity > 0.8 then
      best_similarity = similarity
      best_match_index = i
    end
  end
  
  if best_match_index then
    logger.debug("Found similarity-based match at index %d with similarity %.2f", best_match_index, best_similarity)
    return best_match_index
  end
  
  logger.warn("No match found for selected line after all attempts")
  logger.debug("Available formatted lines:")
  for i, formatted_line in ipairs(formatted_items) do
    logger.debug("  %d: '%s'", i, formatted_line)
  end
  
  return nil
end

-- Helper function to calculate string similarity
function M.calculate_string_similarity(str1, str2)
  if not str1 or not str2 then return 0 end
  if str1 == str2 then return 1 end
  
  local len1, len2 = #str1, #str2
  local max_len = math.max(len1, len2)
  
  if max_len == 0 then return 1 end
  
  -- Simplified version of Levenshtein distance calculation
  local common_chars = 0
  local min_len = math.min(len1, len2)
  
  for i = 1, min_len do
    if str1:byte(i) == str2:byte(i) then
      common_chars = common_chars + 1
    else
      break
    end
  end
  
  return common_chars / max_len
end

function M.handle_jump_action(selected, history_items)
  local logger = get_logger()
  logger.log_function_call("picker", "handle_jump_action", {
    selected_count = selected and #selected or 0,
    history_items_count = #history_items
  })
  
  if not selected or #selected == 0 then
    logger.warn("No items selected for jump action")
    return
  end
  
  local config = require('claude-fzf-history.config')
  local display_opts = config.get_display_opts()
  
  local jump_results = {
    attempted = 0,
    successful = 0,
    failed = 0
  }
  
  for i, selected_line in ipairs(selected) do
    jump_results.attempted = jump_results.attempted + 1
    
    logger.debug("Processing selected item %d/%d: %s", i, #selected, selected_line)
    
    local index = M.find_item_index_from_line(selected_line, history_items, display_opts)
    
    if index then
      local item = history_items[index]
      logger.debug("Found item at index %d: question='%s'", index, item.question and item.question:sub(1, 50) or "")
      
      local success = manager.jump_to_qa(item)
      
      if success then
        jump_results.successful = jump_results.successful + 1
        logger.debug("Successfully jumped to item %d", index)
      else
        jump_results.failed = jump_results.failed + 1
        logger.warn("Failed to jump to item %d", index)
      end
    else
      jump_results.failed = jump_results.failed + 1
      logger.warn("Could not find item index for selected line: %s", selected_line)
    end
  end
  
  logger.log_function_return("picker", "handle_jump_action", jump_results)
  
  -- Display result summary
  if jump_results.attempted > 1 then
    if jump_results.successful > 0 then
      vim.notify(string.format("Jumped to %d/%d items successfully", jump_results.successful, jump_results.attempted), vim.log.levels.INFO)
    else
      vim.notify("Failed to jump to any selected items", vim.log.levels.ERROR)
    end
  end
end



-- Create a beautiful export input dialog
function M.create_export_dialog(selected_items, callback)
  local buf = vim.api.nvim_create_buf(false, true)
  
  -- Store the original window and mode to restore later
  local original_win = vim.api.nvim_get_current_win()
  local original_mode = vim.api.nvim_get_mode().mode
  
  -- Get screen dimensions for absolute centering
  local screen_width = vim.o.columns
  local screen_height = vim.o.lines
  
  -- Calculate dialog dimensions (fixed size, always centered on screen)
  local dialog_width = math.min(60, math.floor(screen_width * 0.6))
  local dialog_height = 8
  local row = math.floor((screen_height - dialog_height) / 2)
  local col = math.floor((screen_width - dialog_width) / 2)
  
  -- Create header content
  local timestamp = os.date("%Y%m%d_%H%M%S")
  local default_filename = string.format("claude_history_%s.md", timestamp)
  
  -- Helper function to pad text to fit dialog width
  local function pad_text(text, width)
    local padding = width - 2 - vim.fn.strdisplaywidth(text)
    return "│" .. text .. string.rep(" ", math.max(0, padding)) .. "│"
  end
  
  local title_text = string.format(" 📤 Export %d Q&A Items", #selected_items)
  local save_text = " 💾 Save to file: Enter filename below"
  local copy_text = " 📋 Copy to clipboard: Leave empty and press Enter"
  local cancel_text = " ❌ Cancel: Press Esc"
  
  local header_lines = {
    "┌" .. string.rep("─", dialog_width - 2) .. "┐",
    pad_text(title_text, dialog_width),
    "├" .. string.rep("─", dialog_width - 2) .. "┤",
    pad_text(save_text, dialog_width),
    pad_text(copy_text, dialog_width),
    pad_text(cancel_text, dialog_width),
    "├" .. string.rep("─", dialog_width - 2) .. "┤",
    "└" .. string.rep("─", dialog_width - 2) .. "┘"
  }
  
  -- Set buffer content
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, header_lines)
  
  -- Create floating window (relative to editor, always screen centered)
  local opts = {
    relative = 'editor',
    width = dialog_width,
    height = dialog_height,
    row = row,
    col = col,
    style = 'minimal',
    border = 'none',
    zindex = 100
  }
  
  local dialog_win = vim.api.nvim_open_win(buf, false, opts)
  
  -- Set window options for better appearance
  vim.api.nvim_win_set_option(dialog_win, 'winhl', 'Normal:Normal,FloatBorder:FloatBorder')
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  
  -- Create input field
  local input_buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(input_buf, 0, -1, false, {default_filename})
  
  local input_opts = {
    relative = 'editor',
    width = dialog_width - 4,
    height = 1,
    row = row + dialog_height - 2,
    col = col + 2,
    style = 'minimal',
    border = 'none',
    zindex = 101
  }
  
  local input_win = vim.api.nvim_open_win(input_buf, true, input_opts)
  vim.api.nvim_win_set_option(input_win, 'winhl', 'Normal:PmenuSel,FloatBorder:FloatBorder')
  
  -- Set cursor to end of filename (before extension)
  local filename_base = default_filename:match("(.+)%.md$") or default_filename
  vim.api.nvim_win_set_cursor(input_win, {1, #filename_base})
  
  -- Enter insert mode
  vim.cmd('startinsert!')
  
  -- Set up keymaps
  local function close_dialog()
    -- Close dialog windows
    if vim.api.nvim_win_is_valid(dialog_win) then
      vim.api.nvim_win_close(dialog_win, true)
    end
    if vim.api.nvim_win_is_valid(input_win) then
      vim.api.nvim_win_close(input_win, true)
    end
    
    -- Restore original window and ensure normal mode
    vim.schedule(function()
      if vim.api.nvim_win_is_valid(original_win) then
        vim.api.nvim_set_current_win(original_win)
      end
      
      -- Force exit from any insert/visual mode to prevent mode contamination
      -- This prevents the insert mode issue when closing dialog
      vim.cmd('stopinsert')
      
      -- Ensure we are truly in normal mode by checking and correcting
      local current_mode = vim.api.nvim_get_mode().mode
      if current_mode ~= 'n' then
        -- Force normal mode with ESC key simulation
        vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes('<Esc>', true, true, true), 'n', true)
      end
    end)
  end
  
  local function submit()
    local input_text = vim.api.nvim_buf_get_lines(input_buf, 0, 1, false)[1] or ""
    close_dialog()
    
    -- Use vim.schedule to ensure callback runs after mode restoration
    vim.schedule(function()
      callback(input_text)
    end)
  end
  
  -- Key mappings for input buffer
  local keymaps = {
    ['<CR>'] = submit,
    ['<Esc>'] = close_dialog,
    ['<C-c>'] = close_dialog,
  }
  
  for key, func in pairs(keymaps) do
    vim.api.nvim_buf_set_keymap(input_buf, 'i', key, '', {
      callback = func,
      noremap = true,
      silent = true
    })
    vim.api.nvim_buf_set_keymap(input_buf, 'n', key, '', {
      callback = func,
      noremap = true,
      silent = true
    })
  end
  
  -- Auto-close on focus lost
  vim.api.nvim_create_autocmd({'BufLeave', 'WinLeave'}, {
    buffer = input_buf,
    once = true,
    callback = close_dialog
  })
end

function M.handle_export_action(selected, history_items)
  if not selected or #selected == 0 then
    return
  end
  
  local config = require('claude-fzf-history.config')
  local display_opts = config.get_display_opts()
  
  local selected_items = {}
  for _, selected_line in ipairs(selected) do
    local index = M.find_item_index_from_line(selected_line, history_items, display_opts)
    if index then
      table.insert(selected_items, history_items[index])
    end
  end
  
  if #selected_items > 0 then
    -- Use beautiful export dialog
    M.create_export_dialog(selected_items, function(input)
      local success, message
      if input == "" then
        success, message = manager.export_qa(selected_items, "markdown") -- Copy to clipboard
        if success then
          vim.notify(
            string.format("📋 %s", message),
            vim.log.levels.INFO,
            { title = "Claude History Export" }
          )
        else
          vim.notify(
            string.format("❌ %s", message),
            vim.log.levels.ERROR,
            { title = "Claude History Export" }
          )
        end
      else
        success, message = manager.export_qa(selected_items, "markdown", input) -- Save to file
        if success then
          vim.notify(
            string.format("💾 %s", message),
            vim.log.levels.INFO,
            { title = "Claude History Export" }
          )
        else
          vim.notify(
            string.format("❌ %s", message),
            vim.log.levels.ERROR,
            { title = "Claude History Export" }
          )
        end
      end
    end)
  end
end

function M.create_filters()
  local config = require('claude-fzf-history.config')
  local actions = config.get_actions()
  
  local ok, fzf_lua = pcall(require, 'fzf-lua')
  if not ok then
    vim.notify("fzf-lua is required for search filters", vim.log.levels.ERROR)
    return
  end
  
  local filter_options = {
    "Search keywords",
    "Filter by time range",
    "Clear all filters"
  }
  
  fzf_lua.fzf_exec(filter_options, {
    prompt = "Select filter type> ",
    header = "Choose the filter type to apply",
    actions = {
      ["default"] = function(selected)
        M.handle_filter_selection(selected[1])
      end
    }
  })
end

function M.handle_filter_selection(filter_type)
  if filter_type == "Search keywords" then
    M.create_keyword_search()
  elseif filter_type == "Filter by time range" then
    M.create_time_filter()
  elseif filter_type == "Clear all filters" then
    M.clear_filters()
  end
end

function M.create_keyword_search()
  vim.ui.input({
    prompt = "Enter search keywords: ",
  }, function(input)
    if input and input ~= "" then
      -- Reopen history picker with keyword filter applied
      local manager = require('claude-fzf-history.history.manager')
      local history_items = manager.get_history({ search_term = input })
      M.create_history_picker(history_items, { search_term = input })
    end
  end)
end

function M.create_time_filter()
  local time_options = {
    "Last 1 hour",
    "Last 24 hours", 
    "Last week",
    "Last month",
    "Custom time range"
  }
  
  local ok, fzf_lua = pcall(require, 'fzf-lua')
  if not ok then return end
  
  fzf_lua.fzf_exec(time_options, {
    prompt = "Select time range> ",
    actions = {
      ["default"] = function(selected)
        M.apply_time_filter(selected[1])
      end
    }
  })
end

function M.apply_time_filter(time_option)
  local current_time = os.time()
  local start_time
  
  if time_option == "Last 1 hour" then
    start_time = current_time - 3600
  elseif time_option == "Last 24 hours" then
    start_time = current_time - 86400
  elseif time_option == "Last week" then
    start_time = current_time - 604800
  elseif time_option == "Last month" then
    start_time = current_time - 2592000
  elseif time_option == "Custom time range" then
    M.create_custom_time_filter()
    return
  end
  
  local manager = require('claude-fzf-history.history.manager')
  local history_items = manager.get_history({ start_time = start_time })
  M.create_history_picker(history_items, { start_time = start_time })
end

function M.create_custom_time_filter()
  vim.ui.input({
    prompt = "Start time (YYYY-MM-DD HH:MM): ",
  }, function(start_input)
    if not start_input or start_input == "" then return end
    
    vim.ui.input({
      prompt = "End time (YYYY-MM-DD HH:MM): ",
    }, function(end_input)
      if not end_input or end_input == "" then return end
      
      -- Simple time parsing (should use more robust time library in production)
      local start_time = M.parse_time_string(start_input)
      local end_time = M.parse_time_string(end_input)
      
      if start_time and end_time then
        local manager = require('claude-fzf-history.history.manager')
        local history_items = manager.get_history({ 
          start_time = start_time, 
          end_time = end_time 
        })
        M.create_history_picker(history_items, { 
          start_time = start_time, 
          end_time = end_time 
        })
      else
        vim.notify("Invalid time format, please use YYYY-MM-DD HH:MM format", vim.log.levels.ERROR)
      end
    end)
  end)
end

function M.parse_time_string(time_str)
  -- Simple time parsing implementation
  local year, month, day, hour, min = time_str:match("(%d+)-(%d+)-(%d+) (%d+):(%d+)")
  if year and month and day and hour and min then
    return os.time({
      year = tonumber(year),
      month = tonumber(month),
      day = tonumber(day),
      hour = tonumber(hour),
      min = tonumber(min),
      sec = 0
    })
  end
  return nil
end



function M.clear_filters()
  local manager = require('claude-fzf-history.history.manager')
  local history_items = manager.get_history({ force_refresh = true })
  M.create_history_picker(history_items, {})
  vim.notify("All filters cleared", vim.log.levels.INFO)
end



return M