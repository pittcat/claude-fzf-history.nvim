-- Test the screen-centered positioning for export dialog
-- Run in Neovim: :luafile test_screen_center.lua

print("=== Testing Screen-Centered Positioning ===")

-- Check if we're in Neovim
if not vim then
  print("❌ This test must be run in Neovim")
  return
end

-- Setup module paths
local current_dir = vim.fn.expand('%:p:h')
local lua_dir = current_dir .. '/lua'

-- Add to package path if not already present
if not package.path:find(lua_dir, 1, true) then
  package.path = lua_dir .. '/?.lua;' .. lua_dir .. '/?/init.lua;' .. package.path
end

-- Clear any existing modules
package.loaded['claude-fzf-history'] = nil
package.loaded['claude-fzf-history.config'] = nil
package.loaded['claude-fzf-history.logger'] = nil
package.loaded['claude-fzf-history.history.picker'] = nil

-- Test 1: Initialize the plugin
print("\n1. Testing plugin initialization...")
local success, err = pcall(function()
  local claude_history = require('claude-fzf-history')
  claude_history.setup({
    logging = {
      level = "DEBUG",
      file_logging = false,
      console_logging = true
    }
  })
end)

if success then
  print("✅ Plugin initialization successful")
else
  print("❌ Plugin initialization failed: " .. tostring(err))
  return
end

-- Test 2: Display screen dimensions
print("\n2. Screen dimensions:")
local screen_width = vim.o.columns
local screen_height = vim.o.lines
print("📐 Screen width: " .. screen_width)
print("📐 Screen height: " .. screen_height)

-- Calculate expected dialog position
local dialog_width = math.min(60, math.floor(screen_width * 0.6))
local dialog_height = 8
local expected_row = math.floor((screen_height - dialog_height) / 2)
local expected_col = math.floor((screen_width - dialog_width) / 2)

print("📐 Dialog width: " .. dialog_width)
print("📐 Dialog height: " .. dialog_height)
print("📍 Expected position: row=" .. expected_row .. ", col=" .. expected_col)

-- Test 3: Open dialog in different window positions
print("\n3. Testing screen-centered positioning...")

-- First, split windows to test if dialog stays centered
vim.cmd('split')
vim.cmd('vsplit')

local success2, err2 = pcall(function()
  local picker = require('claude-fzf-history.history.picker')
  
  -- Create fake selected items for testing
  local test_items = {
    {
      question = "Does this dialog stay screen-centered?",
      answer = "Yes, it should always be in the exact screen center!",
      timestamp = os.time(),
      metadata = {}
    },
    {
      question = "What happens when I switch windows?",
      answer = "The dialog position should not change.",
      timestamp = os.time() - 60,
      metadata = {}
    }
  }
  
  print("🎯 Creating screen-centered export dialog...")
  print("📝 Test instructions:")
  print("   1. Dialog should appear in the exact center of your screen")
  print("   2. Position should be independent of current window")
  print("   3. Try switching windows before opening dialog")
  print("   4. Dialog should always be screen-centered")
  
  -- Create the dialog
  picker.create_export_dialog(test_items, function(input)
    if input == "" then
      print("📋 Test: User chose clipboard option")
    else
      print("💾 Test: User chose file option: " .. input)
    end
    print("✅ Screen-centered dialog test completed!")
  end)
end)

if success2 then
  print("✅ Screen-centered export dialog created")
  print("🔍 Verify the dialog appears in the exact center of your screen")
  print("📍 Expected coordinates: row=" .. expected_row .. ", col=" .. expected_col)
else
  print("❌ Screen-centered dialog test failed: " .. tostring(err2))
end

print("\n=== Screen Centering Test ===")
print("🎯 The dialog should always appear in the exact center of your entire screen")
print("📐 Position should be calculated based on vim.o.columns and vim.o.lines")
print("🪟 Window splits or current window position should not affect dialog placement")