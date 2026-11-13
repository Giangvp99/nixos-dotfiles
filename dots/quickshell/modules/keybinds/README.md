# Keyboard shortcut reference

Implemented and validated on j4n9-proxmox, 2026-11-12.

Open with **Super + /** or the dashboard's **Keyboard shortcuts** button. Search
matches all query terms against the key combination, description, category,
submap and flags. The header follows the current mode/workspace; Mode & windows
filters the window-management category. The same navigation bindings apply to
the current mode as defined by modes.core; no additional per-mode actions are
invented by the reference.

- Down from search enters the list. Up/Down select rows, Home/End jump to bounds.
- Tab/Backtab cycle search, filter, Refresh, Close and the list.
- Escape closes and uses OverlayFocus to return an existing origin when possible.
- Rows are read-only. Enter on a row does not dispatch a binding or launch an app.
- Keys, descriptions, submaps and labels are plain text. There are no tooltips.

## Source and lifecycle

`BindingCatalog.qml` runs `hyprctl -j binds` when the view is created. It refreshes
on the compositor's configreloaded event and on Refresh. There is no polling.
The command is an argument array, independent of search text. Query text is
never passed to a process. Only one read runs at a time; a refresh during a read
queues one more read. A four-second deadline handles failed or stalled reads.
Errors clear stale results and offer Refresh.

`Keybindings.js` formats modifier bitmasks, keysyms/keycodes and repeat/release/
locked flags. It preserves duplicate bindings and submap information. Categories
are derived from descriptions and key types. Opaque Lua callback IDs are not
interpreted; missing descriptions appear as No description provided. Common Lua
bindings now declare descriptions at the source. Existing combinations/actions
and flags remain unchanged; Super + slash is the only new combination.

`KeybindContent.qml` virtualizes rows with ListView and stacks key/description
columns on narrow windows. `KeybindSheet.qml` uses Theme, Surface, OverlayMotion
and OverlayFocus. Closing unloads the content and cancels its child process.
Only the open flag survives a QML reload in production PersistentProperties;
search/filter/selection reset and bindings are read again. A fresh shell process
starts closed. Theme animation respects reducedMotion.

The production ShellRoot coordinates the reference with dashboard, launcher and
bar popups/notification center. Opening one closes the others without restoring
focus into a closing overlay. Audio OSD remains passive and independent.

Config.qml exposes keybindWidth=760 and keybindHeight=600. IPC supports:

```sh
qs ipc call keybinds open
qs ipc call keybinds close
qs ipc call keybinds status
```

## Validation

```sh
python3 dots/quickshell/tests/run-keybinds.py
lua dots/hypr/tests/modes.lua
luac -p dots/hypr/binds.lua
```

The GUI runner copies the production shell and injects a harness, retaining the
actual PersistentProperties and overlay handoff wiring. It registers separate
test shortcut app IDs and executes no binding actions. Run GUI fixtures serially
because they use Wayland keyboard focus.

Passed: modifier/keycode/catch-all parsing, missing descriptions, duplicates,
submaps/flags, search, category filtering, Up/Down/Home/End/Tab/Backtab, read-only
Enter, malformed JSON, failed command, timeout/cancel, 380x500 layout, real
source-content reload verified by a persistent generation counter, dashboard
help/launcher handoff and five open/close cycles. The final fixture log has no
QML runtime errors; existing missing backlight/fcitx/UPower warnings remain.

Native VM validation: Lua reload returned no config errors and preserved the
previous combinations and flags. The global dispatcher for quickshell:keybinds
opened the real catalog with 36 registered bindings. Toggling closed it, dashboard
handoff worked, and close destroyed its catalog. Images were inspected for the
compact fixture and native panel. Previous overlay state was restored. Physical
keyboard delivery was not synthesized separately from the global dispatcher.
All eight Mode Manager regression scenarios still pass.

qmllint reports metadata warnings for PanelWindow, GlobalShortcut, Loader.item
and Process ExitStatus; no syntax errors. git diff --check passes. No laptop,
Flake, Home Manager, NixOS module or package changes were made.

Multi-screen update: the panel and workspace header use a screen captured on
open. Session memory also keeps its name; missing outputs cancel restoration.
The live multi-screen fixture covers focus changes, handoff and removal. See
[MULTISCREEN](../../docs/MULTISCREEN.md).
