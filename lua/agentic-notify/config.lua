local M = {}

M.defaults = {
  enabled = true,
  input_patterns = {
    "^%s*%-%->NEEDS_INPUT<%-%-%s*$",
  },
  update_title = true,
  title_backend = "auto",
  ring_bell = false,
  clear_on_term_enter = true,
  clear_on_output = false,
  debug_output = false,
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
