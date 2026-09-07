# Services

Services là lớp duy nhất chịu trách nhiệm giao tiếp với hệ thống.

## Service owns

- system state;
- lifecycle của integration;
- system action;
- parsing/normalization dữ liệu.

## Service does NOT own

- Rectangle;
- Text;
- visual layout;
- popup;
- animation UI.

## Naming

DomainService.qml

Ví dụ:

AudioService.qml
NetworkService.qml
HyprlandService.qml

## API design

Ưu tiên expose API đơn giản:

readonly property real volume
readonly property bool muted

function toggleMute()
function setVolume(value)

Widget không cần biết backend đang dùng PipeWire, DBus hay Process.

## Khi tạo service mới

Copy Template.qml.

Sau đó thêm singleton vào qmldir.

## Current services

### HyprlandService

Owner của Hyprland state:

- workspaces;
- focused workspace;
- focused monitor;
- active toplevel.

### AudioService

Owner của output audio state.

Backend:

    Quickshell.Services.Pipewire

Public state:

- `available`
- `volume`
- `volumePercent`
- `muted`

Public actions:

- `toggleMute()`
- `setMuted(value)`
- `setVolume(value)`
- `increaseVolume()`
- `decreaseVolume()`

Widgets không được truy cập PipeWire trực tiếp nếu dữ liệu đã được
AudioService expose.
