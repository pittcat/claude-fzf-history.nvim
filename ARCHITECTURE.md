# Architecture Design Document

## Overview

`claude-fzf-history.nvim` is a Neovim plugin designed with a modular architecture that provides intelligent browsing and navigation of Claude AI terminal conversation history. The plugin integrates with fzf-lua to offer a powerful interface for searching, filtering, and jumping to specific conversations.

## System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    User Interface Layer                     │
├─────────────────────────────────────────────────────────────┤
│  Neovim Commands  │  Key Bindings  │  FZF-lua Interface   │
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                     Core Plugin Layer                      │
├─────────────────────────────────────────────────────────────┤
│    init.lua       │   config.lua   │   commands.lua       │
│   (Entry Point)   │ (Configuration)│  (Vim Commands)      │
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                    Business Logic Layer                    │
├─────────────────────────────────────────────────────────────┤
│   history/        │   logger.lua   │   utils.lua          │
│   ├─ parser.lua   │  (Logging)     │  (Utilities)        │
│   ├─ picker.lua   │                │                      │
│   ├─ manager.lua  │   preview.lua  │                      │
│   └─ init.lua     │  (Preview)     │                      │
└─────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────┐
│                  External Dependencies                     │
├─────────────────────────────────────────────────────────────┤
│    fzf-lua        │    Neovim API  │  System Clipboard   │
│   (FZF Interface) │   (Buffers)    │   (Export)          │
│                   │                │                      │
│       bat         │                │                      │
│  (Syntax Highlight)│                │                      │
└─────────────────────────────────────────────────────────────┘
```

## Module Structure

### 1. Entry Point (`lua/claude-fzf-history/init.lua`)

**Responsibilities:**
- Plugin initialization and setup
- Public API exposure
- Module coordination

**Key Functions:**
- `setup(opts)`: Initialize plugin with user configuration
- `show_history()`: Main entry point for history picker
- `debug_mode(action)`: Debug mode control

**Dependencies:**
- `config`: Configuration management
- `commands`: Vim command registration
- `history`: Core history functionality

### 2. Configuration Management (`lua/claude-fzf-history/config.lua`)

**Responsibilities:**
- Default configuration definition
- User configuration merging
- Configuration validation
- Logging system initialization

**Key Data Structures:**
```lua
M.defaults = {
  history = { max_items, min_item_length, cache_timeout, auto_refresh },
  display = { max_question_length, show_timestamp, show_line_numbers, date_format },
  preview = { enabled, hidden, position, wrap, toggle_key, scroll_up, scroll_down, type, syntax_highlighting },
  fzf_opts = { fzf specific options },
  keymap = { fzf key bindings },
  logging = { level, file_logging, console_logging },
  parser = { patterns, ignore_patterns },
  actions = { key action mappings }
}
```

### 3. Command Interface (`lua/claude-fzf-history/commands.lua`)

**Responsibilities:**
- Vim command registration
- Command argument parsing
- Debug command handling

**Commands:**
- `:ClaudeHistory`: Main history picker command
- `:ClaudeHistoryDebug <action>`: Debug mode commands
  - `enable/disable`: Toggle debug mode
  - `status`: Show debug status
  - `log`: Open log file
  - `buffer`: Analyze current buffer
  - `export`: Export debug info to clipboard
  - `clear`: Clear log file

### 4. History Module (`lua/claude-fzf-history/history/`)

#### 4.1 Parser (`history/parser.lua`)

**Responsibilities:**
- Claude terminal buffer detection
- Conversation content parsing
- Q&A pair extraction
- Content validation

**Key Functions:**
- `find_claude_buffers()`: Detect Claude terminal buffers
- `parse_buffer(bufnr)`: Parse conversation content from buffer
- `extract_qa_pairs(lines)`: Extract Q&A pairs from text

**Algorithm:**
```
1. Scan all open buffers
2. Identify Claude terminal buffers by content patterns
3. Extract text lines from buffers
4. Parse lines using regex patterns:
   - Question pattern: "^>%s*(.+)$"
   - Answer pattern: "^Claude:"
