# Config Layer

Thư mục này định nghĩa các token và preference dùng toàn shell.

## Files

Config.qml
- kích thước;
- behavior;
- feature flags.

Theme.qml
- colors;
- typography;
- radius.

Animations.qml
- duration;
- easing.

## Allowed

- QtObject;
- readonly property;
- cấu hình UI;
- design token.

## Forbidden

- Hyprland API;
- PipeWire;
- Process;
- system state;
- widget logic.

## Khi thêm config

Copy Template.qml nếu cần singleton config mới.

Nếu property thuộc appearance, ưu tiên Theme.qml.

Nếu property thuộc animation, dùng Animations.qml.

Nếu property thuộc behavior/layout, dùng Config.qml.

`notificationsEnabled` defaults to false. NotificationHost allows an explicitly
approved process-scoped trial through IPC without changing that default; see
`modules/notifications/README.md` for the current owner, session opt-in and rollback.
This flag is not a safe hot daemon switch.

Các flag showNetworkSpeed/showResourceUsage/showTemperature/showBatteryStatus,
chu kỳ lấy mẫu, interface/cảm biến và ngưỡng màu nằm trong Config.qml.
Xem [SYSTEM_WIDGETS](../docs/SYSTEM_WIDGETS.md); không cần rebuild NixOS.

Audio OSD uses `audioOsdEnabled`, `audioOsdTimeout` (1500 ms), `audioOsdWidth`
(300 px), and `audioOsdBottomMargin` (64 px). Changes remain live-editable.
It observes confirmed audio changes, stays silent on startup/reload/device swaps,
and never takes keyboard/pointer input. See [OSD](../modules/osd/README.md).

The keyboard reference uses `keybindWidth` (760) and `keybindHeight` (600), clamped
to the current viewport. Its open flag survives QML reload; the current binding
catalog is read again. See [keybinds](../modules/keybinds/README.md).

Dark Dracula is defined by Theme.qml. All surfaces and shared controls consume
its semantic tokens, with dark selected text on purple selection. The mirrored
Hyprland palette is in dots/hypr/config/theme.lua. See
[DRACULA](../docs/DRACULA.md) for colors, adaptations and VM validation.
