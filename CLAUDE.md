# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Neovim plugin called `claude-fzf-history.nvim` that provides intelligent browsing and navigation of Claude AI terminal conversation history. It integrates with fzf-lua to offer a powerful interface for searching, filtering, and jumping to specific conversations.

## Architecture

The plugin follows a modular architecture:

```
lua/claude-fzf-history/
├── init.lua          # Main plugin entry, exports setup() and public API
├── config.lua        # Configuration management
├── commands.lua      # Vim command registration
├── logger.lua        # Logging system with multiple levels
├── utils.lua         # Utility functions
└── history/
    ├── init.lua      # History module entry
    ├── parser.lua    # Claude conversation parser (core logic)
    ├── picker.lua    # FZF-lua interface and interactions
    └── manager.lua   # History cache and navigation management
```

### Key Components

1. **Parser** (`history/parser.lua`): Detects Claude terminal buffers and parses conversation content into structured Q&A pairs
2. **Picker** (`history/picker.lua`): Provides the FZF interface with preview, search, and actions
3. **Manager** (`history/manager.lua`): Handles caching, terminal jumping, and content export
4. **Logger** (`logger.lua`): Multi-level logging system for debugging

## Development Commands

### Running Tests
```bash
# Note: Test files don't exist yet in the repository
# Tests are run using simple Lua scripts with pcall assertions

# Test the plugin in Neovim
nvim --clean -c "set rtp+=." -c "lua require('claude-fzf-history').setup()"
```

### Plugin Installation for Development
```bash
# Clone and symlink for development
git clone <repo-url> ~/.local/share/nvim/site/pack/dev/start/claude-fzf-history.nvim
```

### Debugging in Neovim
```vim
" Enable debug mode
:ClaudeHistoryDebug enable

" Check debug status
:ClaudeHistoryDebug status

" View log file
:ClaudeHistoryDebug log

" Reload plugin during development
:lua package.loaded['claude-fzf-history'] = nil
:lua require('claude-fzf-history').setup()
```

### Log Location
Debug logs are written to: `~/.local/state/nvim/log/claude-fzf-history.log`

## Code Standards

1. **Module Structure**: Each module returns a table with its public functions
2. **Error Handling**: Use `pcall` for potentially failing operations
3. **Logging**: Use the logger module for debug information, avoid print statements
4. **Configuration**: All user-facing options go through the config module
5. **Testing**: Tests use simple assert-based framework with visual output

## Key APIs

### Public Functions (lua/claude-fzf-history/init.lua)
- `setup(opts)`: Initialize plugin with user configuration
- `show_history()`: Open the FZF history picker
- `debug_mode(action)`: Control debug logging

### Internal APIs
- Parser: `parse_buffer()`, `find_claude_buffers()`
- Picker: `create_picker()`, `preview_handler()`
- Manager: `jump_to_item()`, `export_to_markdown()`

## Testing Approach

Tests are simple Lua scripts that:
1. Modify `package.path` to load the plugin modules
2. Use `pcall` to catch errors
3. Display results with ✓ (pass) or ✗ (fail) markers
4. Exit with appropriate status codes

## Performance Considerations

- Parser processes at ~1000 items/second
- FZF picker responds in <100ms
- Terminal jumping completes in <50ms
- Memory usage stays under 50MB with caching

## Common Development Tasks

### Adding a New Feature
1. Identify the appropriate module (parser, picker, or manager)
2. Add the functionality with proper error handling
3. Update the config module if new options are needed
4. Add tests in the tests/ directory
5. Update documentation (README.md, USAGE.md)

### Debugging Issues
1. Enable debug mode: `:ClaudeHistoryDebug enable`
2. Check the log file for detailed information
3. Use the test scripts to isolate problems
4. The parser has extensive debug logging for buffer detection

## Dependencies

- Neovim >= 0.9.0 (for proper terminal buffer APIs)
- fzf-lua plugin (for the selection interface)
- Optional: System clipboard tools (pbcopy/xclip/wl-copy)

## Plugin Structure

```
plugin/claude-fzf-history.lua    # Plugin initialization and command registration
lua/claude-fzf-history/
├── init.lua                     # Main plugin entry and public API
├── config.lua                   # Configuration management and defaults
├── commands.lua                 # Vim command definitions
├── logger.lua                   # Multi-level logging system
├── utils.lua                    # Common utility functions
└── history/                     # Core history functionality
    ├── init.lua                 # History module entry point
    ├── parser.lua               # Claude conversation parser
    ├── picker.lua               # FZF-lua interface and interactions
    └── manager.lua              # History cache and navigation
```