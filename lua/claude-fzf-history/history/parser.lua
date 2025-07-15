local M = {}

-- Get logger instance
local function get_logger()
  local ok, logger = pcall(require, 'claude-fzf-history.logger')
  if ok then
    return logger
  end
  -- Return empty logger in case of loading failure
  return {
    debug = function() end,
    info = function() end,
    warn = function() end,
    error = function() end,
    trace = function() end,
  }
end

-- Simple utility functions to avoid dependency issues
local function trim(str)
  if not str then return "" end
  return str:gsub("^%s*(.-)%s*$", "%1")
end

local function split_lines(str)
  if not str then return {} end
  local lines = {}
  for line in str:gmatch("[^\r\n]+") do
    table.insert(lines, line)
  end
  return lines
end

-- Q&A item data structure
local function create_qa_item(question, answer, metadata)
  return {
    id = metadata.id or math.random(1000000),
    question = question or "",
    answer = answer or "",
    timestamp = metadata.timestamp or os.time(),
    buffer_line_start = metadata.buffer_line_start or 1,
    buffer_line_end = metadata.buffer_line_end or 1,
    context_lines = metadata.context_lines or 0,
    tags = metadata.tags or {},
    metadata = metadata.metadata or {}
  }
end

function M.detect_claude_buffer(bufnr)
  local logger = get_logger()
  
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    logger.warn("Invalid buffer number: %s", bufnr or "nil")
    return false, "Invalid buffer"
  end
  
  logger.debug("Detecting Claude buffer for bufnr: %d", bufnr)
  
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  local filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')
  
  -- Check filename and type characteristics
  local name_indicators = {
    'claude', 'terminal', 'term'
  }
  
  local has_name_indicator = false
  for _, indicator in ipairs(name_indicators) do
    if bufname:lower():match(indicator) then
      has_name_indicator = true
      break
    end
  end
  
  -- Terminal type buffers are more likely Claude sessions (including snacks_terminal)
  local is_terminal = filetype == 'term' or filetype == 'terminal' or filetype == 'snacks_terminal'
  
  -- Check buffer content (for large buffers, checking end content may be more useful)
  local total_lines = vim.api.nvim_buf_line_count(bufnr)
  local start_line = math.max(0, total_lines - 100)  -- Check last 100 lines
  local lines = vim.api.nvim_buf_get_lines(bufnr, start_line, -1, false)
  local content_score, has_claude_code = M.analyze_content_patterns(lines)
  
  -- Comprehensive judgment
  local confidence = 0
  if has_name_indicator then confidence = confidence + 30 end
  if is_terminal then confidence = confidence + 20 end
  confidence = confidence + content_score
  
  local is_claude_buffer = confidence >= 40  -- Lower threshold to adapt to more cases
  
  logger.debug("Claude buffer detection result: %s (confidence: %d)", 
    is_claude_buffer and "true" or "false", confidence)
  logger.trace("Detection details: name_indicator=%s, is_terminal=%s, content_score=%d", 
    has_name_indicator, is_terminal, content_score)
  
  return is_claude_buffer, {
    confidence = confidence,
    name_indicator = has_name_indicator,
    is_terminal = is_terminal,
    content_score = content_score,
    total_lines = #lines
  }
end

