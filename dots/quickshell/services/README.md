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

SystemMonitor chia sẻ delta CPU/RAM/network và cảm biến sysfs giữa các widget.
Đọc proc/sysfs bất đồng bộ với chu kỳ có giới hạn, không chạy lệnh cho mỗi mẫu.
BatteryService tách nguồn AC/Battery khỏi charging/full/pending/discharging, giữ
onBattery làm alias tương thích của usingBattery. Xem [SYSTEM_WIDGETS](../docs/SYSTEM_WIDGETS.md).

### Audio device selection and microphone

AudioService additionally exposes `outputs`, `inputs`, `source`, `inputAvailable`,
`inputVolume`, `inputVolumePercent`, and `inputMuted`. Use `deviceLabel(node)`,
`selectOutput(node)`, `selectInput(node)`, `setInputVolume(value)`, and
`toggleInputMute()` from controls. The original output API stays shared by the
bar and dashboard. Only current default nodes are tracked; device enumeration
uses native registry metadata and excludes streams/video. Selection requests a
preferred default; the UI reflects the actual default reported by PipeWire.
The `backend` property supports isolated fixtures; production uses Pipewire.

### Network scanner ownership

NetworkService uses the native Networking backend and accepts a mock `backend`
for isolated tests. `startScanning(owner)`/`stopScanning(owner)` manage independent
visible consumers; omitted owner is the existing `wifi-popup`. The dashboard
uses `dashboard-network`. An owner can register repeatedly without increasing
its count. Scanning follows the current Wi-Fi adapter only while requested and
the software/hardware radio is enabled. Closing one consumer preserves another.

`canConnect(network)` validates membership, radio state, connected/busy state,
and saved credentials or open security before `connectNetwork(network)` runs.
`networkStatus(network)` provides display text, `connectionError` reports the
latest attempted connection failure, and `hardwareEnabled` distinguishes radio
hardware blocking. Existing output/connectivity properties stay available to
the bar and dashboard. No polling or background command was added.

AudioService output/input availability additionally accounts for native node
readiness. Getters and actions guard transiently null audio interfaces during
node replacement/disconnection. The audio OSD observes this same service; it
adds no commands, polling or independent audio state owner.

### ScreenService and per-screen window metadata

ScreenService exposes screens/focusedScreen, choose(origin, preferred), contains,
monitorFor and workspaceFor. Bar bindings track the monitor model explicitly.
HyprlandService.toplevelsFor(workspace, monitor) sorts normal windows and scopes
minimized windows by their recorded origin; activeToplevelFor provides workspace
context without following global focus. Initial and event-driven metadata refresh
covers new/moved windows; no polling is introduced.

NotificationState registers/unregisters centers and resolves centerForScreen.
WifiPopup uses a distinct wifi-popup:<screen> scanner owner. See
[MULTISCREEN](../docs/MULTISCREEN.md) for lifecycle, compatibility and validation.

### MediaService

Uses Quickshell.Services.Mpris to expose players, activePlayer, available,
isPlaying, trackTitle, trackArtist, artwork, playerName and transport capability
flags. selectPlayer chooses a live player's bus identity; automatic selection
prefers playing players. previous/togglePlaying/next validate membership and
capabilities at call time. The backend is injectable for fixtures; no shell
commands, polling, position timer or preference persistence are added. See
[MEDIA_CENTER](../docs/MEDIA_CENTER.md).

FocusSession uses reload-persistent root memory, a deadline and a timer active
only while running. NotificationState.dndRevision prevents restoring DND after
manual changes. NotesService debounces atomic plain-text saves, keeps unsaved
drafts across reload and exposes read/write errors for Retry. See
[Focus and notes](../docs/FOCUS_NOTES.md).

SystemMonitor now keeps 90 timestamped CPU and RAM samples per series, restored
through root PersistentProperties across QML reload. It uses the existing sampler.
NetworkService classifies the exact measured interface. NetworkDetails performs
bounded, on-demand, read-only nmcli queries for NetworkPopup. See
[WIDGET_DETAILS](../docs/WIDGET_DETAILS.md).
