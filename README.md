# Claude FZF History

English | [中文](README_CN.md)

An intelligent Neovim plugin for browsing and navigating Claude AI terminal conversation history. Provides powerful search, filtering, and jump functionality through fzf-lua integration.

## ✨ Features

- 🔍 **Smart Parsing**: Automatically detect and parse Claude terminal conversation content
- 🎯 **Precise Navigation**: One-click jump to specific conversation locations
- 📤 **Batch Export**: Multi-select export conversations to Markdown
- 👁️ **Preview Window**: Toggle-able preview with syntax highlighting support
- 🌈 **Syntax Highlighting**: Bat integration for beautiful code preview
- 🔧 **Debug Tools**: Comprehensive debugging commands and standalone scripts
- ⚡ **High Performance**: ~1000 items/second parsing, <100ms response time
- 🔧 **Highly Configurable**: Flexible configuration options and key bindings
- 🎨 **Modern Interface**: Responsive selection interface based on fzf-lua

## 📦 Installation

### Prerequisites

- Neovim >= 0.9.0
- [fzf-lua](https://github.com/ibhagwan/fzf-lua) plugin
- [bat](https://github.com/sharkdp/bat) (optional, for syntax highlighting)

### Using lazy.nvim

```lua
{
  'your-username/claude-fzf-history.nvim',
  dependencies = { 'ibhagwan/fzf-lua' },
  config = function()
    require('claude-fzf-history').setup()
  end,
  cmd = { 'ClaudeHistory', 'ClaudeHistoryDebug' },
  keys = {
    { '<leader>ch', '<cmd>ClaudeHistory<cr>', desc = 'Claude History' },
  },
}
```

### Using packer.nvim

```lua
use {
  'your-username/claude-fzf-history.nvim',
  requires = { 'ibhagwan/fzf-lua' },
  config = function()
    require('claude-fzf-history').setup()
  end
}
```

## 🚀 Quick Start

### Basic Usage

1. Have conversations in Claude CLI terminal
2. Open history picker: `:ClaudeHistory` or `<leader>ch`
3. Use the following keybindings:

| Key | Function |
|-----|----------|
| `Tab` | Multi-select/deselect |
| `Enter` | Jump to conversation (single selection only) |
| `Ctrl-E` | Export selected conversations to Markdown |
| `Ctrl-F` | Open filter options |
| `Ctrl-/` | Toggle preview window |
| `Shift-Up` | Scroll preview up |
| `Shift-Down` | Scroll preview down |
| `Esc` | Exit picker |

### Multi-selection

- Use `Tab` key to select multiple conversations
- Pressing `Enter` with multiple selections will show a warning to prevent accidental jumps
- Use `Ctrl-E` to batch export multiple conversations

### Preview Window

- **Toggle Preview**: Use `Ctrl-/` to show/hide the preview window
- **Syntax Highlighting**: Automatic syntax highlighting with bat (if available)
- **Scroll Navigation**: Use `Shift-Up` and `Shift-Down` to scroll through preview
- **Fallback Mode**: Automatically falls back to plain text if bat is not available

### Export Feature

The export feature provides a beautiful, user-friendly interface:

#### 🎨 Beautiful Export Dialog
- **Screen-Centered Positioning**: Dialog always appears in the exact center of your screen, regardless of current window position
- **Modern UI Design**: Professional box-drawing characters and emoji icons
- **Clear Instructions**: Visual guide showing all available options
- **Smart Input**: Pre-filled filename with timestamp, cursor positioned for easy editing

#### 📤 Export Options
- **💾 Save to File**: Enter filename and press Enter
- **📋 Copy to Clipboard**: Leave filename empty and press Enter  
- **❌ Cancel**: Press Esc to close without action

#### 📋 Export Content
Exported Markdown files include:
- Complete Q&A content with proper formatting
- Timestamps and source file information
- Auto-formatted Markdown structure with headers
- Professional document layout

#### ⌨️ Dialog Controls
- **Insert Mode**: Use `i` or `a` to edit filename
- **Navigation**: Use arrow keys to move cursor
- **Submit**: Press `Enter` to confirm export
- **Cancel**: Press `Esc` to close dialog
- **Auto-restore**: Returns to normal mode when closed

## ⚙️ Configuration

### Basic Configuration

```lua
require('claude-fzf-history').setup({
  -- History settings
  history = {
    max_items = 1000,          -- Maximum number of history items
    min_item_length = 10,      -- Minimum Q&A length
    cache_timeout = 300,       -- Cache timeout (seconds)
    auto_refresh = true,       -- Auto refresh
  },
  
  -- Display settings
  display = {
    max_question_length = 80,  -- Maximum question display length
    show_timestamp = true,     -- Show timestamps
    show_line_numbers = true,  -- Show line numbers
    date_format = "%Y-%m-%d %H:%M",
  },
  
  -- Preview settings
  preview = {
    enabled = true,              -- Enable preview
    hidden = false,              -- Start with preview hidden
    position = "right:60%",      -- Preview window position
    wrap = true,                 -- Enable line wrapping
    toggle_key = "ctrl-/",       -- Toggle preview key
    scroll_up = "shift-up",      -- Scroll up key
    scroll_down = "shift-down",  -- Scroll down key
    type = "external",           -- Preview type: 'builtin' or 'external'
    syntax_highlighting = {
      enabled = true,            -- Enable syntax highlighting
      fallback = true,           -- Fallback to plain text if bat unavailable
      theme = "Monokai Extended Bright",  -- Bat theme
      language = "markdown",     -- Default language
      show_line_numbers = true,  -- Show line numbers
    },
  },
  
  -- Keymaps
  keymaps = {
    history = "<leader>ch",
  },
  
  -- Logging
  logging = {
    level = "INFO",           -- DEBUG, INFO, WARN, ERROR
    file_logging = false,
  },
})
```

### Advanced Configuration Example

```lua
require('claude-fzf-history').setup({
  -- Custom keymaps
  keymaps = {
    history = "<leader>H",
  },
  
  -- FZF window settings
  fzf_opts = {
    winopts = {
      height = 0.8,
      width = 0.9,
      preview = {
        layout = 'vertical',
        vertical = 'right:60%',
      },
    },
  },
  
  -- Debug mode
  logging = {
    level = "DEBUG",
    file_logging = true,
    log_file = "/path/to/debug.log",
  },
})
```

## 📝 Commands

| Command | Function |
|---------|----------|
| `:ClaudeHistory` | Open history picker |
| `:ClaudeHistoryDebug enable` | Enable debug mode |
| `:ClaudeHistoryDebug disable` | Disable debug mode |
| `:ClaudeHistoryDebug status` | View debug status |
| `:ClaudeHistoryDebug log` | Open log file |
| `:ClaudeHistoryDebug buffer` | Analyze current buffer |
| `:ClaudeHistoryDebug export` | Export debug info to clipboard |
| `:ClaudeHistoryDebug clear` | Clear log file |

## 🔧 Development and Debugging

### Debug Commands

```vim
# Enable debug mode
:ClaudeHistoryDebug enable

# Check current buffer
:ClaudeHistoryDebug buffer

# Export debug info to clipboard
:ClaudeHistoryDebug export

# Clear log file
:ClaudeHistoryDebug clear

# View debug status
:ClaudeHistoryDebug status

# Open log file
:ClaudeHistoryDebug log
```

### Standalone Debug Tools

```bash
# Run parser analysis on current directory
lua debug/debug_parser.lua

# Test parser with specific file
lua debug/parse_test.lua /path/to/claude/buffer
```

### View Logs

Log file location: `~/.local/state/nvim/log/claude-fzf-history.log`

### Run Tests

```bash
# Parser tests
lua tests/test_parser.lua

# Debug functionality tests
lua tests/test_debug.lua

# Terminal jump tests
lua test_terminal_jump_fix.lua
```

## 📊 Performance Metrics

- **Parsing Speed**: ~1000 items/second
- **FZF Response Time**: <100ms
- **Terminal Jump**: <50ms
- **Memory Usage**: <50MB (with caching)

## 🤝 Contributing

Issues and Pull Requests are welcome!

### Development Environment Setup

```bash
git clone https://github.com/your-username/claude-fzf-history.nvim.git
cd claude-fzf-history.nvim
```

### Code Style

- Use 4-space indentation
- Functions and variables use snake_case
- Modules return table structures
- Include comprehensive error handling

## 🐛 Troubleshooting

### Common Issues

**Q: No Claude conversations detected?**
A: Ensure you're in a Claude CLI terminal buffer and conversation format is correct.

**Q: Can't jump after multi-selection?**
A: This is by design. Multi-selection is for batch export, use single selection for jumping.

**Q: Performance issues?**
A: Adjust `max_items` to limit history count, use filter functionality.

### Debugging Steps

1. Enable debug mode: `:ClaudeHistoryDebug enable`
2. Reproduce the issue
3. Check logs: `:ClaudeHistoryDebug log`
4. Include log information when submitting issues

## 📄 License

MIT License

## 🔗 Related Projects

- [fzf-lua](https://github.com/ibhagwan/fzf-lua) - Modern FZF Neovim plugin
