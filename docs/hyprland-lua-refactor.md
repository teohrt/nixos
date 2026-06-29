# Hyprland Lua Refactor

Reference for migrating Hyprland config from hyprlang (Nix-generated) to Lua (0.55+).

Phases are ordered so each one builds on the last. Within each phase, tasks are
ordered by simplicity (easiest first). Every phase should leave you with a
working desktop — no phase depends on a later one.

---

## Getting Hyprland 0.55+ running

Lua config requires Hyprland >= 0.55. Getting the right version to actually
run turned out to be the first major hurdle. Here's what we tried and why each
approach failed or succeeded.

### Attempt 1: Hyprland flake (failed — GPU driver mismatch)

Used the official `hyprland` flake input (`github:hyprwm/Hyprland`). The flake
builds Hyprland against its own mesa/GPU drivers from a separate nixpkgs pin.
At runtime, NixOS uses `/run/opengl-driver` from the *system* mesa. The mismatch
caused the `start-hyprland` wrapper to crash immediately on startup. SDDM saw
the session exit and looped back to the login screen.

**Removed:** flake input, 59 transitive inputs, cachix, NixOS module overlay.

### Attempt 2: nixpkgs-unstable (failed — wrong version in PATH)

Switched `programs.hyprland.package` in `desktop.nix` to `pkgs-unstable.hyprland`.
This put 0.55.x in the *system* PATH, but home-manager's
`wayland.windowManager.hyprland.enable = true` also installs a Hyprland binary
into the *user profile* (`/etc/profiles/per-user/trace/bin/`). Since user
profile takes priority over system PATH, the home-manager default
`pkgs.hyprland` (stable nixpkgs, 0.52.1) shadowed the 0.55 system binary.

**Result:** Hyprland ran but was 0.52.1, which doesn't support Lua config.
It silently fell back to the generated `.conf` file.

### Attempt 3: pinned nixpkgs-hyprland (failed — same shadowing issue)

Added `nixpkgs-hyprland` input pinned to a specific commit with Hyprland 0.55.4.
Set `programs.hyprland.package = pkgs-hyprland.hyprland` in `desktop.nix` and
passed `pkgs-hyprland` to NixOS modules via `specialArgs`. Same problem as
attempt 2 — only fixed the NixOS system-level package, not home-manager.

### Attempt 4: pass pkgs-hyprland to home-manager (current)

The fix requires **both** levels to use the pinned package:

1. `flake.nix`: added `pkgs-hyprland` to home-manager's `extraSpecialArgs`
2. `hyprland.nix`: set `wayland.windowManager.hyprland.package = pkgs-hyprland.hyprland`

This ensures the user-profile binary is also 0.55.4, so Lua config loads.

**Lesson:** When using home-manager with `wayland.windowManager.hyprland`,
the HM module installs its own binary that shadows the NixOS system package.
Both must be set explicitly when pinning to a non-default version.

---

## Phase 0: Foundation (do first — everything else depends on this)

Decide how Nix and Lua coexist. This is the only design decision that blocks
everything else. Get it wrong and you'll redo work.

- [ ] **Choose Nix-to-Lua integration strategy**
  - Option A: Nix templates the `.lua` file (like you currently template `.conf`) — keeps `${config.lib.stylix.colors.base0D}` working, but tightly couples Nix and Lua
  - Option B: Nix generates a small `theme.lua` / `host.lua` data file, Lua `require()`s it — cleaner separation, Lua file is a real `.lua` you can edit/test outside Nix
  - Option C: Nix sets env vars, Lua reads `os.getenv()` — simplest but least structured
- [ ] **Decide on package path strategy** — `${pkgs.slurp}/bin/slurp` Nix interpolation vs. relying on `PATH` (scripts that call external tools need this resolved)
- [ ] **Decide per-host override strategy** — Lua conditionals on hostname vs. Nix-generated per-host Lua snippets
- [ ] **Decide if hypridle stays in Nix** — it has its own config format, no clear Lua benefit, probably leave it

---

## Phase 1: Port static config (low risk, mechanical)

Pure translation of settings — no behavior changes. If something breaks, it's a
typo, not a design problem. Validates that the Phase 0 integration works.

- [ ] General settings (gaps, borders, layout, misc)
- [ ] Input settings (kb_layout, sensitivity, repeat rate, touchpad)
- [ ] Decoration (rounding, blur)
- [ ] Animations (bezier curves, animation rules)
- [ ] XWayland settings
- [ ] Environment variables
- [ ] Monitor config (including per-host overrides for framework-16/thinkpad)
- [ ] Dwindle layout settings
- [ ] Layer rules
- [ ] `exec-once` startup commands

---

## Phase 2: Quick wins (low risk, immediate payoff)

Patterns where Lua's programmability directly collapses repetition. Small,
isolated changes that are easy to verify.

### Workspace bindings (20 lines -> 4)

- [ ] Replace 10 workspace-switch + 10 move-to-workspace bindings with a loop:
  ```lua
  for i = 1, 10 do
      local key = i == 10 and "0" or tostring(i)
      hl.bind("SUPER+" .. key, hl.dsp.workspace.change(i))
      hl.bind("SUPER+SHIFT+" .. key, hl.dsp.workspace.move_to(i))
  end
  ```

