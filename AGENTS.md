# agentic-notify.nvim

## Purpose
`agentic-notify.nvim` updates the **terminal tab title** (local or over SSH) when
Neovim terminal buffers need input. It uses OSC/tmux title sequences and does
not alter Neovim’s internal UI title.

## Behavior Summary
- Assigns a stable instance number per terminal buffer (first-seen order).
- Title format:
  - Base: `N:TERM`
  - Input: `N:INPUT TERM`
- Title updates happen immediately on state changes.
- When the last tracked terminal closes, the title is restored to a best-effort
  original value.
- Optional bell on input transition.

## Key Files (mirrors multi-tree.nvim structure)
- `plugin/agentic-notify.lua`: command registration and plugin guard.
- `lua/agentic-notify/init.lua`: main logic (attach, detection, title updates).
- `lua/agentic-notify/config.lua`: defaults + setup.
- `lua/agentic-notify/state.lua`: buffer state + instance ids.

## Configuration
```lua
require("agentic-notify").setup({
  input_patterns = {
    "waiting for input",
    "press enter",
    "press any key",
    "^%s*>%s*$",
    "^%s*:%s*$",
  },
  title_backend = "auto", -- auto | osc | tmux
  ring_bell = false,
  clear_on_term_enter = true,
  clear_on_output = false,
})
```

## Testing
Minimal headless checks are in `tests/`:
- `tests/minimal_init.lua`
- `tests/agentic_notify_spec.lua`

Run:
```bash
nvim --headless -u tests/minimal_init.lua
```