function M.analyze_content_patterns(lines)
  local score = 0
  local patterns = {
    question_patterns = {
      "^>%s+.+",           -- User input starting with >
      "^%s*@.+",           -- User input starting with @
      "^User:%s*.+",       -- Starting with User:
      "^⏺",                -- Claude Code command marker
    },
    answer_patterns = {
      "^Claude:%s*.+",     -- Claude responses starting with Claude:
      "^Assistant:%s*.+", -- Starting with Assistant:
      "^AI:%s*.+",         -- Starting with AI:
    },
    context_patterns = {
      "^%[%d+%-%d+%-%d+",  -- Timestamp format
      "^%-%-%- .+ %-%-%-%s*$", -- Separator line
      "^═══.+═══%s*$",     -- Another type of separator line
    },
    claude_code_patterns = {
      "Update%(.*%)",      -- Update(...) function call
      "Read%(.*%)",        -- Read(...) function call
      "Update Todos",       -- Update todos
    }
  }
  
  local has_claude_code = false
  
  for _, line in ipairs(lines) do
    -- Check Claude Code specific patterns
    if line:match("^⏺") then
      score = score + 30  -- Claude Code marker has high weight
      has_claude_code = true
    end
    
    -- Check Claude Code command patterns
    for _, pattern in ipairs(patterns.claude_code_patterns) do
      if line:match(pattern) then
        score = score + 10
        has_claude_code = true
        break
      end
    end
    
    -- Check question patterns
    for _, pattern in ipairs(patterns.question_patterns) do
      if line:match(pattern) then
        score = score + 15
        break
      end
    end
    
    -- Check answer patterns
    for _, pattern in ipairs(patterns.answer_patterns) do
      if line:match(pattern) then
        score = score + 20
        break
      end
    end
    
    -- Check context patterns
    for _, pattern in ipairs(patterns.context_patterns) do
      if line:match(pattern) then
        score = score + 5
        break
      end
    end
  end
  
  return math.min(score, 50), has_claude_code -- Return score and whether it's Claude Code format
end

