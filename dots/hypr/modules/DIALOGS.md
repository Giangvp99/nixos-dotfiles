# Temporary dialog sizing

`dialogs.lua` is loaded by `rules.lua` and uses the installed Hyprland Lua
window-rule API. It adds no event polling, background process or package.
[API reference](https://wiki.hypr.land/configuring/core/rules/window-rules/).

| Kind | Initial size | Maximum size |
| --- | --- | --- |
| File chooser / Save As / Open | 66% monitor width × 70% height | 86% × 80% |
| Downloads / download progress | 52% × 46% | 86% × 80% |
| Modal, portal, recognized confirmation | Natural requested size | 86% × 80% |

Floating dialogs are centered in the usable area; the compositor accounts for
the owning monitor's scale, origin and reserved topbar space. No fixed desktop
resolution, monitor name or workspace is applied. No minimum size is forced;
small confirmation windows stay small. Users can still move and resize dialogs
within the maximum size. Sizes apply when a new window maps; reopen an already
open picker to apply the new initial size.

Recognition uses native `modal`, known xdg-desktop-portal classes, or an already
floating toplevel plus an anchored canonical file/download/confirmation title.
The floating-title fallback is needed because the tested Qt Wayland dialogs do
not advertise modal to the compositor. English and common Vietnamese file titles
are included. A normal tiled browser page/main window is not floated just because
its title says Save As/Downloads. The float-terminal scratchpad remains untouched.

The lists and sizes are centralized at the top of `dialogs.lua` for additional
application-specific/localized titles. These rules do not resize embedded browser
menus, download bubbles, Quickshell layer popups or unmanaged xdg_popup surfaces;
those are sized by their own UI/toolkit. No broad rule for all floating windows,
forced focus trap, pinning, fullscreen or workspace redirection is introduced.

## VM validation

`tests/run-dialogs.py` runs only on j4n9-proxmox with one active monitor and no open
special workspace. It uses existing Quickshell/Qt to create disposable native
windows and opens/cancels a real Qt Save File chooser. No file is accepted or
written, and no actual browser download starts.

The native check covers Save As, Open File, Chọn tệp, Downloads, a small
confirmation, an oversized confirmation, client requests to grow beyond limits,
centering below the reserved topbar, normal-window title false positives,
configerrors and cleanup. Original clients remain open; focus/pointer are restored.
Log: `/tmp/hypr-dialog-tests.log`.

Validated monitor: Virtual-1, 1920×1080 at 1.2 scale (1600×900 logical), topbar
reservation 50 logical pixels. File dialogs map at 1056×630; downloads at 832×414.
Physical laptop, GTK/KDE portal and XWayland dialogs have not been exercised
natively here; their rules use the same verified compositor API and guarded
matching. No laptop-specific, NixOS, Home Manager, Flake or package edits.
