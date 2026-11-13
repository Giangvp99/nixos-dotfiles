# Dashboard

Dashboard không cuộn toàn bảng. Trên VM, panel rộng tối đa 1260, cao tối đa 740
đơn vị logical; thu theo vùng màn hình và vẫn giữ màn hình đã mở overlay.

- Màn hình rộng: ba cột, hai hàng thẳng mép. Focus/lịch ở trái, audio/network
  ở giữa, notes/media ở phải. Clock và workspace nằm ở đầu; ứng dụng ghim,
  launcher, notifications, shortcuts và DND dùng chung hàng cuối.
- Khi nội dung hẹp hơn dashboardBreakpoint (1100) hoặc thấp hơn 700: chọn
  Focus / Sound / Network / Notes / Calendar / Media bằng các nút mục.
  Mỗi mục hiển thị riêng, không nối dài thành một danh sách dọc.
- Bộ chọn thiết bị, mạng và player trong dashboard hiển thị hai lựa chọn mỗi
  trang, với nút chuyển trang để truy cập mọi lựa chọn. Audio chỉ mở một bộ chọn
  tại một thời điểm. Bộ chọn thay thế các điều khiển của thẻ trong lúc mở.
- Chỉ ô soạn ghi chú cuộn nội bộ khi nội dung dài; không dùng Flickable hay
  ScrollBar cho dashboard. Không thu nhỏ toàn bộ giao diện hoặc cắt thẻ để ép vừa.
- Tab/Shift+Tab chỉ đi qua mục đang thấy. Enter/Space, Escape, slider, mode,
  lưu ghi chú và live reload giữ nguyên. Mục đang chọn được nhớ qua live reload.
  Scanner Wi-Fi dừng khi rời mục mạng. Không có tooltip.

DashboardContent vẫn được tạo/hủy bởi Loader khi mở/đóng. Không thêm polling,
packages hoặc thay đổi cấu hình NixOS/laptop. Các card standalone giữ chế độ
mở rộng đầy đủ; compact/pagination chỉ bật trong dashboard.

Kiểm tra bố cục trên j4n9-proxmox:
`python3 dots/quickshell/tests/run-dashboard-layout.py` dùng backend giả và
thư mục state tạm. Kiểm tra hai trục, va chạm thẻ, hai hàng thẳng mép, danh sách
nhiều mục, vòng Tab, live reload và các trang ở 1000×708, 720×600, 340×600.
Log: `/tmp/dashboard-layout-tests.log`. Kiểm thử hồi quy từng phần có trong
`run-focus-notes.py`, `run-audio-controls.py`, `run-network-controls.py`,
`run-media-controls.py`.

## Lịch sử triển khai (bố cục trước đợt chuẩn hóa không cuộn)

### Giai đoạn 4

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

## Control Center — lượt 1: âm thanh (2026-11-11)

`AudioCard.qml` tách điều khiển output và microphone thành hai nhóm dùng chung
bố cục. Mỗi nhóm có volume/mute và danh sách thiết bị mở ngay trong thẻ. Tên
thiết bị là plain text, được elide khi dài; không có tooltip. Danh sách chỉ được
Loader tạo khi mở, thẻ vẫn theo vòng đời Loader của dashboard.

AudioService là nguồn trạng thái duy nhất cho dashboard và topbar. Chọn thiết bị
đặt preferred default qua PipeWire native; dấu chọn theo default thực tế được
backend xác nhận. Không tự unmute, không chuyển volume giữa các thiết bị, không
thêm polling hoặc lệnh shell. Không có microphone/output thì nút và slider tương
ứng bị vô hiệu. Stream ứng dụng và video node không xuất hiện trong danh sách.

Tab/Backtab đi qua các điều khiển và thiết bị đang mở. Escape trong nhóm đang mở
đóng danh sách và trả focus về nút chọn; Escape tiếp theo đóng dashboard. Khi
thiết bị đang được focus biến mất, focus chuyển về nút chọn hoặc điều khiển còn
khả dụng. Các focus mới được chuyển cho dashboard để cuộn vào viewport.

Chạy lại trên `j4n9-proxmox`:

```sh
python3 dots/quickshell/tests/run-audio-controls.py
```

Runner dùng bản sao tạm của shell. Nó đọc backend thật trước, rồi thay backend
trong bản sao bằng dữ liệu giả; không ghi trạng thái âm thanh thật. Đã kiểm tra:

- Lọc stream/video, chọn output/input, chờ default thực tế, bỏ qua node đã ngắt
  hoặc backend chưa sẵn sàng; volume clamp 0–100%, bỏ qua NaN, mute độc lập.
- Enter chọn thiết bị; Escape, Tab/Backtab; mũi tên chỉnh microphone volume.
- Mất output khi focus ở danh sách: vô hiệu nút/slider, khôi phục focus và nhận
  lại thiết bị khi dữ liệu trở lại.
- Bố cục thẻ 340/420 px, 10 chu kỳ tạo/hủy, tích hợp Tab trong DashboardContent,
  Escape đóng dashboard và hủy nội dung. Không có lỗi QML trong fixture.
