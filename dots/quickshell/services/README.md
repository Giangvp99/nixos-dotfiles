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

### AppService

DesktopEntries owns the live application catalog. AppService builds a normalized
metadata index when it changes and delegates ranking to `utils/AppSearch.js`.
`search(query)` honors Config.launcherPinnedApps and launcherResultLimit;
`isPinned(app)` compares normalized desktop IDs. `launch(app)` uses the desktop
entry's execute method without constructing shell commands. See the launcher
README for ranking rules and VM validation.

### NotificationService

Optional native notification server and bounded live FIFO. NotificationRecord
owns each one-shot lifetime timer. See `modules/notifications/README.md` for the
Quickshell 0.3.1 timeout detail, reload behavior and isolated D-Bus validation.
Do not reference this singleton from always-loaded widgets while notifications
are disabled: it initializes the native server. The top-level LazyLoader keeps
it off until an approved daemon handoff.

### NotificationState

Lightweight notification history/read/DND state for the bell and center. This
singleton does not instantiate NotificationServer. ShellRoot supplies string/boolean
PersistentProperties for in-RAM reload storage; see modules/notifications/CENTER.md.
Native actions are always resolved through NotificationService by ID, and archived
entries retain no native object or action references.

DashboardState giữ tham chiếu controller để topbar mở/đóng dashboard.
AppService.byId tra desktop entry từ index dùng chung. ModeService.activate chỉ
nhận ba mode đã định nghĩa và chạy Lua qua hyprctl eval khi người dùng bấm.
NetworkService bổ sung trạng thái liên kết Ethernet/Wi-Fi và connectivity hiện
có từ backend, không chủ động kiểm tra mạng hay tạo polling.
