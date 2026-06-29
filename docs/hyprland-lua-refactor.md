# Hyprland Lua Refactor

Reference for migrating Hyprland config from hyprlang (Nix-generated) to Lua (0.55+).

## Scripts eliminated by Lua

These shell scripts are fully replaceable with native `hl.on()` event handlers and
direct compositor object access. No more socat, jq, or hyprctl IPC parsing.

### `unfloatOnNewWindow` -> `hl.on("window.open", ...)`

- [ ] Replace socat IPC listener with `hl.on("window.open", callback)`
- [ ] Query floating kitties via `ws.windows` iterator instead of `hyprctl clients -j | jq`
- [ ] Unfloat via `hl.dsp.window.toggle_floating(w)` instead of `hyprctl dispatch`

### `autoMirror` -> `hl.on("monitor.added/removed", ...)`

- [ ] Replace socat listener with `hl.on("monitor.added", ...)` and `hl.on("monitor.removed", ...)`
- [ ] Handle config reload via appropriate event instead of parsing `configreloaded` text
- [ ] Use `hl.monitor()` for runtime monitor config instead of `hyprctl keyword monitor`
- [ ] Eliminate self-deduplication logic (`pgrep`/`kill` of other instances)
- [ ] Replace `sleep` race-condition hacks with timer callbacks

### `popWindow` -> inline Lua keybind

- [ ] Replace `hyprctl activewindow -j | jq` with `hl.focused_window()`
- [ ] Access `.pinned`, `.floating` as native Lua properties
- [ ] Use `hl.dsp.window.*` dispatchers directly

### `screensaver launcher` -> Lua monitor iteration

- [ ] Replace `hyprctl monitors -j | jq` with `hl.monitors()` iteration
- [ ] Launch kitty instances via `hl.exec_cmd()`

## Scripts simplified by Lua

These still need external tools (slurp, grim, wf-recorder, etc.) but benefit from
Lua's in-process state and direct compositor access.

### `terminalHere`

- [ ] Move workspace-empty check and conditional float/center into Lua
- [ ] Keep `/proc` CWD traversal as a small helper called via `hl.exec_cmd`

### `screenshot` + `toggleMenu` (shared screenshot logic)

- [ ] Deduplicate screenshot code between standalone `screenshot` and `toggleMenu`
- [ ] Simplify cursor-hide with `hl.dsp.cursor.move()` instead of `hyprctl dispatch movecursor`
- [ ] External tools (slurp, grim, wl-copy, notify-send, satty) still required

### `toggleMenu` state management

- [ ] Replace `pgrep -x wf-recorder` with Lua variable tracking recording state
- [ ] Replace `/tmp/current-recording` temp file with in-process state
- [ ] Webcam toggle state can be a Lua variable instead of `pgrep -f "mpv.*title=webcam"`

### `voiceInput`

- [ ] Replace `pgrep -f "pw-record.*voice-input"` toggle with Lua state variable
- [ ] External tools (pw-record, whisper-cpp, wtype) still required

## Repetitive config Lua collapses

### Workspace bindings (20 lines -> 4)

- [ ] Replace 10 workspace-switch + 10 move-to-workspace bindings with a `for` loop:
  ```lua
  for i = 1, 10 do
      local key = i == 10 and "0" or tostring(i)
      hl.bind("SUPER+" .. key, hl.dsp.workspace.change(i))
      hl.bind("SUPER+SHIFT+" .. key, hl.dsp.workspace.move_to(i))
  end
  ```

### `floatingPopupRules` helper

- [ ] Replace Nix string-interpolation function with a Lua function calling the rules API directly

### Repeated opacity window rules

- [ ] Collapse repeated `opacity` rules (Nautilus, Spotify, Slack) into a loop over a class list

## New capabilities unlocked

- [ ] **Custom layouts**: `hl.register_layout()` — define tiling algorithms beyond dwindle
- [ ] **Reactive window rules**: `hl.on("window.open", ...)` with runtime logic (time of day, monitor, other windows)
- [ ] **Timer API**: proper callbacks instead of `sleep` hacks
- [ ] **In-process state**: replace state files and `pgrep` checks with Lua variables

## Nix integration to solve

Moving to Lua means finding alternatives for things Nix currently handles at
build time.

- [ ] **Color theming**: Stylix colors (`config.lib.stylix.colors.base0D`) need to reach Lua — either template the `.lua` file through Nix, or read colors from a generated file/env var at runtime
- [ ] **Per-host overrides**: Replace `lib.mkForce` with either Lua conditionals (`if hostname == "framework-16"`) or Nix-generated host-specific Lua snippets
- [ ] **Package paths**: `${pkgs.jq}/bin/jq` style Nix store paths — either rely on `PATH` or have Nix template paths into the Lua file
- [ ] **Hypridle**: Determine if hypridle config stays in Nix or also moves to Lua

## Summary

| Current pain point | Lua benefit |
|---|---|
| 7 shell scripts with socat/jq/hyprctl IPC | 3-4 scripts eliminated entirely, replaced by `hl.on()` event handlers with direct object access |
| Race conditions requiring `sleep` calls | Timer API with proper callbacks |
| State via temp files and `pgrep` | In-process Lua variables |
| 22 repetitive workspace bindings | `for` loop, 4 lines |
| Duplicated screenshot logic (standalone + menu) | Shared Lua functions |
| Self-deduplicating scripts (`pgrep -f` self) | Event handlers registered once, no process management |
