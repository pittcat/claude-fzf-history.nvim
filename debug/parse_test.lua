#!/usr/bin/env lua

-- 测试解析器的独立脚本
-- 使用: lua parse_test.lua

-- 设置 Lua 路径以便加载模块
package.path = package.path .. ";./lua/?.lua;./lua/?/init.lua"

-- 加载解析器模块
local parser = require('claude-fzf-history.history.parser')

-- 读取文件内容
local function read_file(filepath)
    local file = io.open(filepath, "r")
    if not file then
        error("无法打开文件: " .. filepath)
    end
    local content = file:read("*all")
    file:close()
    return content
end

-- 将内容转换为行数组
local function content_to_lines(content)
    local lines = {}
    for line in content:gmatch("[^\r\n]*") do
        table.insert(lines, line)
    end
    return lines
end

-- 格式化输出问答对
local function format_qa_item(qa_item, index)
    local result = {}
    table.insert(result, string.format("=== 问答对 %d ===", index))
    table.insert(result, string.format("ID: %s", qa_item.id or "N/A"))
    table.insert(result, string.format("行范围: %d-%d", qa_item.buffer_line_start or 0, qa_item.buffer_line_end or 0))
    table.insert(result, "")
    table.insert(result, "【问题】")
    table.insert(result, qa_item.question or "")
    table.insert(result, "")
    table.insert(result, "【回答】")
    table.insert(result, qa_item.answer or "")
    table.insert(result, "")
    table.insert(result, string.rep("-", 80))
    table.insert(result, "")
    return table.concat(result, "\n")
end

-- 主解析函数
local function main()
    print("开始解析 claudecode_buffer.md...")
    
    -- 读取文件
    local content = read_file("debug/claudecode_buffer.md")
    local lines = content_to_lines(content)
    
    print(string.format("文件读取完成，共 %d 行", #lines))
    
    -- 使用解析器解析内容
    local qa_items = parser.parse_claude_code_content(lines, 1)
    
    print(string.format("解析完成，提取到 %d 个问答对", #qa_items))
    print("")
    
    -- 输出到文件
    local output_file = io.open("debug/parsed_result.txt", "w")
    if not output_file then
        error("无法创建输出文件")
    end
    
    -- 写入统计信息
    output_file:write(string.format("解析统计信息\n"))
    output_file:write(string.format("================\n"))
    output_file:write(string.format("原始文件行数: %d\n", #lines))
    output_file:write(string.format("提取问答对数: %d\n", #qa_items))
    output_file:write(string.format("解析时间: %s\n", os.date("%Y-%m-%d %H:%M:%S")))
    output_file:write(string.format("\n"))
    
    -- 写入每个问答对
    for i, qa_item in ipairs(qa_items) do
        local formatted = format_qa_item(qa_item, i)
        output_file:write(formatted)
        
        -- 同时输出到控制台（简化版）
        print(string.format("问答对 %d: %s", i, (qa_item.question or ""):sub(1, 50)))
    end
    
    output_file:close()
    print("")
    print("解析结果已保存到 parsed_result.txt")
    
    -- 输出一些调试信息
    print("\n调试信息:")
    print("=========")
    
    if #qa_items > 0 then
        local first_item = qa_items[1]
        print(string.format("第一个问答对的元数据:"))
        if first_item.metadata then
            for k, v in pairs(first_item.metadata) do
                print(string.format("  %s: %s", k, tostring(v)))
            end
        end
    end
    
    -- 检查是否有被过滤的内容
    local ide_count = 0
    for _, line in ipairs(lines) do
        if line:match("^>%s*/ide") then
            ide_count = ide_count + 1
        end
    end
    print(string.format("发现 %d 个 /ide 命令（应该被过滤）", ide_count))
end

-- 运行主函数，捕获错误
local success, error_msg = pcall(main)
if not success then
    print("错误: " .. tostring(error_msg))
    os.exit(1)
end
