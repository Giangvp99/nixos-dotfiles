> Bổ sung hiện tại: icon LAN/Wi-Fi, popup mạng/audio, CPU/RAM history và
> chuẩn hóa khoảng cách được mô tả tại [WIDGET_DETAILS](WIDGET_DETAILS.md).
> Các kích thước ghi trong phần lịch sử bên dưới phản ánh bố cục trước đợt này.

# Tốc độ mạng, CPU/RAM, nhiệt độ và pin

Đã triển khai/kiểm thử trên j4n9-proxmox, 2026-11-10. Chỉ thay giao diện/service
QML và helper JS; không đổi packages, Flake, modules, Home Manager hay laptop.

## Hiển thị

- NetworkSpeed: ↓ download, ↑ upload; dạng gọn B/s, K/s, M/s… theo cơ số 1024.
  Tên accessibility vẫn dùng đầy đủ KiB/s, MiB/s.
- ResourceUsage: icon CPU và icon RAM, mỗi giá trị có ô % riêng; bỏ nhãn chữ.
- Temperature: °C; ưu tiên cảm biến CPU/package, nếu không có thì cảm biến khác.
- Battery: % và AC khi có nguồn ngoài; icon thể hiện sạc/đầy/pin.
  ‖ là tạm dừng sạc, ↓ sau AC là vẫn đang xả, ? là chưa rõ trạng thái.
  Mô tả accessibility giữ đầy đủ trạng thái.
  Có nguồn AC không đồng nghĩa đang sạc; trường hợp AC nhưng pin vẫn xả được
  giữ riêng. Pin yếu/cạn đổi màu theo Theme.warning/urgent. Không hiển thị 0%
  khi thiếu dữ liệu. Widget PowerMenu (lock/logout/reboot/shutdown) giữ nguyên.

Không có tooltip. Các widget mới dùng chung StatusText, Theme, font/icon và
kích thước control của topbar. Các chỉ số là read-only, không gọi ứng dụng ngoài.

Trên VM hiện tại, dữ liệu CPU/RAM và ens18 có sẵn; UPower/pin và cảm biến nhiệt
chưa được cung cấp nên hai widget này tự ẩn. Không suy diễn nhiệt
độ của máy Proxmox vật lý từ dữ liệu máy khách.

## Dữ liệu và hiệu năng

SystemMonitor là singleton chung, không tạo sampler riêng cho từng widget:

- CPU/RAM/mạng: mặc định 2 giây, tối thiểu 1 giây; FileView đọc bất đồng bộ
  /proc/stat, /proc/meminfo, /proc/net/dev. Không fork lệnh theo mỗi mẫu.
- CPU cần hai mẫu, dùng delta tổng/idle+iowait; bỏ guest/guest_nice khỏi tổng
  vì đã có trong user/nice. Chỉ số non-idle có bao gồm steal của VM.
- RAM used = MemTotal − MemAvailable, không dùng MemFree làm lượng RAM còn dùng được.
- Mạng chỉ lấy một interface: networkRateInterface nếu đặt, nếu không thì route IPv4 mặc định có metric thấp nhất, rồi thiết
  bị connected của NetworkService (bỏ lo). Có thể chỉ
  định interface cho IPv6-only khi không có backend NetworkManager/route IPv4.
  Không cộng nhiều interface để tránh đếm trùng bridge/VPN/physical NIC.
- Tính byte/giây bằng thời gian thực giữa hai mẫu, không giả định timer chính
  xác tuyệt đối. Đổi interface, counter reset, clock lùi hoặc gap quá dài sẽ bỏ
  delta cũ; mẫu đầu/chưa sẵn sàng chưa hiện widget; tốc độ thực bằng 0 B/s vẫn hiện.
- Nhiệt độ: FileView sysfs mỗi 5 giây; một shell script literal tìm cảm biến khi
  khởi tạo và mỗi 60 giây để nhận hotplug. Shell chỉ dùng builtin đọc tên/label,
  không dùng sensors/python/awk hay chèn giá trị config vào lệnh.
