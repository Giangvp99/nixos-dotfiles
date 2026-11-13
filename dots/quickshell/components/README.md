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

## Topbar controls

StatusText and IconButton do not create tooltips. Use Accessible.name for
icon-only controls. IconButton inherits the shared icon/text layout from
StatusText; fillContentWidth allows popup action rows to align content left.

`MonthCalendar` chia sẻ lịch tháng giữa popup và dashboard; hỗ trợ reset,
previousMonth/nextMonth, wrapFocus cho popup và focusHandler cho dashboard.
`StyledSlider` dùng token của Theme; business logic chỉ nối vào `moved` để tránh
ghi ngược dữ liệu khi service cập nhật value.

`OverlayMotion` điều khiển fade mở trên một targetItem, theo shown và
Animations.reducedMotion; khi ẩn dừng ngay, không trì hoãn giải phóng UI.
`OverlayFocus` nhớ origin dạng Item, khôi phục focus QML sau khi cửa sổ ẩn,
loại bỏ callback cũ khi mở lại. Không dùng nó để giữ keyboard grab thường trực.
`IconButton.focusController` tùy chọn nhận object có cycleFocus(delta), giúp
module kiểm soát Tab/Shift+Tab thay vì phụ thuộc thứ tự Qt mặc định.

`FixedStatus` khóa chiều rộng theo cellWidth trong layout, dùng chung StatusText
và token của StatusText; dành cho số liệu cập nhật thường xuyên trên topbar.

### QuickToggle

`QuickToggle` extends IconButton for dashboard Wi-Fi/DND tiles. Set `label`,
`stateText`, `symbol`, `active`, `enabled`, and `focusController`; handle `clicked`
through the owning service. It does not optimistically toggle local state.
Accessible checkbox/checked state, plain text labels, theme spacing/colors,
keyboard activation and focus styling are shared. It has no tooltip.

### OverlayScreen

Captures ScreenService's chosen screen when an owner opens. Bind `active` to the
owner's open/visible state and handle `removed` by closing without restoring
focus. It validates asynchronously so capture and visibility can settle in one
Qt turn. `screenName` is suitable for session-only reload memory; a missing
screen is not silently replaced during an active presentation. See
[MULTISCREEN](../docs/MULTISCREEN.md).

FixedStatusButton adds FixedStatus geometry to an interactive IconButton.
HistoryChart paints bounded time series with missing-data/gap breaks and no own
timer. IconButton.doubleClickEnabled is opt-in: it delays only mouse single-click
and emits doubleClicked without also clicking; keyboard activation is immediate.
The common control padding/gap are 8/4; dense two-line rows use spaceTiny=2.

StyledScrollBar applies the dark Dracula thumb/track tokens to scrollable
launcher, shortcut, notification and notes views; it adds no timers or tooltips.
