-- Prevent multiple loading
if vim.g.loaded_claude_fzf_history == 1 then
  return
end
vim.g.loaded_claude_fzf_history = 1

-- Check Neovim version
if vim.fn.has('nvim-0.9.0') == 0 then
  vim.notify('claude-fzf-history.nvim requires Neovim 0.9.0+', vim.log.levels.ERROR)
  return
end

-- Lazy load main module
vim.api.nvim_create_user_command('ClaudeHistory', function(args)
  require('claude-fzf-history').history(args.fargs)
end, {
  nargs = '*',
  desc = 'Open Claude conversation history picker'
})