5. Group lines into Q&A pairs
6. Validate and filter based on length requirements
7. Add metadata (timestamps, buffer info, line numbers)
```

#### 4.2 Picker (`history/picker.lua`)

**Responsibilities:**
- FZF-lua interface creation
- Item formatting for display
- Key binding configuration
- Action handling

**Key Functions:**
- `create_history_picker(history_items, opts)`: Main picker creation
- `format_items_for_display(items, display_opts)`: Format items for FZF
- `preview_qa_content(selected, history_items, display_opts)`: Preview generation
- `handle_jump_action(selected, history_items)`: Jump action handler
- `handle_export_action(selected, history_items)`: Export action handler
- `create_preview_handler(items, opts)`: Preview window handler
- `toggle_preview()`: Toggle preview visibility

**Display Format:**
```
[YYYY-MM-DD HH:MM] L{line_number} {truncated_question}...
```

#### 4.3 Manager (`history/manager.lua`)

**Responsibilities:**
- Terminal navigation
- Content export
- Cache management
- File operations

**Key Functions:**
- `jump_to_item(item)`: Navigate to conversation location
- `export_to_markdown(items, output_file)`: Export conversations
- `get_cache_key(bufnr)`: Cache key generation
- `validate_qa_item(item)`: Item validation

### 5. Logging System (`lua/claude-fzf-history/logger.lua`)

**Responsibilities:**
- Multi-level logging (TRACE, DEBUG, INFO, WARN, ERROR)
- File and console output
- Performance monitoring
- Debug information collection

**Features:**
- Configurable log levels
- File rotation (implicit via Neovim)
- Caller information tracking
- Timestamp formatting

### 6. Preview System (`lua/claude-fzf-history/preview.lua`)

**Responsibilities:**
- Preview content generation
- Syntax highlighting with bat integration
- Preview window management
- Fallback to plain text when bat unavailable

**Key Functions:**
- `create_preview_content(item, opts)`: Generate preview content
- `apply_syntax_highlighting(content, language)`: Apply bat highlighting
- `handle_preview_toggle()`: Toggle preview visibility

### 7. Utilities (`lua/claude-fzf-history/utils.lua`)

**Responsibilities:**
- Common utility functions
- String manipulation
- File system operations
- Helper functions

## Data Flow

### 1. Initialization Flow

```
User calls setup() 
    ↓
config.setup() merges user config with defaults
    ↓
logger.setup() initializes logging system
    ↓
commands.setup() registers Vim commands
    ↓
Plugin ready for use
```

### 2. History Picker Flow

```
User triggers :ClaudeHistory
    ↓
init.show_history() called
    ↓
parser.find_claude_buffers() discovers terminals
    ↓
parser.parse_buffer() extracts Q&A pairs
    ↓
picker.format_items_for_display() formats for FZF
    ↓
picker.create_history_picker() opens FZF interface
    ↓
User interaction (selection/actions)
    ↓
Action handlers (jump/export) execute
```

### 3. Jump Action Flow

```
User selects item and presses Enter
    ↓
picker.handle_jump_action() validates selection
    ↓
Check if single selection (multi-select blocked)
    ↓
manager.jump_to_item() navigates to buffer
    ↓
vim.api.nvim_set_current_buf() switches buffer
    ↓
vim.api.nvim_win_set_cursor() positions cursor
```

### 4. Export Action Flow

```
User selects items and presses Ctrl-E
    ↓
picker.handle_export_action() processes selection
    ↓
manager.export_to_markdown() generates content
    ↓
Format as Markdown with timestamps and metadata
    ↓
Write to file or clipboard
    ↓