- Ưu tiên coretemp/k10temp/zenpower/cpu/x86_pkg_temp, rồi package/Tctl/Tdie nếu
  có label tương ứng; lấy max của các cảm biến được chọn. Fallback generic
  vẫn mang nhãn nhiệt độ chung, không được mô tả là chắc chắn nhiệt độ CPU.
- Tối đa 32 cảm biến. Đọc millidegree Celsius, loại giá trị trống/không hợp lệ
  và ngoài −40…150°C. Bản ghi không đổi không tạo lại FileView. Mất hết cảm biến
  ẩn widget; callback xử lý sau khi Instantiator đã cập nhật danh sách.
- BatteryService dùng sự kiện UPower, không polling. Dùng displayDevice battery/UPS,
  bỏ thiết bị ngoại vi; percentage của Quickshell là fraction 0…1. Cờ nguồn
  usingBattery và alias onBattery tách riêng với trạng thái sạc của thiết bị.

Chỉ giữ mẫu trước và dữ liệu hiện tại, không tích lũy lịch sử, không thêm GC/timer
thu gom rác. Tắt flag tương ứng trong Config thì dừng lấy mẫu phần đó.

## Bố cục và cấu hình

Nhóm chỉ số trong BarRight cuộn ngang khi thiếu chỗ. Cuộn chuột dọc hoặc ngang
trên chỉ số để di chuyển; sự kiện wheel của Audio được ưu tiên để giữ điều chỉnh
âm lượng. Notification/date/clock/keyboard/power ở ngoài vùng cuộn; date rút gọn
trên bar hẹp nhưng vẫn mở được lịch. Không thêm tooltip làm lối truy cập phụ.

Các giá trị trong config/Config.qml vẫn live-editable:

| Config | Mặc định | Ý nghĩa |
| --- | --- | --- |
| showNetworkSpeed/showResourceUsage/showTemperature/showBatteryStatus | true | Bật/tắt widget |
| metricsInterval | 2000 | Chu kỳ CPU/RAM/mạng (ms) |
| temperatureInterval | 5000 | Chu kỳ đọc nhiệt độ (ms) |
| networkRateInterface | "" | Tự chọn interface; đặt tên chính xác để override |
| temperatureSensorPaths | [] | Tự tìm; hoặc chọn đường dẫn sysfs cụ thể |
| resourceWarning | 90 | Ngưỡng CPU/RAM đổi màu (%) |
| temperatureWarning/temperatureCritical | 80/95 | Ngưỡng màu °C, có thể điều chỉnh theo cảm biến |
| batteryLow/batteryCritical | 15/5 | Ngưỡng màu khi chạy pin/đang xả (%) |
| networkSpeedWidth | 72 | Chiều rộng cố định tốc độ mạng |
| resourceUsageWidth | 56 | Chiều rộng cố định CPU/RAM |
| temperatureWidth | 84 | Chiều rộng cố định nhiệt độ |
| batteryStatusWidth | 120 | Chiều rộng cố định pin/nguồn |

temperatureSensorPaths chỉ chấp nhận /sys/class/hwmon/hwmonN/tempN_input hoặc
/sys/class/thermal/thermal_zoneN/temp. Nếu đặt danh sách riêng, tự chọn đúng
cảm biến mong muốn; các đường dẫn không hợp lệ bị bỏ qua.

## Kiểm thử

`tests/run-system-widgets.py` tạo bản sao tạm trên VM; không thay thiết bị thật:

```sh
python3 dots/quickshell/tests/run-system-widgets.py
```

Cần Python 3, qs và QtTest đã có trong môi trường kiểm thử; không phải dependency
runtime mới. Script chỉ cho chạy trên j4n9-proxmox.

Đã đạt:

- 26 assertions parser: delta CPU/guest, counter reset, MemAvailable, tốc độ byte,
  đổi interface, clock/gap, đơn vị, giá trị lỗi, route và ưu tiên cảm biến.
