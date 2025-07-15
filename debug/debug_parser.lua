#!/usr/bin/env lua

-- 调试解析器的详细脚本
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

local parser = require('claude-fzf-history.history.parser')

-- 读取文件并转换为行数组
local function read_file_lines(filepath)
    local file = io.open(filepath, "r")
    if not file then
        error("无法打开文件: " .. filepath)
    end
    local lines = {}
    for line in file:lines() do
        table.insert(lines, line)
    end
    file:close()
    return lines
end

-- 分析原始内容中的模式
local function analyze_patterns(lines)
    local stats = {
        total_lines = #lines,
        user_questions = 0,
        ide_commands = 0,
        system_reminders = 0,
        tool_outputs = 0,
        connection_messages = 0
    }
    
    local ide_lines = {}
    local question_lines = {}
    
    for i, line in ipairs(lines) do
        local trimmed = line:gsub("^%s*(.-)%s*$", "%1")
        
        -- 用户问题
        if trimmed:match("^>%s+") then
            stats.user_questions = stats.user_questions + 1
            table.insert(question_lines, {line_num = i, content = trimmed})
            
            -- 检查是否是 /ide 命令
            if trimmed:match("^>%s*/ide") then
                stats.ide_commands = stats.ide_commands + 1
                table.insert(ide_lines, {line_num = i, content = trimmed})
            end
        end
        
        -- 系统提示
        if line:match("<system%-reminder>") then
            stats.system_reminders = stats.system_reminders + 1
        end
        
        -- 工具输出
        if trimmed:match("^⎿") then
            stats.tool_outputs = stats.tool_outputs + 1
            
            -- 连接消息
            if trimmed:match("Connected to Neovim") then
                stats.connection_messages = stats.connection_messages + 1
            end
        end
    end
    
    return stats, ide_lines, question_lines
end

-- 主函数
local function main()
    print("=== 解析器调试分析 ===")
    print()
    
    -- 读取文件
    local lines = read_file_lines("debug/claudecode_buffer.md")
    
    -- 分析原始内容
    local stats, ide_lines, question_lines = analyze_patterns(lines)
    
    print("原始内容分析:")
    print("=============")
    printf = function(fmt, ...)
        print(string.format(fmt, ...))
    end
    
    printf("总行数: %d", stats.total_lines)
    printf("用户问题: %d", stats.user_questions)
    printf("IDE 命令: %d", stats.ide_commands)
    printf("系统提示: %d", stats.system_reminders)
    printf("工具输出: %d", stats.tool_outputs)
    printf("连接消息: %d", stats.connection_messages)
    print()
    
    -- 显示所有用户问题
    print("所有用户问题:")
    print("=============")
    for i, q in ipairs(question_lines) do
        local is_ide = q.content:match("^>%s*/ide")
        printf("%d. 行%d: %s %s", i, q.line_num, q.content:sub(1, 60), 
               is_ide and "[IDE命令]" or "")
    end
    print()
    
    -- 显示 IDE 命令详情
    if #ide_lines > 0 then
        print("IDE 命令详情:")
        print("=============")
        for i, ide in ipairs(ide_lines) do
            printf("%d. 行%d: %s", i, ide.line_num, ide.content)
        end
        print()
    end
    
    -- 使用解析器处理
    print("解析器处理结果:")
    print("===============")
    local qa_items = parser.parse_claude_code_content(lines, 1)
    printf("提取的问答对: %d", #qa_items)
    print()
    
    -- 显示解析后的问题
    print("解析后的问题列表:")
    print("=================")
    for i, qa in ipairs(qa_items) do
        printf("%d. 行%d-%d: %s", i, qa.buffer_line_start, qa.buffer_line_end, 
               (qa.question or ""):sub(1, 60))
    end
    print()
    
    -- 验证过滤效果
    print("过滤效果验证:")
    print("=============")
    local filtered_ide = 0
    for _, qa in ipairs(qa_items) do
        if qa.question and qa.question:match("/ide") then
            filtered_ide = filtered_ide + 1
            printf("警告: 发现未过滤的 IDE 命令: %s", qa.question)
        end
    end
    
    if filtered_ide == 0 then
        printf("✅ 所有 %d 个 IDE 命令都被正确过滤", stats.ide_commands)
    else
        printf("❌ 有 %d 个 IDE 命令未被过滤", filtered_ide)
    end
    
    printf("原始问题数: %d, 解析后问题数: %d, 过滤掉: %d", 
           stats.user_questions, #qa_items, stats.user_questions - #qa_items)
end

-- 运行
local success, error_msg = pcall(main)
if not success then
    print("错误: " .. tostring(error_msg))
    os.exit(1)
end