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
