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
})

local opts = config.get()
assert_eq(opts.enabled, false, "setup should update enabled")
assert_eq(opts.title_backend, "osc", "setup should update title_backend")
assert_eq(opts.ring_bell, true, "setup should update ring_bell")
assert_eq(opts.input_patterns[1], "foo", "setup should update input_patterns")

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
