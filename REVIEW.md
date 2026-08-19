# Adversarial Code Review — 19 Aug 2026

Full-repo review · 41 files · 6 parallel agents · deduplicated & verified

## Critical

- [x] ~~**Screensaver script passes Lua API syntax to hyprctl IPC** — `hypridle.nix:78-82`~~
  FALSE POSITIVE: Hyprland's `hyprctl dispatch` wraps args in `return hl.dispatch(...)` — Lua syntax is correct.

- [x] **init.lua crashes all config if io.popen returns nil** — `hyprland/init.lua:12`
  `io.popen("ls " .. dir .. "*.lua"):lines()` chains on the return value without nil check. Fork failure → "attempt to index a nil value" → zero keybinds, no rules, no monitor config. Handle also never closed. Fix: assign to variable, nil-check, close after loop.

## High

- [ ] **Kitty remote control on world-accessible /tmp socket** — `apps/kitty.nix:48-49`
  `allow_remote_control = "yes"` with `listen_on = "unix:/tmp/kitty-socket"`. Any local process can inject keystrokes, read terminal content, or spawn processes via `kitten @`. Fix: move to `$XDG_RUNTIME_DIR/kitty-socket`.

- [x] ~~**Browser chooser uses Lua syntax in hyprctl dispatch** — `apps/browser-chooser.nix:18`~~
  FALSE POSITIVE: Same as screensaver — Lua syntax is correct for this Hyprland version.

## Medium

- [ ] **SUPER+O crashes if monitor is nil during hotunplug** — `hyprland/binds.lua:145-146`
  `w.monitor` used without nil guard → `mon.width` crashes. The webcam handler in rules.lua:106 correctly guards this. Add `if mon == nil then return end`.

- [ ] **monitor.removed applies 1.25x scale on ThinkPad** — `hyprland/events.lua:66-79`, `hyprland.nix:10`
  `ctx.default_scale` is hardcoded to 1.25 for all hosts. ThinkPad uses scale 1. Unplugging an external monitor re-enables eDP-1 at wrong scale. Fix: parameterize `defaultScale` per host or read from monitor config.

- [ ] **Noctalia popups unfloat solo kitty windows** — `hyprland/events.lua:10-28`, `hyprland/rules.lua:75`
  `window.open` handler only excludes `hyprmon` and `webcam` titles, not Noctalia popups. Opening a wallpaper picker or panel abruptly tiles the kitty. Fix: also exclude `dev.noctalia.Noctalia` class.

- [ ] **Voice input wav in /tmp enables wtype injection** — `hyprland.nix:200-201`
  `/tmp/voice-input.wav` at a predictable path. Between recording and transcription, a local process could swap the wav → attacker-chosen text typed via `wtype` into the focused window. Fix: use `$XDG_RUNTIME_DIR`.

- [ ] **Docker group added unconditionally in core module** — `nixos/core/default.nix:75`
  User is added to `docker` group even on hosts without `docker.nix`. Docker group = root-equivalent access. Fix: move to `docker.nix`.

- [ ] **Zoom overlay may lose QT_SCALE_FACTOR from double-wrapping** — `hosts/framework-16/default.nix:9-12`
  Overlay calls `wrapProgram` in `postInstall`; if upstream zoom-us also wraps, the second call replaces the first and the scale factor is lost. Fix: use `overrideAttrs` with env vars or `makeWrapper` flags.

- [ ] **Framework audio fix uses fragile sleep instead of polling** — `hosts/framework-16/default.nix:108-127`
  Hardcoded `sleep 2` before `wpctl status` races against ALSA device enumeration. `DEVICE_ID` ends up empty on fast boot. Fix: poll in a loop until device appears.

## Low

- [ ] **sops-nix and claude-desktop inputs don't follow nixpkgs** — `flake.nix:24-25`
  Both bring their own nixpkgs copy, inflating closure and risking library mismatches.

- [ ] **TOML gsub accumulates duplicate [bar.main] sections** — `hyprland/binds.lua:123`
  Pattern assumes `position` immediately follows section header. If other keys exist, old section is never removed; duplicates pile up on each toggle.

- [ ] **context.lua crashes on empty /etc/hostname** — `hyprland.nix:25` (generated)
  `f:read("*l"):match(...)` chains on potentially nil return. Unlikely on NixOS but nil guard is missing.

- [ ] **Orphaned hyprmon references** — `hyprland/events.lua:12,48`, `hyprland/rules.lua:74`
  `hyprmon` removed from packages in 6e2fd6f but title checks and floating rules remain. Dead code.

- [ ] **Stale hyprlock PAM service** — `nixos/optional/desktop.nix:159`
  PAM entry for hyprlock declared but hyprlock is not installed (noctalia replaced it).

- [ ] **Dead opacity variables in walker.nix** — `home/optional/desktop/walker.nix:10-11`
  `opacity` and `bgOpacity` bound but never interpolated.

- [ ] **Steam ports open on all interfaces** — `nixos/optional/steam.nix:8-9`
  Remote Play and local transfer firewall ports open on all interfaces including untrusted networks.

- [ ] **Selene lints as Lua 5.1, runtime is Lua 5.4** — `selene.toml:1`, `.luarc.json:2`
  Latent: no 5.4 features used yet, but linter will reject them when added.
