# Debug Tools for claude-fzf-history.nvim

This directory contains debugging and testing tools for the `claude-fzf-history.nvim` parser module.

## Tools Overview

### 1. `parse_test.lua` - Standalone Parser Testing Tool

A standalone testing tool that parses Claude conversation content and outputs Q&A pairs. Can be run independently of Neovim.

**Usage:**
```bash
cd /path/to/claude-fzf-history.nvim

# Parse file in current directory
lua debug/parse_test.lua

# Parse specific file
lua debug/parse_test.lua /path/to/claude/buffer/file
```

**Requirements:**
- A `claudecode_buffer.md` file in the debug directory (or specified file path)
- The parser module must be loadable from the lua path
- Can run independently without Neovim

**Output:**
- Console output showing parsing progress and statistics
- `parsed_result.txt` file with detailed Q&A pairs

**What it does:**
- Reads `content.md` from the root directory
- Parses the content using the `parse_claude_code_content` function
- Extracts Q&A pairs with metadata (line numbers, timestamps, etc.)
- Outputs formatted results to both console and file
- Shows debugging information about filtering effectiveness

### 2. `debug_parser.lua` - Comprehensive Parser Analysis Tool

A comprehensive debugging tool that provides detailed analysis of the parsing process with extensive statistics and validation.

**Usage:**
```bash
cd /path/to/claude-fzf-history.nvim

# Analyze files in current directory
lua debug/debug_parser.lua

# Analyze specific directory
lua debug/debug_parser.lua /path/to/directory
```

**Requirements:**
- Claude conversation files in the target directory
- The parser module must be loadable from the lua path
- Can run independently without Neovim

**Output:**
- Detailed console analysis including:
  - Original content statistics
  - All user questions found
  - IDE commands detected and filtered
  - System reminders and connection messages
  - Filtering effectiveness verification
  - Before/after comparison with validation
  - Performance metrics

**What it analyzes:**
- Total lines in the input files
- Number of user questions found
- Number of IDE commands detected and filtered
- System reminders and tool outputs
- Connection messages filtering
- Filtering effectiveness (IDE commands, system noise)
- Parse success rates and error handling
- Performance timing and memory usage

## File Structure

```
debug/
├── README.md           # This documentation
├── parse_test.lua      # Standalone parsing tool
├── debug_parser.lua    # Comprehensive analysis tool
├── claudecode_buffer.md # Sample test data
└── .fdignore           # File ignore patterns for fd searches
```

## Input File Format

Both tools expect a `claudecode_buffer.md` file in the debug directory containing Claude Code conversation content with the following format:

```
> User question here

⏺ Assistant response here
⏺ Tool calls and outputs
  ⎿  Tool output results

> Another user question

⏺ Another assistant response
```

## Expected Behavior

### Filtering Rules

The parser should filter out:
- Questions starting with `/ide`
- Responses containing only "Connected to Neovim"
- Content within `<system-reminder>` tags
- Empty or whitespace-only responses

### Extraction Rules

The parser should extract:
- User questions (lines starting with `> `)
- Assistant responses (lines starting with `⏺`)
- Tool outputs (lines starting with `⎿`)
- Box content (content between `╭` and `╰`)
- Multi-line responses and context

## Testing Workflow

### Basic Testing

1. **Prepare test data:**
   ```bash
   # Place your Claude conversation content in debug/claudecode_buffer.md
   cp /path/to/conversation.md debug/claudecode_buffer.md
   ```

2. **Run basic parsing test:**
   ```bash
   lua debug/parse_test.lua
   ```

3. **Run detailed analysis:**
   ```bash
   lua debug/debug_parser.lua
   ```

4. **Review results:**
   - Check console output for statistics
   - Review `parsed_result.txt` for detailed Q&A pairs
   - Verify filtering effectiveness

### Advanced Testing

1. **Test with specific files:**
   ```bash
   # Test specific file
   lua debug/parse_test.lua /path/to/claude/buffer
   
   # Analyze specific directory
   lua debug/debug_parser.lua /path/to/claude/sessions
   ```

2. **Integration with Neovim debug commands:**
   ```vim
   " In Neovim, use debug commands for live analysis
   :ClaudeHistoryDebug buffer
   :ClaudeHistoryDebug export
   ```

3. **Performance testing:**
   ```bash
   # Test with large conversation files
   time lua debug/debug_parser.lua /path/to/large/sessions
   ```

## Common Issues and Solutions

### Module Loading Errors

If you get module loading errors:
```lua
-- Error: module 'claude-fzf-history.history.parser' not found
```

**Solution:** Ensure you're running from the plugin root directory where `lua/` folder exists.

### File Not Found Errors

If you get file not found errors:
```lua
-- Error: 无法打开文件: debug/claudecode_buffer.md
```

**Solution:** Place your test content in `debug/claudecode_buffer.md` in the plugin debug directory.

### Empty Results

If parsing returns no results:
- Check that your content follows the expected format
- Verify user questions start with `> `
- Ensure assistant responses start with `⏺`

## Development Tips

### Adding New Test Cases

1. Create different test files in the debug directory for various scenarios
2. Test edge cases like interrupted conversations
3. Verify filtering works for different IDE command patterns

### Debugging Parser Issues

1. Use `debug_parser.lua` to see detailed statistics
2. Check the filtering logic in the analysis output
3. Verify line number tracking is accurate

### Performance Testing

For large conversation files:
- Monitor parsing time in console output
- Check memory usage during processing
- Verify filtering efficiency with many IDE commands
- Test with files containing thousands of Q&A pairs
- Validate that filtering rules scale properly

### Integration Testing

Test integration with Neovim debug commands:
```vim
" Enable debug mode and test buffer analysis
:ClaudeHistoryDebug enable
:ClaudeHistoryDebug buffer
:ClaudeHistoryDebug export
```

### Automated Testing

Both tools support automated testing:
- Exit codes indicate success/failure
- Consistent output format for CI/CD
- Detailed error messages for debugging
- Statistics comparison for regression testing

## Integration with Neovim Debug Commands

The debug tools integrate with Neovim's built-in debug commands:

```vim
" Analyze current buffer
:ClaudeHistoryDebug buffer

" Export debug information
:ClaudeHistoryDebug export

" View comprehensive logs
:ClaudeHistoryDebug log

" Clear debug logs
:ClaudeHistoryDebug clear
```

## New Features

### Enhanced Filtering
- More robust IDE command detection
- Better handling of system reminders
- Improved connection message filtering
- Support for various Claude conversation formats

### Standalone Operation
- Both tools can run without Neovim
- Support for file path arguments
- Batch processing capabilities
- CI/CD integration support

### Performance Improvements
- Faster parsing algorithms
- Better memory management
- Parallel processing support
- Caching for repeated operations

## Contributing

When modifying the parser:
1. Run both debug tools to verify changes
2. Test with various conversation formats
3. Ensure filtering rules work correctly
4. Test both standalone and Neovim integration
5. Validate performance with large files
6. Update this documentation if adding new features