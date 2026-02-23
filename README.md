# agentic-notify.nvim

Notify when a terminal buffer inside Neovim needs input by updating the
**terminal tab title** (local or over SSH).

## Features

- Watches terminal buffers for configurable input markers/patterns.
- Updates the terminal tab title via OSC/tmux.
- Optional bell on input-needed events.
- Input-only state model (`N:TERM` and `N:INPUT TERM`).
- Simple commands to enable/disable/attach.

## Installation

### lazy.nvim

```lua
{
  "DanielTellier/agentic-notify.nvim",
  config = function()
    require("agentic-notify").setup({
      input_patterns = {
        "^%s*%-%->NEEDS_INPUT<%-%-%s*$",
      },
      ring_bell = true,
      title_backend = "auto",
    })
  end,
}
```

### Manual

- Place plugin file at: `~/.config/nvim/plugin/agentic-notify.lua`
- Place module files in: `~/.config/nvim/lua/agentic-notify/`

## Commands

- `:AgenticNotifyEnable` Enable detection and auto-attach to terminals.
- `:AgenticNotifyDisable` Disable detection and clear state.
- `:AgenticNotifyAttach` Attach to the current terminal buffer.
- `:AgenticNotifyStatus` Show current status.

## Title Convention

- Base title: `N:TERM`
- Input title: `N:INPUT TERM`

`N` is a stable per-terminal instance number assigned in the order terminals
are detected.

## Configuration

```lua
require("agentic-notify").setup({
  enabled = true,
  input_patterns = {
    "^%s*%-%->NEEDS_INPUT<%-%-%s*$",
  },
  title_backend = "auto",
  ring_bell = false,
  clear_on_term_enter = true,
  clear_on_output = false,
  debug_output = false,
})
```

### Notes

- `input_patterns` are Lua patterns matched against the most recent non-empty
  terminal output line.
- Recommended marker for agentic tools: `-->NEEDS_INPUT<--` (pattern:
  `^%s*%-%->NEEDS_INPUT<%-%-%s*$`).
- Default pattern is `^%s*%-%->NEEDS_INPUT<%-%-%s*$` so leading/trailing
  whitespace around the marker line is allowed.
- There is no resolve marker/state anymore; input is cleared only by:
  `clear_on_term_enter` (entering the terminal buffer) or `clear_on_output`
  (any subsequent non-empty output).
- `title_backend`:
  - `auto`: use tmux passthrough when `$TMUX` is set, otherwise OSC.
  - `osc`: write OSC title escape directly.
  - `tmux`: wrap OSC in tmux passthrough.
- `debug_output`: when `true`, logs each inspected terminal output line and
  whether it matched an input pattern.
- Titles update immediately on state changes, even if the current window is not
  a terminal.
- When the last tracked terminal closes, the title is restored to a best-effort
  original title.

## Required Setup Step

Configure your agentic tool with an end-marker skill that appends
`-->NEEDS_INPUT<--` as the final output line. This step is required so
`agentic-notify.nvim` can detect that input is needed and switch the title to
`N:INPUT TERM`.

```markdown
---
name: end-marker
description: Ensure agentic AI tools append an explicit marker as the last line of their output, so watchers can detect completion and readiness for input.
---

# End Marker Skill

## Purpose
Append a **single, explicit, unique marker line** as the **last line** of every response.

## Marker Format
Use this exact line (all caps) as the final line of every response:

```
-->NEEDS_INPUT<--
```

Important: no spaces are allowed in the marker line. Emit the marker exactly as `-->NEEDS_INPUT<--`.

## Rules
- The marker must be the **last line** of every response.
- The marker must appear on a **standalone line** with nothing else on that line.
- Do not localize or alter the marker text.
```

## License

MIT
