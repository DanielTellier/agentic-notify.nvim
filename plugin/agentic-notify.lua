if vim.g.loaded_agentic_notify then
  return
end
vim.g.loaded_agentic_notify = true

vim.api.nvim_create_user_command("AgenticNotifyEnable", function()
  require("agentic-notify").enable()
end, {})

vim.api.nvim_create_user_command("AgenticNotifyDisable", function()
  require("agentic-notify").disable()
end, {})

vim.api.nvim_create_user_command("AgenticNotifyStatus", function()
  local status = require("agentic-notify").status()
  local msg = string.format(
    "AgenticNotify enabled=%s tracked=%d",
    tostring(status.enabled),
    status.tracked_buffers
  )
  vim.notify(msg)
end, {})

vim.api.nvim_create_user_command("AgenticNotifyAttach", function()
  local buf = vim.api.nvim_get_current_buf()
  require("agentic-notify").attach(buf)
end, {})
