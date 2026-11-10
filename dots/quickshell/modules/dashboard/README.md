# Dashboard — giai đoạn 4

Mở bằng nút Dashboard bên trái topbar hoặc `qs ipc call dashboard toggle`.
`Escape`, nút đóng hoặc click vùng nền đóng dashboard. Tab/Shift+Tab chuyển
điều khiển; điều khiển đang chọn được cuộn vào vùng nhìn thấy.

Dashboard dùng Theme, Surface, IconButton, AppIcon, StyledSlider và MonthCalendar
chung. Hiển thị mode/workspace, cửa sổ hiện tại, đồng hồ/lịch, âm lượng,
trạng thái Ethernet/Wi-Fi, ứng dụng ghim và lối vào notification center/DND.
Launcher, dashboard và popup topbar đóng lẫn nhau khi mở.
Không có tooltip.

Tùy chỉnh trong config/Config.qml: dashboardName, dashboardWidth,
dashboardMaxHeight, dashboardBreakpoint và dashboardApps. Danh sách ứng dụng
mặc định theo launcherPinnedApps; desktop entry không tồn tại được bỏ qua.
Không có adapter âm thanh/Wi-Fi hoặc backend thông báo thì nút tương ứng bị vô hiệu.
Nhãn mạng phân biệt thiếu dữ liệu, mất kết nối và có liên kết; không suy diễn
Internet từ trạng thái Ethernet. Settings chỉ bật nếu có nm-connection-editor.

DashboardContent chỉ được Loader tạo khi mở và được hủy khi đóng. Đồng hồ
cập nhật theo phút, dữ liệu hệ thống dùng service hiện có, không thêm polling.
Bố cục hai cột chuyển thành một cột trên cửa sổ hẹp, có cuộn khi thiếu chiều cao.
MonthCalendar dùng lại trong CalendarPopup để giữ thống nhất cách tính ngày.

ModeService chỉ nhận writing/code/relax, gọi `hyprctl eval` để chạy modes.core.switch.
Theo API Hyprland Lua, dispatch chỉ nhận biểu thức dispatcher; eval chạy Lua tùy ý:
https://wiki.hypr.land/configuring/core/advanced-configuration/using-hyprctl/
Không thay đổi Lua keybinding hay cấu hình hệ thống.

Kiểm thử trên j4n9-proxmox: mở dashboard thật và kiểm tra hình ảnh; fixture QML
với dịch vụ mô phỏng cho volume/mute/Wi-Fi/mode/DND, shortcut, phối hợp overlay,
thiếu thiết bị và bố cục 380×500. Không thay đổi volume/Wi-Fi/mode thật trong fixture.
Live update vẫn dùng symlink QML hiện tại; không cần rebuild NixOS.

## Lượt 2 — hoàn thiện trải nghiệm

Ở chế độ rộng, ứng dụng ghim xếp ba cột và lịch dùng chiều cao
Theme.dashboardCalendarHeight (230), giúp hai cột có chiều cao gần nhau.
Chế độ hẹp vẫn xếp ứng dụng theo hàng để giữ đủ không gian cho nhãn.
Nút đang bật có viền primary; hover/pressed/focus và chuyển màu dùng token chung.
Slider có chuyển màu theo Animations.fast, tôn trọng reducedMotion.

ShellRoot giữ duy nhất cờ mở dashboard trong PersistentProperties. Khi reload
hoàn tất, dashboard mở lại và lấy focus ở nút đóng; vị trí cuộn và tháng đang xem
được reset. Không lưu dữ liệu xuống đĩa, không tự mở lại qua lần chạy Quickshell mới.

Kiểm tra bàn phím gồm vòng Tab và Shift+Tab, bỏ qua điều khiển disabled,
cuộn theo focus, Enter kích hoạt nút, mũi tên chỉnh slider, Left/Right đổi tháng
và Escape đóng overlay. Không có tooltip. Fixture dùng dịch vụ mô phỏng để
tránh đổi âm lượng, Wi-Fi hoặc mode của phiên thật.

### Kết quả kiểm tra trên VM, 2026-11-10

- Fixture: điều khiển với service mô phỏng, launcher/popup, lịch năm nhuận,
  Tab/Shift+Tab, Enter/Escape, mũi tên slider/lịch, bố cục 380×500 và thiếu thiết bị đạt.
- Phiên thật: giữ mở qua reload, phối hợp notification center và 40 chu kỳ
  mở/đóng đạt. Khi đóng, IPC báo opened=false, loaded=false.
- Không có lỗi runtime mới; các cảnh báo thiếu intel_backlight/fcitx trên VM đã có sẵn.
- qmllint còn cảnh báo metadata PanelWindow và Loader.item kiểu QObject;
  không có lỗi cú pháp, git diff --check đạt.

Đo toàn bộ tiến trình Quickshell trong các cửa sổ nhàn rỗi 5 giây, sau đợt reload:

| Mốc | CPU (% một lõi) | RSS (KiB) |
| --- | ---: | ---: |
| Trước đợt bổ sung | 3.0 | 241948 |
| Sau 10 chu kỳ | 3.4 | 265652 |
| Sau 20 chu kỳ | 3.2 | 280744 |

Đây là số liệu của toàn bộ shell, không phải riêng dashboard. RSS vẫn tăng trong
phép đo ngắn dù Loader đã hủy nội dung; chưa thể phân biệt cache/GC với rò rỉ
bộ nhớ. Cần theo dõi dài hạn trước khi khẳng định RAM ổn định hoặc áp dụng laptop.
Không thêm polling, tiến trình nền hay ghi bộ nhớ dashboard xuống đĩa.

Đã kiểm tra tiếp bằng các đợt dài và bộ đếm vòng đời trong bản sao cô lập:
[xem phương pháp, số liệu và công cụ chạy lại](../../docs/DASHBOARD_MEMORY.md).
Kết quả này bổ sung cho phép đo ngắn ở trên; không cần thay đổi vòng đời Loader
hay thêm GC vào giao diện đang dùng.

Giai đoạn 5 bổ sung fade mở, origin focus qua các lần chuyển overlay và đưa focus
vào viewport sau resize. Xem [PHASE5](../../docs/PHASE5.md) cho hợp đồng close(false),
reducedMotion và phạm vi kiểm thử.
