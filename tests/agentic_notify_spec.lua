local config = require("agentic-notify.config")
local notify = require("agentic-notify")

local function assert_eq(actual, expected, msg)
  if actual ~= expected then
    error(string.format("%s (expected=%s, actual=%s)", msg, tostring(expected), tostring(actual)))
  end
end

local defaults = config.get()
assert_eq(defaults.enabled, true, "default enabled should be true")
assert_eq(defaults.title_backend, "auto", "default title_backend should be auto")
assert_eq(type(defaults.input_patterns), "table", "default input_patterns should be table")

config.setup({
  enabled = false,
  input_patterns = { "foo" },
  title_backend = "osc",
  ring_bell = true,
  debug_output = true,
})

local opts = config.get()
assert_eq(opts.enabled, false, "setup should update enabled")
assert_eq(opts.title_backend, "osc", "setup should update title_backend")
assert_eq(opts.ring_bell, true, "setup should update ring_bell")
assert_eq(opts.input_patterns[1], "foo", "setup should update input_patterns")
assert_eq(opts.debug_output, true, "setup should update debug_output")

local status = notify.status()
assert_eq(status.enabled, false, "status should reflect enabled=false")

notify.enable()
status = notify.status()
assert_eq(status.enabled, true, "enable should set enabled=true")

notify.disable()
status = notify.status()
assert_eq(status.enabled, false, "disable should set enabled=false")

-- Attach should no-op for non-terminal buffers
local buf = vim.api.nvim_create_buf(false, true)
notify.attach(buf)
status = notify.status()
assert_eq(status.tracked_buffers, 0, "attach should ignore non-terminal buffers")

-- User commands should be available via plugin runtime
assert_eq(vim.fn.exists(":AgenticNotifyStatus"), 2, "command should exist")

local private = notify._private
assert_eq(type(private), "table", "private helpers should be exposed for tests")

local normalized = private.normalize_terminal_line("\027[31m-->NEEDS_INPUT<--\027[0m\r")
assert_eq(normalized, "-->NEEDS_INPUT<--", "normalize should strip ANSI and carriage return")

local tail_buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(tail_buf, 0, -1, false, {
  "first line",
  "",
  "\027[32m-->NEEDS_INPUT<--\027[0m\r",
  "",
})
local tail = private.get_last_non_empty_line(tail_buf)
assert_eq(tail, "-->NEEDS_INPUT<--", "last non-empty line should be normalized terminal tail")

local from_lines = private.get_last_non_empty_from_lines({
  "",
  "\027[31mstatus: running\027[0m",
  "\027[32m-->NEEDS_INPUT<--\027[0m\r",
  "",
})
assert_eq(from_lines, "-->NEEDS_INPUT<--", "last non-empty changed line should be normalized")
