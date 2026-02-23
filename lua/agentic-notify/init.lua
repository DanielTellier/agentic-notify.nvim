local M = {}

local config = require("agentic-notify.config")
local state = require("agentic-notify.state")

local function ring_bell()
  vim.api.nvim_out_write("\007")
end

local function debug_log(opts, msg)
  if not opts or not opts.debug_output then
    return
  end
  vim.schedule(function()
    vim.notify("[agentic-notify] " .. msg, vim.log.levels.INFO)
  end)
end

local function sanitize_title(title)
  if not title or title == "" then
    return "NVIM"
  end
  return title:gsub("[%c]", "")
end

local function capture_original_title()
  if state.title.original ~= nil then
    return
  end
  local base = vim.o.titlestring
  if not base or base == "" then
    base = "NVIM"
  end
  state.title.original = sanitize_title(base)
end

local function select_title_backend(opts)
  local backend = opts.title_backend or "auto"
  if backend == "auto" then
    if vim.env.TMUX and vim.env.TMUX ~= "" then
      backend = "tmux"
    else
      backend = "osc"
    end
  end
  return backend
end

local function emit_title(title, opts)
  if not opts.update_title then
    return
  end
  capture_original_title()

  local backend = select_title_backend(opts)
  local sanitized = sanitize_title(title)

  local function write_escape(sequence)
    local ok = pcall(vim.api.nvim_chan_send, vim.v.stderr, sequence)
    if not ok then
      vim.api.nvim_out_write(sequence)
    end
  end

  if backend == "tmux" then
    write_escape("\027Ptmux;\027\027]0;" .. sanitized .. "\007\027\\")
  else
    write_escape("\027]0;" .. sanitized .. "\007")
  end

  state.title.last = sanitized
end

local function restore_title(opts)
  if not opts.update_title then
    return
  end
  capture_original_title()
  if state.title.original then
    emit_title(state.title.original, opts)
  end
end

local function matches_patterns(line, patterns)
  if not line or line == "" then
    return false
  end
  for _, pattern in ipairs(patterns) do
    if line:match(pattern) then
      return true
    end
  end
  return false
end

local function normalize_terminal_line(line)
  if not line or line == "" then
    return ""
  end

  -- Strip common terminal escape sequences and control characters so
  -- pattern matching sees only visible text.
  line = line:gsub("\027%[[0-9;?]*[ -/]*[@-~]", "")
  line = line:gsub("\027%].-\007", "")
  line = line:gsub("\027%].-\027\\", "")
  line = line:gsub("[%z\001-\008\011\012\014-\031\127]", "")
  line = line:gsub("\r", "")
  return line
end

local function get_last_non_empty_line(buf)
  local line_count = vim.api.nvim_buf_line_count(buf)
  if line_count == 0 then
    return nil
  end

  local tail_start = math.max(0, line_count - 200)
  local lines = vim.api.nvim_buf_get_lines(buf, tail_start, line_count, false)
  for i = #lines, 1, -1 do
    local normalized = normalize_terminal_line(lines[i])
    if normalized ~= "" then
      return normalized
    end
  end
  return nil
end

local function get_last_non_empty_from_lines(lines)
  if not lines then
    return nil
  end
  for i = #lines, 1, -1 do
    local normalized = normalize_terminal_line(lines[i])
    if normalized ~= "" then
      return normalized
    end
  end
  return nil
end

local function next_instance_id()
  if #state.free_instance_ids > 0 then
    table.sort(state.free_instance_ids)
    return table.remove(state.free_instance_ids, 1)
  end
  local id = state.next_instance_id
  state.next_instance_id = state.next_instance_id + 1
  return id
end

local function format_title(entry)
  if entry.needs_input then
    return string.format("%d:INPUT TERM", entry.instance_id)
  end
  return string.format("%d:TERM", entry.instance_id)
end

local function update_title_for_buf(buf, opts)
  local entry = state.buffers[buf]
  if not entry or not entry.instance_id then
    return
  end
  local title = format_title(entry)
  state.title.last_buf = buf
  emit_title(title, opts)
end

local function update_title_after_close(opts)
  local buf = state.title.last_buf
  if buf and state.buffers[buf] then
    update_title_for_buf(buf, opts)
    return
  end

  local current = vim.api.nvim_get_current_buf()
  if state.buffers[current] then
    update_title_for_buf(current, opts)
    return
  end

  for other_buf, _ in pairs(state.buffers) do
    update_title_for_buf(other_buf, opts)
    break
  end

  restore_title(opts)
end

local function set_needs_input(buf, value, opts)
  local entry = state.ensure_buffer(buf)
  if entry.needs_input == value then
    return
  end
  entry.needs_input = value
  if value and opts.ring_bell then
    ring_bell()
  end
  update_title_for_buf(buf, opts)
