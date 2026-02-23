local M = {}

M.buffers = {}
M.title = {
  original = nil,
  last = nil,
  last_buf = nil,
}
M.next_instance_id = 1
M.free_instance_ids = {}

function M.reset()
  M.buffers = {}
  M.title.original = nil
  M.title.last = nil
  M.title.last_buf = nil
  M.next_instance_id = 1
  M.free_instance_ids = {}
end

function M.ensure_buffer(buf)
  if not M.buffers[buf] then
    M.buffers[buf] = {
      needs_input = false,
      attached = false,
      instance_id = nil,
      closed = false,
    }
  end
  return M.buffers[buf]
end

function M.remove_buffer(buf)
  M.buffers[buf] = nil
end

return M
