# Components

Components là reusable UI primitives.

Một Component phải có thể tồn tại mà không biết feature nào đang sử dụng nó.

## Ví dụ đúng

StyledText
Surface
IconButton
Card
Slider
Tooltip

## Ví dụ sai

WifiButton
BatteryIndicator
WorkspaceButton

Các component trên thuộc feature/domain và nên nằm trong module/widget.

## Forbidden

Không import:

- Quickshell.Hyprland
- PipeWire
- NetworkManager
- system service trực tiếp

Component có thể import config để lấy Theme.