end

local function clear_needs_input(buf, opts)
  local entry = state.buffers[buf]
  if not entry or not entry.needs_input then
    return
  end
  entry.needs_input = false
  update_title_for_buf(buf, opts)
end

local function ensure_instance(buf, opts)
  local entry = state.ensure_buffer(buf)
  if not entry.instance_id then
    entry.instance_id = next_instance_id()
    update_title_for_buf(buf, opts)
  end
end

local function detach_buffer(buf, opts)
  local entry = state.buffers[buf]
  if not entry or entry.closed then
    return
  end
  -- TermClose, BufWipeout, and on_detach can all fire for the same terminal.
  -- The closed flag prevents double-freeing instance ids and duplicate updates.
  entry.closed = true
  if entry.instance_id then
    table.insert(state.free_instance_ids, entry.instance_id)
  end
  state.remove_buffer(buf)
  update_title_after_close(opts)
end

function M.attach(buf)
  local opts = config.get()
  if not opts.enabled then
    return
  end
  if not vim.api.nvim_buf_is_valid(buf) then
    return
  end
  if vim.bo[buf].buftype ~= "terminal" then
    return
  end

  local entry = state.ensure_buffer(buf)
  if entry.attached then
    return
  end
  entry.attached = true
  ensure_instance(buf, opts)

  vim.api.nvim_buf_attach(buf, false, {
    on_detach = function(_, detach_buf)
      detach_buffer(detach_buf, opts)
    end,
    on_lines = function(_, line_buf, _, firstline, _, new_lastline)
      if not opts.enabled then
        return
      end
      local changed_lines = vim.api.nvim_buf_get_lines(line_buf, firstline, new_lastline, false)
      local source = "changed_lines"
      local last_line = get_last_non_empty_from_lines(changed_lines)
      if last_line == nil then
        source = "buffer_tail"
        last_line = get_last_non_empty_line(line_buf)
      end

      local matched_input = matches_patterns(last_line, opts.input_patterns)

      -- Check if line has "well" anywhere in it
      if last_line and last_line:lower():find("well") then
        debug_log(
          opts, string.format("Found the word well")
        )
      end

      if matched_input then
        debug_log(
          opts, string.format("The matched line=%s matched_input=%s source=%s", last_line, tostring(matched_input), source)
        )
        set_needs_input(line_buf, true, opts)
      elseif opts.clear_on_output and last_line ~= nil then
        clear_needs_input(line_buf, opts)
      end
    end,
  })

  if opts.clear_on_term_enter then
    vim.api.nvim_create_autocmd("TermEnter", {
      buffer = buf,
      callback = function()
        clear_needs_input(buf, opts)
        update_title_for_buf(buf, opts)
      end,
    })
  end

  vim.api.nvim_create_autocmd("TermClose", {
    buffer = buf,
    callback = function()
      detach_buffer(buf, opts)
    end,
  })

  vim.api.nvim_create_autocmd("BufWipeout", {
    buffer = buf,
    callback = function()
      detach_buffer(buf, opts)
    end,
  })
end

function M.enable()
  local opts = config.get()
  opts.enabled = true
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.bo[buf].buftype == "terminal" then
      M.attach(buf)
    end
  end
end

function M.disable()
  local opts = config.get()
  opts.enabled = false
  for buf, entry in pairs(state.buffers) do
    entry.needs_input = false
    entry.attached = false
    state.buffers[buf] = nil
  end
  state.next_instance_id = 1
  state.free_instance_ids = {}
  state.title.last_buf = nil
  restore_title(opts)
end

function M.status()
  local opts = config.get()
  return {
    enabled = opts.enabled,
    tracked_buffers = vim.tbl_count(state.buffers),
  }
end

function M.setup(opts)
  config.setup(opts)

  local group = vim.api.nvim_create_augroup("AgenticNotify", { clear = true })
  vim.api.nvim_create_autocmd("TermOpen", {
    group = group,
    callback = function(ev)
      M.attach(ev.buf)
    end,
  })

  vim.api.nvim_create_autocmd("WinEnter", {
    group = group,
    callback = function()
      if not config.get().enabled then
        return
      end
      local buf = vim.api.nvim_get_current_buf()
      if vim.bo[buf].buftype == "terminal" then
        ensure_instance(buf, config.get())
        update_title_for_buf(buf, config.get())
      end
    end,
  })

  if config.get().enabled then
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.bo[buf].buftype == "terminal" then
        M.attach(buf)
      end
    end
  end
end

M._private = {
  normalize_terminal_line = normalize_terminal_line,
  get_last_non_empty_line = get_last_non_empty_line,
  get_last_non_empty_from_lines = get_last_non_empty_from_lines,
}

return M
