# Bar Popups

Popup components opened from widgets in the top bar.

## Rules

- A popup is responsible only for presentation and interaction.
- System state belongs to `services/`.
- Popups must not call shell commands directly.
- Prefer native Quickshell APIs.
- Popup positioning is anchored to the widget that opened it.
- Larger features should be moved into their own module when they outgrow the bar.

## Adding a popup

1. Copy `Template.qml`.
2. Add the new type to `qmldir`.
3. Pass an anchor item from the owning widget.
4. Read state/actions through services.
5. Keep popup-specific state local to the popup.

## Shared lifecycle and appearance

`BarPopup.qml` owns anchoring, viewport bounds, focus and dismissal.
`PopupState.qml` is a UI singleton that permits one visible bar popup per shell.
Triggers call `popup.toggle()` and bind their selected state to `popup.visible`.
Do not set a second grabFocus handler in feature popups.

The popup first acquires keyboard focus with HyprlandFocusGrab, then adds its
parent bar to the allowed windows. This permits same-button toggle and switching
between triggers without reopening a popup on the dismissal click. A passive
TapHandler in Bar closes the current popup for taps outside its trigger. Clicks
outside the allowed windows clear the native grab and close the popup.

Popup content sets initialFocusItem and handles Escape with close(true). Opening
another popup or clicking outside closes without forcing focus onto the bar.
PopupState is released when a window is hidden or destroyed. Network scanning
stops on close and destruction.

Appearance uses Theme.popupPadding, popupHeaderHeight, popupActionHeight and
separatorWidth. Calendar navigation and power/network rows reuse IconButton.
The shared anchor places popups below the bar, right-aligns to the trigger where
possible, and allows slide/flip/resize inside the screen. Power actions scroll
when the available vertical space is short. Wi-Fi lists scroll independently.
Widgets and popup controls intentionally have no tooltips; keep accessible names.

Keyboard behavior:

- Calendar: Left/Right changes month, Tab/Shift+Tab cycles month buttons,
  Enter/Space activates the focused month button, Escape closes.
- Session: Up/Down and Tab/Shift+Tab cycle actions, Enter/Space activates,
  Escape closes. Keyboard focus is visibly outlined.
- Wi-Fi: Up/Down and Tab/Shift+Tab cycle available network rows, skipping busy
  rows; Enter/Space connects the focused row, Escape closes. Connected rows do
  not reconnect. No-adapter/off/no-results states remain informational.

## Validation — 2026-11-10, j4n9-proxmox

A temporary QML harness loads the actual popup types and uses installed QtTest
TestEvent for mouse/key injection. Confirmed Calendar arrows, Tab/backtab,
Enter and Escape; Session arrow navigation and tab wrap; exclusive opening;
same-trigger toggle; switching triggers; blank-bar dismissal; Wi-Fi unavailable
state; a compact Calendar. Native grab clearing is checked with a competing grab
in the harness. No system power actions or network connections are invoked.

The main shell automatically reloaded successfully. No tooltip definitions remain
in runtime QML. The final harness does not emit the prior xdg popup grab warnings.
Its process still emits existing EGL/Mesa initialization messages. The main shell
retains the pre-existing missing-backlight/input-language warnings.

qmllint still reports Quickshell PopupAnchor/PanelWindow metadata limitations and
some delegate unqualified-access/dynamic-currentItem warnings; no syntax errors
were found. git diff --check passes. Calendar and Wi-Fi screenshots were reviewed
from `/tmp/popup-calendar.png` and `/tmp/popup-wifi.png`.

Limitations: physical clicks outside the shell and actual Wi-Fi connection rows
require further interactive/hardware validation; the VM has no Wi-Fi adapter.
No laptop or system configuration was changed. Existing service actions remain
unchanged; reboot/shutdown/logout/lock were not executed.

API references:

- [HyprlandFocusGrab](https://quickshell.org/docs/v0.3.1/types/Quickshell.Hyprland/HyprlandFocusGrab/)
- [PopupWindow](https://quickshell.org/docs/v0.3.1/types/Quickshell/PopupWindow/)
- [PopupAnchor](https://quickshell.org/docs/v0.3.1/types/Quickshell/PopupAnchor/)

Multi-screen update: BarPopup captures its anchor screen name and closes when
that screen/origin disappears or changes. Cross-screen bar taps dismiss the old
popup. Wi-Fi scanning uses wifi-popup:<screen> ownership so another bar's popup
cannot release its request. Notification centers register per screen while
PopupState keeps one interactive popup open. See
[MULTISCREEN](../../../docs/MULTISCREEN.md).

DetailsPopup provides the shared lazy header/body and keyboard cycle for
NetworkPopup, ResourcesPopup and AudioPopup. Network and audio bodies reuse the
dashboard cards and size to content. All use BarPopup screen routing, focus,
anchor tracking and PopupState exclusivity. See
[WIDGET_DETAILS](../../../docs/WIDGET_DETAILS.md).
