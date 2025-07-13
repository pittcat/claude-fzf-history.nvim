local M = {}

function M.setup()
  -- Create user commands
  vim.api.nvim_create_user_command('ClaudeHistory', function(args)
    require('claude-fzf-history').history(args.fargs)
  end, {
    nargs = '*',
    desc = 'Open Claude conversation history picker'
  })
  
  -- Debug related commands
  vim.api.nvim_create_user_command('ClaudeHistoryDebug', function(args)
    M.handle_debug_command(args.fargs)
  end, {
    nargs = '*',
    complete = function()
      return { 'enable', 'disable', 'status', 'log', 'clear', 'export', 'buffer' }
    end,
    desc = 'Debug commands for Claude History'
  })
  
  -- Set shortcuts
  local config = require('claude-fzf-history.config')
  local keymaps = config.get().keymaps
  
  if keymaps.history then
    vim.keymap.set('n', keymaps.history, function()
      require('claude-fzf-history').history()
    end, { desc = 'Open Claude history' })
  end
end

function M.handle_debug_command(args)
  local logger = require('claude-fzf-history.logger')
  local config = require('claude-fzf-history.config')
  
  local command = args[1] or 'status'
  
  if command == 'enable' then
    config.enable_debug()
    logger.log_system_info()
    print("🐛 Debug mode enabled. Log file: " .. logger.get_log_file())
    
  elseif command == 'disable' then
    config.disable_debug()
    print("✅ Debug mode disabled")
    
  elseif command == 'status' then
    logger.show_stats()
    
  elseif command == 'log' then
    logger.open_log_file()
    
  elseif command == 'clear' then
    logger.clear_log_file()
    print("🗑️  Log file cleared")
    
  elseif command == 'export' then
    local debug_info = logger.export_debug_info()
    local export_content = vim.inspect(debug_info)
    
    -- Copy to clipboard
    vim.fn.setreg('+', export_content)
    print("📋 Debug info copied to clipboard")
    
  elseif command == 'buffer' then
    local bufnr = vim.api.nvim_get_current_buf()
    logger.log_buffer_info(bufnr)
    
    -- Additional buffer detection information
    local parser = require('claude-fzf-history.history.parser')
    local is_claude, info = parser.detect_claude_buffer(bufnr)
    
    logger.debug("Buffer detection result: %s", vim.inspect({
      is_claude_buffer = is_claude,
      detection_info = info
    }))
    
    print(string.format("🔍 Buffer analysis logged (Claude buffer: %s)", 
      is_claude and "Yes" or "No"))
    
  else
    print("❌ Unknown debug command: " .. command)
    print("Available commands: enable, disable, status, log, clear, export, buffer")
  end
end

return M