Notify user of completion
```

## Performance Considerations

### 1. Parsing Performance

- **Target**: ~1000 items/second
- **Optimization strategies**:
  - Lazy buffer scanning
  - Regex pattern optimization
  - Early termination conditions
  - Caching parsed results

### 2. FZF Interface Performance

- **Target**: <100ms response time
- **Optimization strategies**:
  - Item count limiting (`max_items`)
  - Efficient string formatting
  - Minimal data transfer to FZF
  - Preview generation on-demand

### 3. Memory Management

- **Target**: <50MB memory usage
- **Strategies**:
  - Cache with TTL (`cache_timeout`)
  - Weak references where possible
  - Incremental garbage collection
  - Buffer content streaming

### 4. Cache Strategy

```lua
-- Cache structure
cache = {
  [buffer_id] = {
    items = { parsed_qa_pairs },
    timestamp = cache_creation_time,
    ttl = cache_timeout_seconds
  }
}
```

## Error Handling

### 1. Error Categories

- **Configuration Errors**: Invalid user configuration
- **Buffer Errors**: Buffer access failures
- **Parsing Errors**: Content parsing failures
- **FZF Errors**: FZF-lua integration issues
- **File System Errors**: Export/import failures

### 2. Error Handling Strategy

```lua
-- Error handling pattern
local success, result = pcall(function()
  -- Operation that might fail
end)

if not success then
  logger.error("Operation failed: %s", result)
  -- Graceful degradation or user notification
  return default_value
end
```

### 3. Graceful Degradation

- Parser failures: Continue with available data
- FZF failures: Fall back to simple selection
- Export failures: Try alternative methods
- Buffer access failures: Skip inaccessible buffers

## Security Considerations

### 1. Input Validation

- User configuration validation
- Buffer content sanitization
- File path validation for exports
- Command argument sanitization

### 2. File System Security

- Restricted file operations
- Safe temporary file handling
- Path traversal prevention
- Permission checking

### 3. Content Security

- No eval() of user content
- Sanitized preview content
- Safe regex patterns
- Limited buffer access scope

## Testing Strategy

### 1. Unit Tests

- Parser logic testing
- Configuration validation
- Utility function testing
- Error handling verification

### 2. Integration Tests

- FZF-lua integration
- Neovim API interaction
- End-to-end workflows
- Performance benchmarks

### 3. Test Structure

```lua
-- Test file structure
tests/
├── test_parser.lua      -- Parser functionality
├── test_debug.lua       -- Debug system
├── test_config.lua      -- Configuration
└── test_integration.lua -- End-to-end tests
```

## Extension Points

### 1. Custom Parsers

- Parser interface for different conversation formats
- Pluggable parsing strategies
- Format-specific optimizations

### 2. Custom Actions

- Action registration system
- Custom key bindings
- External tool integration

### 3. Custom Formatters

- Display format customization
- Export format extensions
- Preview customization

## Migration and Versioning

### 1. Configuration Migration

- Backward compatibility for old configs
- Migration helpers for breaking changes
- Deprecation warnings

### 2. API Versioning

- Semantic versioning for public APIs
- Internal API evolution
- Plugin compatibility matrix

## Development Guidelines

### 1. Code Style

- 4-space indentation
- snake_case for functions and variables
- PascalCase for modules
- Comprehensive error handling

### 2. Documentation Standards

- Function documentation with types
- Module-level documentation
- Usage examples
- Performance notes

### 3. Logging Standards

- Appropriate log levels
- Structured log messages
- Performance-sensitive logging
- User-friendly messages

## Future Enhancements

### 1. Planned Features

- Multiple conversation format support
- Advanced filtering options
- Export format extensions
- Remote conversation syncing
- Enhanced preview modes
- Custom syntax highlighting themes

### 2. Performance Improvements

- Incremental parsing
- Background processing
- Streaming large conversations
- Memory optimization

### 3. Integration Enhancements

- LSP integration for context
- Git integration for versioning
- External tool plugins
- Cloud storage integration