### Repeated window rules

- [ ] Collapse opacity rules (Nautilus, Spotify, Slack) into a loop over a class list
- [ ] Replace `floatingPopupRules` Nix helper with a Lua function calling rules API directly
- [ ] Collapse workspace assignment rules into a table-driven loop

### Remaining keybindings

- [ ] Port all static keybinds (`bindd`, `bindel`, `bindm`) to `hl.bind()` calls

---

## Phase 3: Inline simple scripts (low risk, high impact)

Scripts where the entire logic is "query compositor state, act on it" — no
external tools needed. These become Lua keybind handlers.

### `popWindow` -> inline keybind handler

- [ ] Replace `hyprctl activewindow -j | jq` with `hl.focused_window()`
- [ ] Access `.pinned`, `.floating` as native Lua properties
- [ ] Use `hl.dsp.window.*` dispatchers directly
- [ ] Delete the `writeShellScript` block

### `terminalHere` -> mostly inline

- [ ] Move workspace-empty check into Lua (`#workspace.windows == 0`)
- [ ] Move conditional float/center/resize into Lua dispatchers
- [ ] Keep `/proc` CWD traversal as a small shell helper called via `hl.exec_cmd`

### `screensaver launcher` -> Lua monitor iteration

- [ ] Replace `hyprctl monitors -j | jq` loop with `hl.monitors()` iteration
- [ ] Check screensaver state as Lua variable instead of file existence check
- [ ] Launch kitty instances via `hl.exec_cmd()`

---

## Phase 4: Replace IPC listener scripts (medium risk, highest impact)

These are the biggest wins — eliminating long-running socat subprocesses that
parse raw IPC text. But they're also the most behavior-critical. Test each one
in isolation before moving on.

### `unfloatOnNewWindow` -> `hl.on("window.open", ...)`

- [ ] Register `hl.on("window.open", callback)` handler
- [ ] Query floating kitties via workspace window iterator
- [ ] Unfloat via `hl.dsp.window.toggle_floating(w)`
- [ ] Handle title exclusions (hyprmon, webcam) in the callback
- [ ] Remove socat process from `exec-once`
- [ ] Test: open terminal on empty workspace (should float), open second window (terminal should unfloat)

### `autoMirror` -> `hl.on("monitor.added/removed", ...)`

- [ ] Register `hl.on("monitor.added", ...)` handler
- [ ] Register `hl.on("monitor.removed", ...)` handler
- [ ] Handle config reload event (NixOS rebuild re-applies monitor setup)
- [ ] Use `hl.monitor()` for runtime monitor config instead of `hyprctl keyword`
- [ ] Replace `sleep` race-condition hacks with timer callbacks
- [ ] Noctalia bar refresh via timer instead of `sleep 0.3` / `sleep 0.2`
- [ ] Remove socat process and self-dedup logic from `exec-once`
- [ ] Test: hotplug external monitor, close lid, NixOS rebuild with monitor attached

---

## Phase 5: Simplify stateful scripts (medium risk, moderate impact)

These scripts still need external tools (slurp, grim, wf-recorder, mpv,
whisper-cpp) but benefit from Lua's in-process state and shared functions.

### Deduplicate screenshot logic

- [ ] Extract shared screenshot function used by both `Super+S` and toggle menu
- [ ] Simplify cursor-hide with `hl.dsp.cursor.move()` instead of `hyprctl dispatch movecursor`

### `toggleMenu` state management

- [ ] Track recording state as Lua variable instead of `pgrep -x wf-recorder`
- [ ] Track recording file path in Lua instead of `/tmp/current-recording`
- [ ] Track webcam state as Lua variable instead of `pgrep -f "mpv.*title=webcam"`
- [ ] External tool calls (walker, wf-recorder, brightnessctl, mpv, wpctl) remain as `hl.exec_cmd`

### `voiceInput` state management

- [ ] Track recording-in-progress as Lua variable instead of `pgrep -f "pw-record.*voice-input"`
- [ ] External tool calls (pw-record, whisper-cpp, wtype) remain as `hl.exec_cmd`

### Screensaver toggle state

- [ ] Replace `~/.local/state/screensaver-off` file with Lua variable

---

## Phase 6: Explore new capabilities (optional, after everything works)

Things that weren't possible before Lua. Only pursue these once the migration
is stable.

- [ ] **Custom layouts**: `hl.register_layout()` — experiment beyond dwindle
- [ ] **Reactive window rules**: runtime logic in `hl.on("window.open", ...)` (e.g., different behavior based on time of day, which monitor, what else is running)
- [ ] **Timer-based automation**: periodic tasks, delayed actions without shell `sleep`

---

## Summary

| Current pain point | Lua benefit |
|---|---|
| 7 shell scripts with socat/jq/hyprctl IPC | 3-4 scripts eliminated entirely, replaced by `hl.on()` event handlers with direct object access |
| Race conditions requiring `sleep` calls | Timer API with proper callbacks |
| State via temp files and `pgrep` | In-process Lua variables |
| 22 repetitive workspace bindings | `for` loop, 4 lines |
| Duplicated screenshot logic (standalone + menu) | Shared Lua functions |
| Self-deduplicating scripts (`pgrep -f` self) | Event handlers registered once, no process management |
