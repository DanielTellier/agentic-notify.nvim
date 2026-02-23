local M = {}

M.defaults = {
  enabled = true,
  input_patterns = {
    "waiting for input",
    "press enter",
    "press any key",
    "^%s*>%s*$",
    "^%s*:%s*$",
  },
  update_title = true,
  title_backend = "auto",
  ring_bell = false,
  clear_on_term_enter = true,
  clear_on_output = false,
}

local state = {
  opts = vim.deepcopy(M.defaults),
}

function M.setup(opts)
  state.opts = vim.tbl_deep_extend(
    "force",
    vim.deepcopy(M.defaults),
    opts or {}
  )
  return state.opts
end

function M.get()
  return state.opts
end

return M
