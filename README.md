# Claude FZF History

English | [中文](README_CN.md)

An intelligent Neovim plugin for browsing and navigating Claude AI terminal conversation history. Provides powerful search, filtering, and jump functionality through fzf-lua integration.

## ✨ Features

- 🔍 **Smart Parsing**: Automatically detect and parse Claude terminal conversation content
- 🎯 **Precise Navigation**: One-click jump to specific conversation locations
- 📤 **Batch Export**: Multi-select export conversations to Markdown
- ⚡ **High Performance**: ~1000 items/second parsing, <100ms response time
- 🔧 **Highly Configurable**: Flexible configuration options and key bindings
- 🎨 **Modern Interface**: Responsive selection interface based on fzf-lua

## 📦 Installation

### Prerequisites

- Neovim >= 0.9.0
- [fzf-lua](https://github.com/ibhagwan/fzf-lua) plugin

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
| `Esc` | Exit picker |

### Multi-selection

- Use `Tab` key to select multiple conversations
- Pressing `Enter` with multiple selections will show a warning to prevent accidental jumps
- Use `Ctrl-E` to batch export multiple conversations

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

## 🔧 Development and Debugging

### Enable Debug Mode

```vim
:ClaudeHistoryDebug enable
```

### View Logs

Log file location: `~/.local/state/nvim/log/claude-fzf-history.log`

```vim
:ClaudeHistoryDebug log
```

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