- Phiên thật: VM chỉ có Dummy Output, không có input; đã xem ảnh dashboard,
  xác nhận giữ mở qua source live reload và 5 chu kỳ mở/đóng, loaded=false khi
  đóng. Cảnh báo thiếu backlight/fcitx đã có sẵn vẫn còn.

Chuyển nhiều thiết bị âm thanh và microphone được kiểm thử bằng mock vì VM không
có phần cứng tương ứng. Không ghi âm, không thay volume/mute/default thật, không
thay đổi packages, Home Manager, NixOS hay laptop.

## Control Center — lượt 2: mạng và quick toggles (2026-11-11)

`NetworkCard.qml` thay phần mạng viết trực tiếp trong DashboardContent. Thẻ giữ
trạng thái Ethernet/connectivity, thêm nút mở danh sách Wi-Fi và dùng chung
`QuickToggle.qml` với DND. Tile có icon, nhãn và trạng thái On/Off/Unavailable,
viền active/focus, hỗ trợ bàn phím và accessible checked state; không tooltip.
Settings tiếp tục chỉ bật nếu có nm-connection-editor, và chuyển qua luồng
launchRequested hiện có.

Danh sách chỉ được tạo khi mở. Mạng đã lưu hoặc mạng mở mới được phép connect;
mạng cần credential chưa lưu hiện "Set up in Settings", mạng đang chuyển trạng
thái bị vô hiệu, lỗi kết nối hiện ngay trong thẻ. SSID là plain text và elide.
Không lưu mật khẩu, không thêm password prompt hoặc package.

Scanner được đăng ký theo owner: dashboard-network và wifi-popup. Mỗi owner
đăng ký một lần, đóng/hủy giao diện chỉ gỡ phần đăng ký của mình. Scanner dừng
khi owner cuối cùng đóng hoặc radio tắt; tự theo adapter thay thế và tháo/gắn.
Không thêm timer/polling. Thao tác mở dashboard không tự bật Wi-Fi.

Tab/Backtab đi qua tile, Settings, nút danh sách và các mạng đủ điều kiện. Chọn
mạng trả focus về nút danh sách; Escape trong thẻ đóng danh sách trước, Escape
lần tiếp theo đóng dashboard. Focus của mạng bị tháo sẽ được phục hồi.

Chạy kiểm thử riêng từng fixture (cùng dùng focus Wayland):

```sh
python3 dots/quickshell/tests/run-network-controls.py
python3 dots/quickshell/tests/run-audio-controls.py
```

Bản sao shell dùng backend giả để thử scan ownership, RF hardware block,
adapter thay thế/tháo/gắn, saved/open/busy/stale guards, lỗi kết nối và recovery,
Settings, Enter/Escape/Tab/Backtab, DND, bố cục 340/420 px và 5 vòng tạo/hủy.
Popup và dashboard đã được mở đồng thời trong fixture để kiểm tra giữ scanner.
Fixture đầy đủ xác nhận danh sách tham gia Tab order và cleanup qua Escape.
Kiểm thử âm thanh hồi quy cũng đạt. Không có lỗi QML trong các fixture cuối.

Phiên thật trên j4n9-proxmox dùng Ethernet, không có adapter Wi-Fi; kết nối/quét
Wi-Fi thực tế còn cần thiết bị phù hợp. Không thay cấu hình laptop/NixOS,
Home Manager, Flake hoặc packages.

Kiểm tra phiên thật: dashboard giữ mở qua source live reload, 5 chu kỳ mở/đóng
hủy nội dung đúng, trạng thái thiết bị/radio qua nmcli không đổi trước/sau; phiên
ban đầu được khôi phục. Đã xem ảnh trên VM và dành một hàng riêng cho DND để
không cắt nhãn khi ở bố cục rộng. qmllint không có lỗi cú pháp, còn cảnh báo
metadata Loader.item/unqualified như các module hiện có; git diff --check đạt.

## Keyboard shortcut reference

Quick access now includes Keyboard shortcuts (Super + /). DashboardContent emits
shortcutsRequested through Dashboard; ShellRoot forwards the original focus
origin and closes the dashboard before opening KeybindSheet. The reference
participates in the existing launcher/popup exclusivity rules. See
[keybinds](../keybinds/README.md) for data source, keyboard controls and tests.

## Multi-screen routing

Dashboard captures the initiating bar or focused screen and uses its workspace
for mode/title context. Its screen is passed through launcher/keybind/notification
handoffs. The screen name survives QML reload with the open flag; missing output
cancels restoration, and removal while open closes without focus restoration.
See [MULTISCREEN](../../docs/MULTISCREEN.md).

## Media Center

MediaCard adds Now playing above the calendar, backed by the shared native MPRIS
MediaService. It hides without players and supports guarded transport controls,
a player chooser, artwork/fallback and dashboard keyboard/focus integration.
No progress timer or topbar widget is added. See
[MEDIA_CENTER](../../docs/MEDIA_CENTER.md) for selection policy and tests.

FocusCard and NotesCard add an optional focus timer and a persistent local
scratchpad. Both reuse the shared theme and dashboard focus cycle. See
[Focus and notes](../../docs/FOCUS_NOTES.md) for persistence and controls.