function M.parse_claude_terminal(bufnr)
  local logger = get_logger()
  logger.log_function_call("parser", "parse_claude_terminal", {bufnr = bufnr})
  
  if not vim.api.nvim_buf_is_valid(bufnr) then
    logger.log_error_with_context("parser", "parse_claude_terminal", "Invalid buffer", {bufnr = bufnr})
    return nil, "Invalid buffer"
  end
  
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  logger.debug("Retrieved %d lines from buffer %d", #lines, bufnr)
  
  if #lines == 0 then
    logger.warn("Buffer %d is empty", bufnr)
    return {}, nil
  end
  
  -- Analyze content patterns
  local content_score, format_detected = M.analyze_content_patterns(lines)
  logger.debug("Content analysis: score=%d, format=%s", content_score, format_detected and "detected" or "not detected")
  
  local qa_items = {}
  
  if format_detected then
    logger.debug("Using Claude Code parser")
    qa_items = M.parse_claude_code_content(lines, bufnr)
  else
    logger.debug("Using legacy parser")
    qa_items = M.parse_legacy_format(lines, bufnr)
  end
  
  logger.log_function_return("parser", "parse_claude_terminal", {
    qa_items_count = #qa_items,
    format_used = format_detected and "claude_code" or "legacy",
    content_score = content_score
  })
  
  return qa_items, nil
end

function M.parse_content(content, bufnr)
  local lines = split_lines(content)
  
  -- Detect if it's Claude Code format
  local is_claude_code = false
  for _, line in ipairs(lines) do
    if line:match("^⏺") then
      is_claude_code = true
      break
    end
  end
  
  if is_claude_code then
    return M.parse_claude_code_content(lines, bufnr)
  else
    return M.parse_legacy_format(lines, bufnr)
  end
end

function M.parse_legacy_format(lines, bufnr)
  local ok, config = pcall(require, 'claude-fzf-history.config')
  local parser_opts
  
  if ok and config and config.get_parser_opts then
    parser_opts = config.get_parser_opts()
  end
  
  -- If config loading fails or no get_parser_opts function, use default options
  if not parser_opts then
    parser_opts = {
      patterns = {
        question_start = "^>%s*(.+)$",
        answer_start = "^Claude:",
        answer_continuation = "^%s*(.+)$",
      },
      ignore_patterns = {
        "^%s*$",
        "^%-%-%-+$",
        "^%[%d+%-%d+%-%d+",
      }
    }
  end
  
  local qa_items = {}
  local current_qa = nil
  local line_num = 1
  
  for i, line in ipairs(lines) do
    local trimmed_line = trim(line)
    
    -- Skip ignored patterns
    local should_ignore = false
    for _, pattern in ipairs(parser_opts.ignore_patterns) do
      if trimmed_line:match(pattern) then
        should_ignore = true
        break
      end
    end
    
    if not should_ignore and trimmed_line ~= "" then
      -- Detect question start
      local question_match = trimmed_line:match(parser_opts.patterns.question_start)
      if question_match then
        -- Save previous Q&A item
        if current_qa and current_qa.question ~= "" then
          current_qa.buffer_line_end = i - 1
          table.insert(qa_items, current_qa)
        end
        
        -- Start new Q&A item
        current_qa = {
          question = question_match,
          answer = "",
          buffer_line_start = i,
          buffer_line_end = i,
          bufnr = bufnr
        }
      -- Detect answer start
      elseif trimmed_line:match(parser_opts.patterns.answer_start) then
        if current_qa then
          -- Extract content after Claude:
          local answer_content = trimmed_line:gsub("^Claude:%s*", "")
          current_qa.answer = answer_content
        end
      -- Detect answer continuation
      elseif current_qa and current_qa.answer then
        local continuation_match = trimmed_line:match(parser_opts.patterns.answer_continuation)
        if continuation_match then
          if current_qa.answer == "" then
            current_qa.answer = continuation_match
          else
            current_qa.answer = current_qa.answer .. "\n" .. continuation_match
          end
        end
      end
    end
    
    line_num = line_num + 1
  end
  
  -- Save last Q&A item
  if current_qa and current_qa.question ~= "" then
    current_qa.buffer_line_end = #lines
    table.insert(qa_items, current_qa)
  end
  
  -- Convert to standard Q&A item format
  local result_items = {}
  for i, qa in ipairs(qa_items) do
    local metadata = {
      id = i,
      timestamp = os.time(),
      buffer_line_start = qa.buffer_line_start,
      buffer_line_end = qa.buffer_line_end,
      metadata = { bufnr = qa.bufnr }
    }
    
    local qa_item = create_qa_item(qa.question, qa.answer, metadata)
    table.insert(result_items, qa_item)
  end
  
  return result_items
end

function M.parse_claude_code_content(lines, bufnr)
  local logger = get_logger()
  logger.debug("Parsing Claude Code format with ⏺ and ⎿ markers")
  
  local qa_items = {}
  local current_question = ""
  local current_answer = ""
  local in_answer = false
  local in_box = false
  local box_content = {}
  local line_start = 0
  local in_system_reminder = false
  
  -- Improved state machine parsing, mimicking Python success logic
  for i, line in ipairs(lines) do
    local line_stripped = trim(line)
    
    -- Detect new user question - must start with > as first character
    if line:match("^>") then
      -- Save previous Q&A pair (but skip /ide questions)
      if current_question ~= "" and current_answer ~= "" then
        -- Check if this is an /ide question we should skip
        local should_skip = current_question:match("^/ide") or 
                           current_question:match("^%s*/ide")
        
        -- Also skip if the answer is just "Connected to Neovim."
        local trimmed_answer = trim(current_answer)
        if trimmed_answer:match("^⎿%s*Connected to Neovim%.?$") then
          should_skip = true
        end
        
        if not should_skip then
          local qa_item = create_qa_item(
            trim(current_question),
            trim(current_answer),
            {
              id = #qa_items + 1,
              timestamp = os.time() - ((#lines - i) * 10),
              buffer_line_start = line_start,
              buffer_line_end = i - 1,
              metadata = {
                bufnr = bufnr,
                format = "claude_code",
                interaction_type = "user_question"
              }
            }
          )
          table.insert(qa_items, qa_item)
        else
          logger.debug("Skipping /ide question at line %d", line_start)
        end
      end
      
      -- Start new Q&A pair
      current_question = line:gsub("^>%s*", "")
      current_answer = ""
      line_start = i + 1
      in_answer = true
      in_box = false
      box_content = {}
      in_system_reminder = false
      logger.debug("Found user question at line %d: %s", i, current_question:sub(1, 50))
      
    -- If in answer, collect all content
    elseif in_answer then
      -- Handle system reminder blocks
      if line:match("<system%-reminder>") then
        in_system_reminder = true
        goto continue
      elseif line:match("</system%-reminder>") then
        in_system_reminder = false
        goto continue
      elseif in_system_reminder then
        -- Skip all content within system reminder blocks
        goto continue
      
      -- Filter out IDE connection messages
      elseif line_stripped:match("^> /ide") and lines[i+1] and trim(lines[i+1]):match("^⎿%s+Connected to") then
        -- Skip IDE connection pattern (current and next line)
        goto continue
      elseif line_stripped:match("^⎿%s+Connected to") then
        -- Skip standalone connection messages
        goto continue
      
      -- Detect box start
      elseif line_stripped:match("^╭") then
        in_box = true
        box_content = {line}
        
      -- Detect box end
      elseif line_stripped:match("^╰") then
        in_box = false
        table.insert(box_content, line)
        -- Add entire box content to answer
        if current_answer ~= "" then
          current_answer = current_answer .. "\n"
        end
        current_answer = current_answer .. table.concat(box_content, "\n") .. "\n"
        box_content = {}
        
      -- If in box, collect box content
      elseif in_box then
        table.insert(box_content, line)
        
      -- Collect tool calls and output
      elseif line_stripped:match("^⏺") or 
             line_stripped:match("^⎿") or
             line_stripped:match("^│") or
             line_stripped:match("User approved") or
             line_stripped:match("User rejected") then
        if current_answer ~= "" then
          current_answer = current_answer .. "\n"
        end
        current_answer = current_answer .. line
        
      -- Collect normal answer content
      elseif line_stripped ~= "" then
        if current_answer ~= "" then
          current_answer = current_answer .. "\n"
        end
        current_answer = current_answer .. line
      end
    end
    
    ::continue::
  end
  
  -- Process last Q&A pair
  if current_question ~= "" and current_answer ~= "" then
    -- Check if this is an /ide question we should skip
    local should_skip = current_question:match("^/ide") or 
                       current_question:match("^%s*/ide")
    
    -- Also skip if the answer is just "Connected to Neovim."
    local trimmed_answer = trim(current_answer)
    if trimmed_answer:match("^⎿%s*Connected to Neovim%.?$") then
      should_skip = true
    end
    
    if not should_skip then
      local qa_item = create_qa_item(
        trim(current_question),
        trim(current_answer),
        {
          id = #qa_items + 1,
          timestamp = os.time(),
          buffer_line_start = line_start,
          buffer_line_end = #lines,
          metadata = {
            bufnr = bufnr,
            format = "claude_code",
            interaction_type = "final"
          }
        }
      )
      table.insert(qa_items, qa_item)
    else
      logger.debug("Skipping final /ide question")
    end
  end
  
  logger.info("Parsed %d Claude Code Q&A items with improved box content handling", #qa_items)
  return qa_items
end

-- Improved response text cleaning function - preserve important content
function M.clean_response_text(text)
  if not text then return "" end
  
  local lines = split_lines(text)
  local clean_lines = {}
  local in_code_block = false
  
  for _, line in ipairs(lines) do
    -- Detect code block
    if line:match("^```") then
      in_code_block = not in_code_block
      table.insert(clean_lines, line)
      goto continue
    end
    
    -- Inside code block, preserve all content
    if in_code_block then
      table.insert(clean_lines, line)
      goto continue
    end
    
    -- Preserve box content and tool call information
    if line:match("^╭") or line:match("^╰") or line:match("^│") or
       line:match("^⏺") or line:match("^⎿") or
       line:match("User approved") or line:match("User rejected") then
      table.insert(clean_lines, line)
      goto continue
    end
    
    -- Skip specific UI elements
    if line:match("ctrl%+r to expand") or 
       line:match("◯") or 
       line:match("^%s*%?%s*for shortcuts") then
      goto continue
    end
    
    -- Preserve other content
    table.insert(clean_lines, line)
    
    ::continue::
  end
  
  -- Merge results
  local result = table.concat(clean_lines, "\n")
  
  -- Remove excess blank lines but preserve structure
  result = result:gsub("\n\n\n+", "\n\n")
  
  -- For very long responses, perform intelligent truncation
  if #result > 5000 then
    -- Try to truncate at natural breakpoints
    local truncate_pos = result:find("\n\n", 4000) or 4000
    result = result:sub(1, truncate_pos) .. "\n\n[Content truncated - view full content in buffer]"
  end
  
  return trim(result)
end

function M.incremental_parse(bufnr, last_line)
  -- TODO: Implement incremental parsing to improve performance
  -- Temporarily use full parsing
  return M.parse_claude_terminal(bufnr)
end

return M