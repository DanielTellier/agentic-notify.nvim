vim.opt.runtimepath:prepend(vim.fn.getcwd())

vim.cmd("set rtp^=" .. vim.fn.getcwd())

local ok, err = pcall(function()
  dofile("tests/agentic_notify_spec.lua")
end)

if not ok then
  vim.api.nvim_err_writeln(err)
  vim.cmd("cquit")
end

vim.cmd("quit")
