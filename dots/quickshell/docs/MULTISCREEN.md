# Multi-screen shell routing

Implemented on j4n9-proxmox, 2026-11-12. Scope: Quickshell UI only; monitor rules,
laptop/NixOS configuration and packages remain unchanged.

## Policy

- `Bars.qml` creates one `Bar.qml` per Quickshell screen through Variants. Each
  bar reads its monitor's active workspace, mode, running apps and window title.
- `ScreenService` chooses an explicit screen passed by an overlay handoff,
  otherwise the initiating item's screen, otherwise the focused monitor's screen,
  and finally the first available screen. Monitor lookup tracks model changes so
  asynchronous screen/IPC discovery does not leave a bar without workspace data.
- Launcher, dashboard and keybind reference capture that choice on open through
  `OverlayScreen`. Moving focus or calling open again retains it until close.
  Dashboard/keybind content uses the captured screen's workspace context.
- Dashboard handoff to launcher/keybinds passes its captured screen. Notification
  handoff selects the center attached to that screen's bar.
- Bar popups stay anchored to their originating window. Screen loss/change or
  origin destruction closes the popup and cancels focus restoration.
- OSD captures the focused screen on each confirmed audio change. It stays there
  until another change or dismissal. Screen loss hides it and stops its timer.
- Removing an overlay's output closes it with close(false). Dashboard/keybinds
  persist the screen name with their open flag for QML reload; a missing stored
  output cancels restoration. An initially empty name supports older memory.

Surface geometry uses Qt logical units and existing viewport clamps. This does
not change widget width, fonts, colors, animation tokens or add tooltips. Passive
notification toasts retain their existing placement policy; notification-center
popups use their bar screen.

## Per-screen state

SystemMonitor, audio, network, battery, input method and notification history
remain shared singletons. A new bar does not create another telemetry sampler.

HyprlandService supplies a sorted workspace-specific toplevel list. Minimized
windows are appended only on their recorded origin workspace's monitor, with the
IPC monitor ID as fallback. The legacy focused-workspace model remains available.
Window metadata is fetched initially and coalesced after openwindow,
movewindowv2, changefloatingmode and configreloaded events; there is no polling.
This matters because newly discovered toplevels may initially have an empty
lastIpcObject. A small address-only focus history supports inactive-screen titles.
The event names follow the [Hyprland IPC documentation](https://wiki.hypr.land/ipc/).

NotificationState registers each bar's center and selects by anchorScreen.
PopupState still permits one interactive popup globally; centerOpen reflects any
visible registered center. Removing one bar cannot clear another center's state.

Wi-Fi popups request scanning as wifi-popup:<screen name>. This prevents closing
a popup on one bar from canceling a new popup's scanner on another screen. The
dashboard keeps its own dashboard-network owner. Omitted service owner remains
the legacy wifi-popup token for compatibility.

## Tests

Run on the VM with an existing kitty and Quickshell; no installation is needed:

```sh
python3 dots/quickshell/tests/run-multiscreen.py
python3 dots/quickshell/tests/run-audio-osd.py
python3 dots/quickshell/tests/run-system-widgets.py
python3 dots/quickshell/tests/run-keybinds.py
python3 dots/quickshell/tests/run-network-controls.py
```

Run GUI tests sequentially. The native multi-screen test requires one original
monitor. It copies the production shell, injects a diagnostic harness, creates
headless outputs and one disposable terminal, and applies temporary in-memory
monitor rules. It moves the pointer as well as focus to respect follow_mouse.
Avoid interacting with the desktop during the run.

Passed on j4n9-proxmox:

- One -> two -> one screens, primary scale 1.2, headless scales 1 and 2.
- Per-screen mode/workspace and running-window isolation while focus moves.
- Minimized test window remains listed on its origin monitor, without duplicates
  on the other bar; the test changes only its own window/tags.
- Launcher/dashboard/keybinds open on focus, retain capture across focus changes,
  and fit their viewport at both tested scales.
- Bar origin overrides global focus; dashboard -> keybind handoff retains screen.
- Calendar popup follows its anchor screen; notification centers register on each
  bar and unregister on removal.
- Dashboard retains its captured screen across an actual source-content reload
  while focus is elsewhere; the fixture uses a persistent generation counter.
- Mock OSD follows the focused screen and disappears when that output is removed.
- Removing an output closes launcher, dashboard, keybinds, popup and center,
  destroys the extra bar, and cancels center-open state.
- Cleanup removes test outputs/windows, reloads original monitor rules and restores
  original client workspaces/tags, focus and pointer.

OSD, system widgets, keybinds (including missing-output restoration) and network
controls regression fixtures pass. The system-widgets runner now resolves the
current compositor instance instead of inheriting a stale socket signature.

No QML exceptions were found in the final runs. Missing backlight/fcitx/UPower
warnings remain on the VM. Quickshell's backend also emits "Got removal ... not
previously tracked" during some rapid headless removal/reload sequences; the
routing/cleanup assertions pass. qmllint has dynamic-type/library metadata
warnings but no syntax errors; git diff --check passes.

Images in /tmp/multiscreen-dashboard-scale-{1,2}.png show both the real shell bar
and the disposable fixture bar while testing. After cleanup, the native session
has one Virtual-1 output at scale 1.2, one 1600x50 logical bar and no config errors.
Physical cable hotplug, monitor rotations and fractional scale on a physical
external display have not been tested; no laptop deployment was performed.
