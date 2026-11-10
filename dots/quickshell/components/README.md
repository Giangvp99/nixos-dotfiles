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
