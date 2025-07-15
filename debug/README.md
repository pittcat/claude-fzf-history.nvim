# Debug Tools for claude-fzf-history.nvim

This directory contains debugging and testing tools for the `claude-fzf-history.nvim` parser module.

## Tools Overview

### 1. `parse_test.lua` - Basic Parser Testing Tool

A simple testing tool that parses Claude conversation content and outputs Q&A pairs.

**Usage:**
```bash
cd /path/to/claude-fzf-history.nvim
lua debug/parse_test.lua
```

**Requirements:**
- A `claudecode_buffer.md` file in the debug directory containing Claude conversation content
- The parser module must be loadable from the lua path

**Output:**
- Console output showing parsing progress and statistics
- `parsed_result.txt` file with detailed Q&A pairs

**What it does:**
- Reads `content.md` from the root directory
- Parses the content using the `parse_claude_code_content` function
- Extracts Q&A pairs with metadata (line numbers, timestamps, etc.)
- Outputs formatted results to both console and file
- Shows debugging information about filtering effectiveness

### 2. `debug_parser.lua` - Advanced Parser Analysis Tool

A comprehensive debugging tool that provides detailed analysis of the parsing process.

**Usage:**
```bash
cd /path/to/claude-fzf-history.nvim
lua debug/debug_parser.lua
```

**Requirements:**
- A `claudecode_buffer.md` file in the debug directory containing Claude conversation content
- The parser module must be loadable from the lua path

**Output:**
- Detailed console analysis including:
  - Original content statistics
  - All user questions found
  - IDE commands detected
  - Filtering effectiveness verification
  - Before/after comparison

**What it analyzes:**
- Total lines in the input file
- Number of user questions found
- Number of IDE commands detected
- System reminders and tool outputs
- Connection messages
- Filtering effectiveness (IDE commands, system noise)

## File Structure

```
debug/
├── README.md           # This documentation
├── parse_test.lua      # Basic parsing tool
└── debug_parser.lua    # Advanced analysis tool
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

## Contributing

When modifying the parser:
1. Run both debug tools to verify changes
2. Test with various conversation formats
3. Ensure filtering rules work correctly
4. Update this documentation if adding new features