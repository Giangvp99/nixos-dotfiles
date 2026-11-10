# Giai đoạn 5 — trải nghiệm giữa các overlay

## Thay đổi

`OverlayMotion` dùng chung cho launcher, dashboard và BarPopup (bao gồm notification
center): fade mở theo Animations.fast/standardEasing, không dùng shader, scale hay
layer bổ sung. Khi reducedMotion bật, fade dừng và opacity về 1 ngay. Đóng overlay
không chờ animation: keyboard grab và Loader được giải phóng theo cơ chế hiện có.
Animation của compositor Hyprland độc lập với reducedMotion của QML.

`OverlayFocus` ghi nhận Item gọi overlay, đợi cửa sổ native ẩn rồi khôi phục focus
QML khi đóng bằng Escape/nút đóng. Dashboard truyền nút gọi qua các lần chuyển
sang launcher/notification center. Chuyển overlay, click nền hoặc mở ứng dụng dùng
close(false), tránh callback cũ lấy lại focus. Nút bị hủy/ẩn/disabled được bỏ qua;
lần đóng cũ không khôi phục focus nếu overlay đã mở lại. Không giữ Item qua reload;
chỉ cờ mở dashboard được lưu trong PersistentProperties như trước.

Focus QML của nút gọi và focus cửa sổ do compositor quản lý là hai lớp riêng.
Không thêm keyboard grab thường trực cho topbar. Popup vẫn dùng duy nhất
HyprlandFocusGrab hiện có, không thêm xdg grab hay timer giành focus.

`IconButton.focusController` là điểm nối tùy chọn tới cycleFocus(delta) của module;
khi không đặt, Tab vẫn đi theo Qt. Enter và keypad Enter đều kích hoạt nút. Dùng
controller cho dashboard, power/Wi-Fi popup và các nút trong notification history.
Wi-Fi bỏ qua mạng đang chuyển trạng thái; tắt điều hướng ListView mặc định để
không đi vòng qua logic này. Notification center giữ hàng đang chọn trong viewport;
action dài tự cuộn ngang khi được chọn bằng bàn phím.

Dashboard chia đều hàng nút mode, cho phép nhãn trạng thái mạng co lại và elide,
elide lời chào dài và hiển thị tên cửa sổ như plain text. Focus được đưa lại vào
viewport khi đổi kích thước. Callback resize chạy qua controller ngoài Loader,
không xếp callback trỏ vào DashboardContent đã hủy.

Không thêm tooltip, polling hay package. Không đổi renderer, Lua, cấu hình NixOS,
Home Manager hoặc laptop.

## Kiểm tra trên j4n9-proxmox

Fixture chạy trên Wayland, dùng dịch vụ mô phỏng cho mode/audio/Wi-Fi/app launch.
Notification backend được thử riêng trên D-Bus cô lập để giữ lịch sử phiên thật.

- Fade hữu hạn; bật reducedMotion giữa animation dừng ngay; đóng reset opacity.
- Escape, Tab/Shift+Tab, Enter/keypad Enter; vòng focus notification center.
- Trả focus QML về từng nút gọi; chuyển dashboard → launcher/center giữ origin;
  mở ứng dụng không trả focus; đóng/mở nhanh không bị callback cũ lấy focus.
- Power popup chỉ điều hướng, không thực thi lock/logout/reboot/shutdown.
- Wi-Fi fake: Down/Up/Tab/Shift+Tab bỏ qua mạng busy, Enter gọi đúng fake backend,
  đóng dừng scan. Không kết nối hay chỉnh Wi-Fi thật.
- Action dài cuộn vào viewport, dashboard giữ focus trong viewport khi đổi cột.
- Bố cục 320×480, 360×480, 640×480, 1024×768; tên người dùng/app/cửa sổ dài,
  query dài và launcher không có kết quả.
- Notification history/DND/unread/action/eviction/clear và live reload qua D-Bus riêng.

qmllint dùng cả import path Qt và Quickshell; còn cảnh báo metadata PanelWindow,
Loader.item kiểu QObject và một số truy cập delegate, không có lỗi cú pháp.
`git diff --check` là kiểm tra bắt buộc bổ sung.

## Kiểm tra vòng đời và hiệu năng

Bản offscreen đã qua 70 chu kỳ: RSS 89864 → 89980 KiB từ chu kỳ 20 tới 70,
CPU nhàn rỗi 0–0.4% một lõi, tạo/hủy nội dung và đồng hồ 70/70. Đây là phép đo
trước bản chỉnh callback resize cuối; kết quả sau bản chỉnh được xác minh trên
Wayland như dưới đây.

Bản Wayland với QML cuối: 25 chu kỳ và 2 reload khi đang mở, không gọi GC.
Mọi mẫu đóng có loaded=false và số tạo/hủy khớp; cuối đợt là 29/29. Không có
TypeError, ReferenceError, binding loop hoặc callback invalid context trong log.

| Mốc Wayland | RSS (KiB) | CPU nhàn rỗi (% một lõi) |
| --- | ---: | ---: |
| Sau 5 chu kỳ | 209876 | 0.8 |
| Sau 25 chu kỳ | 222484 | 0.8 |
| Sau reload 1 | 232136 | 0.6 |
| Sau reload 2 | 238796 | 0.59 |

Đây là mẫu ngắn của bản dashboard cô lập, không chứng minh mức RAM ổn định dài
hạn hoặc định lượng chính xác overhead so với bản trước. Chi phí renderer/cache
vẫn cần được phân biệt như trong [DASHBOARD_MEMORY](DASHBOARD_MEMORY.md).
Fade không tiếp tục chạy khi đóng, không thêm timer hay GC vào sản phẩm.

[Số liệu và hash QML](measurements/phase5-memory-2026-11-10.json).

Phiên thật cũng đã kiểm tra dashboard → launcher qua global shortcut → dashboard
→ notification center. Mỗi lần chỉ còn overlay được yêu cầu; sau kiểm tra đã đóng
các overlay, backend notification vẫn available và trạng thái DND giữ nguyên.
Đã kiểm tra hình ảnh dashboard/launcher sau khi cửa sổ Wayland ổn định.
