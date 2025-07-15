# Claude FZF History

[English](README.md) | 中文

一个智能的 Neovim 插件，用于浏览和导航 Claude AI 终端对话历史。通过 fzf-lua 提供强大的搜索、过滤和跳转功能。

## ✨ 功能特性

- 🔍 **智能解析**: 自动检测和解析 Claude 终端对话内容
- 🎯 **精确跳转**: 一键跳转到历史对话的具体位置
- 📤 **批量导出**: 支持多选导出对话内容到 Markdown
- 👁️ **预览窗口**: 可切换的预览窗口，支持语法高亮
- 🌈 **语法高亮**: 集成 Bat 工具，美化代码预览显示
- 🔧 **调试工具**: 全面的调试命令和独立脚本
- ⚡ **高性能**: 解析速度约 1000 项/秒，响应时间 <100ms
- 🔧 **高度可配置**: 灵活的配置选项和键绑定
- 🎨 **现代化界面**: 基于 fzf-lua 的响应式选择界面

## 📦 安装

### 前置依赖

- Neovim >= 0.9.0
- [fzf-lua](https://github.com/ibhagwan/fzf-lua) 插件
- [bat](https://github.com/sharkdp/bat) （可选，用于语法高亮）

### 使用 lazy.nvim

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

### 使用 packer.nvim

```lua
use {
  'your-username/claude-fzf-history.nvim',
  requires = { 'ibhagwan/fzf-lua' },
  config = function()
    require('claude-fzf-history').setup()
  end
}
```

## 🚀 快速开始

### 基本使用

1. 在 Claude CLI 终端中进行对话
2. 打开历史选择器：`:ClaudeHistory` 或 `<leader>ch`
3. 使用以下快捷键：

| 快捷键 | 功能 |
|--------|------|
| `Tab` | 多选/取消选择 |
| `Enter` | 跳转到对话（仅单选） |
| `Ctrl-E` | 导出选中对话到 Markdown |
| `Ctrl-F` | 打开过滤选项 |
| `Ctrl-/` | 切换预览窗口 |
| `Shift-Up` | 预览向上滚动 |
| `Shift-Down` | 预览向下滚动 |
| `Esc` | 退出选择器 |

### 多选功能

- 使用 `Tab` 键选择多个对话
- 多选时按 `Enter` 会显示警告，防止意外跳转
- 使用 `Ctrl-E` 批量导出多个对话

### 预览窗口

- **切换预览**: 使用 `Ctrl-/` 显示/隐藏预览窗口
- **语法高亮**: 使用 bat 工具自动语法高亮（如果可用）
- **滚动导航**: 使用 `Shift-Up` 和 `Shift-Down` 滚动预览内容
- **降级模式**: 当 bat 不可用时自动降级到纯文本显示

### 导出功能

导出功能提供了美观、用户友好的界面：

#### 🎨 美化导出对话框
- **屏幕居中定位**：对话框始终显示在屏幕正中央，不受当前窗口位置影响
- **现代UI设计**：专业的框线字符和表情图标
- **清晰指示**：可视化指南显示所有可用选项
- **智能输入**：预填充带时间戳的文件名，光标定位便于编辑

#### 📤 导出选项
- **💾 保存到文件**：输入文件名并按回车
- **📋 复制到剪贴板**：留空文件名并按回车
- **❌ 取消操作**：按 Esc 关闭对话框

#### 📋 导出内容
导出的 Markdown 文件包含：
- 完整的问答内容和正确格式
- 时间戳和源文件信息
- 自动格式化的 Markdown 结构和标题
- 专业的文档布局

#### ⌨️ 对话框控制
- **插入模式**：使用 `i` 或 `a` 编辑文件名
- **导航**：使用方向键移动光标
- **提交**：按 `Enter` 确认导出
- **取消**：按 `Esc` 关闭对话框
- **自动恢复**：关闭时返回正常模式

## ⚙️ 配置

### 基本配置

```lua
require('claude-fzf-history').setup({
  -- 历史设置
  history = {
    max_items = 1000,          -- 最大历史记录数
    min_item_length = 10,      -- 最小问答长度
    cache_timeout = 300,       -- 缓存超时（秒）
    auto_refresh = true,       -- 自动刷新
  },
  
  -- 显示设置
  display = {
    max_question_length = 80,  -- 问题显示最大长度
    show_timestamp = true,     -- 显示时间戳
    show_line_numbers = true,  -- 显示行号
    date_format = \"%Y-%m-%d %H:%M\",
  },
  
  -- 预览设置
  preview = {
    enabled = true,              -- 启用预览
    hidden = false,              -- 启动时隐藏预览
    position = \"right:60%\",      -- 预览窗口位置
    wrap = true,                 -- 启用换行
    toggle_key = \"ctrl-/\",       -- 切换预览快捷键
    scroll_up = \"shift-up\",      -- 向上滚动快捷键
    scroll_down = \"shift-down\",  -- 向下滚动快捷键
    type = \"external\",           -- 预览类型: 'builtin' 或 'external'
    syntax_highlighting = {
      enabled = true,            -- 启用语法高亮
      fallback = true,           -- bat 不可用时降级到纯文本
      theme = \"Monokai Extended Bright\",  -- Bat 主题
      language = \"markdown\",     -- 默认语言
      show_line_numbers = true,  -- 显示行号
    },
  },
  
  -- 快捷键
  keymaps = {
    history = \"<leader>ch\",
  },
  
  -- 日志
  logging = {
    level = \"INFO\",           -- DEBUG, INFO, WARN, ERROR
    file_logging = false,
  },
})
```

### 高级配置示例

```lua
require('claude-fzf-history').setup({
  -- 自定义快捷键
  keymaps = {
    history = \"<leader>H\",
  },
  
  -- FZF 窗口设置
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
  
  -- 调试模式
  logging = {
    level = \"DEBUG\",
    file_logging = true,
    log_file = \"/path/to/debug.log\",
  },
})
```

## 📝 命令

| 命令 | 功能 |
|------|------|
| `:ClaudeHistory` | 打开历史选择器 |
| `:ClaudeHistoryDebug enable` | 启用调试模式 |
| `:ClaudeHistoryDebug disable` | 禁用调试模式 |
| `:ClaudeHistoryDebug status` | 查看调试状态 |
| `:ClaudeHistoryDebug log` | 打开日志文件 |
| `:ClaudeHistoryDebug buffer` | 分析当前缓冲区 |
| `:ClaudeHistoryDebug export` | 导出调试信息到剪贴板 |
| `:ClaudeHistoryDebug clear` | 清空日志文件 |

## 🔧 开发和调试

### 调试命令

```vim
# 启用调试模式
:ClaudeHistoryDebug enable

# 检查当前缓冲区
:ClaudeHistoryDebug buffer

# 导出调试信息到剪贴板
:ClaudeHistoryDebug export

# 清空日志文件
:ClaudeHistoryDebug clear

# 查看调试状态
:ClaudeHistoryDebug status

# 打开日志文件
:ClaudeHistoryDebug log
```

### 独立调试工具

```bash
# 在当前目录运行解析器分析
lua debug/debug_parser.lua

# 使用指定文件测试解析器
lua debug/parse_test.lua /path/to/claude/buffer
```

### 查看日志

日志文件位置：`~/.local/state/nvim/log/claude-fzf-history.log`

### 运行测试

```bash
# 解析器测试
lua tests/test_parser.lua

# 调试功能测试
lua tests/test_debug.lua

# 终端跳转测试
lua test_terminal_jump_fix.lua
```

## 📊 性能指标

- **解析速度**: ~1000 项/秒
- **FZF 响应时间**: <100ms
- **终端跳转**: <50ms
- **内存使用**: <50MB（带缓存）

## 🤝 贡献

欢迎提交 Issues 和 Pull Requests！

### 开发环境设置

```bash
git clone https://github.com/your-username/claude-fzf-history.nvim.git
cd claude-fzf-history.nvim
```

### 代码风格

- 使用 4 空格缩进
- 函数和变量使用 snake_case
- 模块返回表格结构
- 包含完整的错误处理

## 🐛 故障排除

### 常见问题

**Q: 没有检测到 Claude 对话？**
A: 确保你在 Claude CLI 终端 buffer 中，对话格式正确。

**Q: 多选后不能跳转？**
A: 这是设计行为。多选用于批量导出，跳转请只选择一个项目。

**Q: 性能问题？**
A: 调整 `max_items` 限制历史数量，使用过滤功能。

### 调试步骤

1. 启用调试模式：`:ClaudeHistoryDebug enable`
2. 重现问题
3. 查看日志：`:ClaudeHistoryDebug log`
4. 提交 Issue 时附上日志信息

## 📄 许可证

MIT License

## 🔗 相关项目

- [fzf-lua](https://github.com/ibhagwan/fzf-lua) - 现代化的 FZF Neovim 插件