- Charging/full/paused/discharging/low/critical/<1%/AC drain/unknown, pin vắng,
  thiết bị mouse/unready và percentage không hợp lệ; kiểm tra nhãn và màu.
- FileView cảm biến thật trong cây dữ liệu giả: max, mất/recover; script discovery
  literal, package → CPU core → generic fallback, hotplug tới danh sách rỗng.
- Bar 640/800/1600, các control cố định nằm trong cửa sổ; wheel cuộn metrics và
  wheel loa riêng (được thay bằng bộ đếm trong bản sao, không chỉnh volume thật).
- Không có TypeError/ReferenceError/binding loop/invalid context mới. Các cảnh báo
  Fcitx/backlight/UPower không có trên VM là cảnh báo môi trường đã có từ trước.

Một tiến trình không có cửa sổ dùng SystemMonitor thật đã nhận dữ liệu /proc và
ens18 qua nhiều mẫu. Trong cửa sổ nhàn rỗi 10 giây: RSS 105532 → 105512 KiB,
CPU ghi nhận 0.00% một lõi ở độ phân giải bộ đếm /proc. Đây là phép đo ngắn của
service cô lập, không phải cam kết CPU/RAM của toàn bộ desktop hoặc với cảm biến
vật lý. [Số liệu](measurements/system-monitor-2026-11-10.json).

Popup cũng được kiểm tra bám đúng vị trí khi độ rộng số liệu thay đổi, resize và
cuộn ngang; BarPopup theo dõi geometry của nút gọi, PopupState cập nhật anchor sau
khi viewport/nhóm trạng thái dịch chuyển. Không giữ callback trên widget đã hủy.

Cụm BarRight căn phải và không giãn lấy khoảng trống. Bốn widget dùng FixedStatus
để khóa minimum/preferred/maximum width, giữ kích thước khi số liệu/trạng thái đổi trong lúc dữ liệu khả dụng. Icon/mũi tên và ô số liệu có vị trí riêng; viewport vẫn cuộn khi hẹp.
Đã kiểm tra kích thước qua các trạng thái pin và vị trí không đổi khi rate đổi đơn
vị; các control cố định giữ sát mép phải ở 640/800/1600. Không thêm tooltip.

### Bản gọn, tự ẩn dữ liệu thiếu

Tốc độ mạng xếp download/upload thành hai dòng trong chiều rộng cố định 72,
fontSmall, giảm gần một nửa so với 184 trước đó. CPU dùng icon microchip,
RAM dùng icon thanh nhớ ngang (đã kiểm tra glyph trong FiraCode Nerd Font hiện có).
Không dùng hai icon chip giống nhau nữa.

Widget thiếu dữ liệu tự ẩn và không giữ khoảng trống: mạng chưa có delta hợp lệ,
nhiệt độ không có cảm biến, pin không có phần trăm hợp lệ. CPU/RAM chỉ hiện nhóm
có dữ liệu; một hoặc hai nhóm đều dùng 56; CPU/RAM xếp hai dòng. Tốc độ 0 B/s và CPU 0% vẫn là dữ
liệu hợp lệ, không bị ẩn. Chỉ báo keyboard cũng ẩn khi language là --.

Kích thước giữ nguyên trong lúc số liệu bình thường cập nhật; thay đổi khả dụng
của nguồn dữ liệu sẽ thêm/bớt nhóm tương ứng. Backend vẫn theo dõi để tự hiện lại
khi dữ liệu trở lại. Không thêm tooltip, package hay thay cấu hình hệ thống/laptop.

CPU/RAM và mạng dùng bố cục hai dòng, khoảng cách icon–số liệu spaceTiny (2),
icon neo trái và số liệu căn phải trong mỗi dòng. Ô icon rộng 12 px; chiều rộng
widget mạng 72 px và CPU/RAM 56 px giữ khoảng cách gọn mà không co giãn theo số liệu.
