# Phase 0–1: Proxmox validation

Validated on 2026-11-10, host `j4n9-proxmox`.

## Environment and baseline

- Hyprland 0.55.4; Quickshell 0.3.1.
- Virtual-1: 1920×1080 at 60 Hz, scale 1.2; top reserved area 50 logical px.
- User configuration resolves directly to `/etc/nixos/dots/hypr/hyprland.lua`
  and `/etc/nixos/dots/quickshell`. Keep these live source paths.
- Hyprland `configerrors` was empty before changes and after reload.
- Main Quickshell PID stayed 4183 through automatic QML reloads.
- One process snapshot during development: RSS 208288 KiB, lifetime CPU 0.1%.
  This is not an idle benchmark or evidence of a performance improvement.

## Changes

- `config/{Theme,Config,Animations}.qml`: shared border, spacing, control height,
  icon-font tokens; reduced-motion switch; network label bound. Active title stays
  opt-in, matching the formerly empty center region.
- `components/{Surface,IconButton,StatusText}.qml`: reusable panel surface,
  constrained labels, keyboard activation/focus border, tooltips, shared height.
- `modules/bar/{Bar,BarLeft,BarCenter,BarRight}.qml`: bounded layout, horizontally
  scrollable status group on narrow screens, remove unused required monitor
  property, honor audio visibility, optional active title.
- `modules/bar/widgets/RunningApps.qml`: horizontal ListView, click activation,
  keyboard activation, window-title tooltip, active/urgent/minimized indicators.
  No close-on-middle-click shortcut is introduced.
- `modules/bar/widgets/ModeIndicator.qml`: use ModeService as the QML mode lookup.
- `modules/bar/widgets/{Audio,Battery,Clock,Date,PowerMenu,Wifi}.qml`: shared sizing,
  natural battery-label width, bounded SSID, hide Wi-Fi control without an adapter.
  This does not implement an Ethernet indicator.
- `modules/bar/popups/{CalendarPopup,PowerPopup,WifiPopup}.qml`: implicit window
  sizes, common panel styling, Escape handling, space for Wi-Fi unavailable state.
- `../hypr/binds.lua` and `services/HyprlandService.qml`: preserve origin in a
  `minimized-from-<workspace-selector>` compositor tag. Restore removes only
  minimize tags, retaining mode tags. Old unmarked windows fall back to the
  current workspace when original state is unavailable. QML uses Lua dispatcher
  expressions and normalizes addresses to `0x…`.
- `services/PowerService.qml`: logout uses Lua dispatcher syntax.

No laptop-specific configuration, Nix configuration, package or system service
was changed. Existing staged and unrelated working-tree changes were retained.

## Validation results

- Automatic Quickshell reload: configuration loaded successfully after edits.
- Explicit Hyprland reload: no configuration errors.
- Lua 5.4 `luac -p`: passed for modified bindings.
- Temporary Lua mock test invokes the real Super+M callback, reloads its file,
  changes the current workspace, and verifies origin restore plus preservation
  of unrelated tags: passed.
- Temporary QML harness calls the real HyprlandService against a temporary Kitty
  window. After minimizing and a Hyprland config reload, restore returns to the
  original workspace, removes minimize markers and keeps a mode-return tag:
  passed. Temporary processes/windows were closed and original focus restored.
- Existing launcher global shortcut opens and closes: passed; no launcher source
  was changed.
- Actual Bar instantiated at 640 logical px in a temporary harness: loaded;
  screenshot reviewed, no left/right overlap with the available VM controls.
- Main bar at 1920×1080/scale 1.2: screenshot reviewed.
- `git diff --check`: passed.
- `qmllint` with installed Qt and Quickshell import paths: no syntax errors;
  warnings remain for Quickshell's PanelWindow metadata, popup enum type metadata
  and pre-existing unqualified calendar delegate access. Runtime loading passed.

Artifacts for this session are in `/tmp`: `ui-qmllint.log`,
`proxmox-bar-phase1.png`, `proxmox-bar-narrow.png`,
`proxmox-launcher-phase1.png`. They are temporary, not repository assets.

## Remaining limitations

- VM lacks `intel_backlight`, UPower activation and the runtime Fcitx language
  file. Existing unavailable-data warnings remain; no system setup was changed.
- Wi-Fi connection, physical battery/backlight, real multi-monitor topology and
  laptop behavior are not validated on this VM.
- Multi-screen bars, popup coordination, complete keyboard navigation within
  popup action lists, icon lookup caching and a full performance benchmark remain
  follow-up work. No GPU-performance improvement is claimed.
- Reboot/shutdown/logout were not executed. Lock-handler behavior is unverified.
- Lua mode definitions remain separate from the QML lookup; no generated config
  or build-time bridge was introduced.

## Future checks

Keep each change live in the source tree. Inspect `qs log -t 40` after saves;
check `hyprctl configerrors` after Lua reloads. Repeat restore/tag tests when
changing workspace or minimize behavior. Test on Proxmox before considering
laptop adoption. Do not run a NixOS switch for these QML/Lua edits.

Later topbar work removed all widget tooltips at the user's request and added
shared popup lifecycle/keyboard handling. For the current behavior and validation,
see `../modules/bar/popups/README.md` and `../modules/bar/widgets/README.md`.
