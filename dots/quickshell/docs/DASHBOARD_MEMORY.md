# Kiểm tra bộ nhớ dashboard trên j4n9-proxmox

Ngày kiểm tra: 2026-11-10. Giữ nguyên QML giao diện, cấu hình hệ thống và laptop.

## Kết luận về phép đo mở/đóng

Chưa tái hiện được rò rỉ vòng đời nội dung dashboard hoặc SystemClock.
Số lần tạo/hủy khớp qua 420 chu kỳ ngoài màn hình và 320 chu kỳ Wayland.
Sau mỗi đợt, dashboard đóng và Loader.item là null. Không thêm lời gọi gc(),
timer thu gom rác hay thay đổi thời gian sống của widget vào giao diện thật.

Các phép đo ngắn trước đó của toàn shell không đủ để quy tăng RSS cho dashboard.
Đợt đối chứng toàn shell trong 30 giây có RSS 241420, 241420, 241228,
301000 KiB dù không tự động mở dashboard. Hoạt động khác của shell/phiên làm
việc làm mẫu đối chứng này không đủ sạch để dùng làm ngưỡng riêng cho dashboard.

## Phương pháp

Tạo bản sao tạm của QML; chỉ chạy Dashboard trong ShellRoot tối thiểu, không
khởi động notification server và không thay thế phiên Quickshell đang dùng.
Thêm bộ đếm qua Component.onCompleted/onDestruction vào DashboardContent và
SystemClock của bản sao; không giữ tham chiếu tới đối tượng đã hủy.
Mỗi chu kỳ mở/đóng dùng Timer thử nghiệm với khoảng 120 ms giữa hai trạng thái.
Sau mỗi đợt chờ 5 giây, đọc /proc/PID/smaps_rollup và /proc/PID/stat:

- RSS là số trang resident của tiến trình, có cả trang dùng chung.
- PSS phân bổ trang dùng chung theo số tiến trình chia sẻ; có thể thay đổi khi
  tiến trình khác khởi động/dừng.
- Private_Dirty giúp đối chiếu phần trang riêng.
- CPU tính theo một lõi trong cửa sổ lấy mẫu, không phải CPU trung bình của đợt thao tác.

Ngoài màn hình dùng Qt Window và software renderer thay PanelWindow, vì
PanelWindow cần backend Wayland. Nó kiểm tra vòng đời QML, không thay thế
kiểm thử layer-shell/dựng hình thật. Reload phải kiểm tra trên Wayland vì giao
diện reload nội bộ của Quickshell cũng cần PanelWindow.

## Số liệu mở/đóng

Đơn vị bộ nhớ: KiB. Hai bản thử nghiệm chạy trong các tiến trình riêng.

| Backend | Số chu kỳ | RSS | PSS | Private_Dirty | Tạo/hủy nội dung và đồng hồ |
| --- | ---: | ---: | ---: | ---: | --- |
| Offscreen | 20 | 89980 | 53033 | 25012 | 20/20 |
| Offscreen | 120 | 89852 | 52904 | 24884 | 120/120 |
| Offscreen | 220 | 89808 | 52861 | 24840 | 220/220 |
| Offscreen | 320 | 89736 | 43191 | 24768 | 320/320 |
| Offscreen | 420, sau một GC chẩn đoán | 89948 | 43403 | 24980 | 420/420 |
| Wayland | 20 | 193872 | 87047 | 53200 | 20/20 |
| Wayland | 120 | 187824 | 90598 | 47152 | 120/120 |
| Wayland | 220 | 194800 | 97574 | 54128 | 220/220 |
| Wayland | 320, sau một GC chẩn đoán | 210556 | 113330 | 69884 | 320/320 |

CPU nhàn rỗi của bản thử Wayland: 0–0.8% một lõi trong các mẫu 5 giây.
Sau GC chẩn đoán ở chu kỳ 220: RSS 173156 KiB; sau GC ở chu kỳ 320:
RSS 188224 KiB. Offscreen sau GC cuối: RSS 89576 KiB.
GC không được thêm vào sản phẩm và không được dùng để che xu hướng ở các đợt
20/120/220/320 ban đầu. Số liệu phù hợp với cache/thu gom trì hoãn và tài nguyên
dựng hình, nhưng không đủ để loại trừ mọi rò rỉ native hoặc khẳng định ổn định dài hạn.

Qt giải thích rằng thu gom JavaScript diễn ra theo heuristic và RSS không phản
ánh trực tiếp lượng đối tượng còn sống:
[Memory Management in the JavaScript Engine](https://doc.qt.io/qt-6/qtqml-javascript-memory.html).
Đây là cơ sở giải thích khả dĩ, không phải bằng chứng xác định nguyên nhân của mọi trang RAM.

## Chạy lại

Công cụ `tools/dashboard_memory_probe.py` chỉ cho phép chạy trên j4n9-proxmox.
Dùng Python 3 và qs đã có sẵn, không cài thêm gói. Thư mục output phải chưa tồn tại:

```sh
python3 dots/quickshell/tools/dashboard_memory_probe.py \
  --backend offscreen --batches 20,100,100,100 \
  --output /tmp/dashboard-memory-offscreen-run

python3 dots/quickshell/tools/dashboard_memory_probe.py \
  --backend wayland --batches 20,100,100 --reloads 3 \
  --output /tmp/dashboard-memory-wayland-run
```

Wayland sẽ hiện/ẩn dashboard của bản thử. Đợi phép đo kết thúc trước khi chạy
kiểm thử bàn phím khác. Công cụ lưu results.json và probe.log, dọn bản sao tạm
và dừng đúng tiến trình thử khi kết thúc; không reload/kill shell thật.
`--diagnostic-gc` chỉ gọi GC một lần trong bản thử sau các phép đo thông thường.
Không kết hợp giá trị trước/sau GC thành một chuỗi được coi là hoàn toàn tự nhiên.

Chỉ coi phép kiểm tra đạt nếu nội dung/đồng hồ có số tạo/hủy bằng nhau khi đóng,
Loader đã giải phóng item và RAM không tăng đều theo từng chu kỳ sau khi làm nóng.
Nếu RSS/PSS tiếp tục tăng qua nhiều đợt dài, cần khảo sát native allocations và
renderer; không tự động thêm timer GC hoặc chuyển sang giữ widget sống mãi.

## Đối chứng live reload trên Wayland

Cùng Dashboard và PanelWindow, chỉ đổi QT_QUICK_BACKEND trong tiến trình thử;
phiên thật giữ nguyên. Mỗi bản chạy 5 chu kỳ làm nóng, rồi 12 reload khi đang mở;
sau mỗi reload xác nhận mở lại, đóng và lấy mẫu nhàn rỗi 2 giây.

| Mốc | RSS renderer mặc định (KiB) | RSS software renderer (KiB) |
| --- | ---: | ---: |
| Sau 5 chu kỳ | 232484 | 89808 |
| Reload 1 | 250392 | 94624 |
| Reload 2 | 287252 | 95736 |
| Reload 6 | 267708 | 94980 |
| Reload 10 | 262096 | 95268 |
| Reload 12 | 265072 | 95340 |

Software giữ khoảng 94624–95736 KiB qua 12 reload, số tạo/hủy nội dung và đồng
hồ cuối đợt là 29/29. Renderer mặc định có dao động lớn hơn; tới reload 10 RSS
đã giảm so với reload 2 và 9. Vì vậy không thể ngoại suy số tăng ở vài lần đầu
thành rò rỉ tuyến tính theo số reload.

Khác biệt này cho thấy renderer/driver/cache đóng góp lớn trong kịch bản VM,
nhưng chưa chỉ ra allocation native cụ thể. Không đổi renderer phiên thật,
không thêm GC định kỳ và không thay Loader bằng cache giữ widget sống.
Software có thể được đánh giá riêng cho VM; kết quả này không phải chỉ dẫn áp
dụng laptop hoặc bằng chứng hiệu năng hoạt ảnh tương đương trên mọi widget.

Để chạy lại đối chứng với cùng đối số, dùng thư mục output mới cho mỗi lần:

```sh
QT_QUICK_BACKEND=software python3 dots/quickshell/tools/dashboard_memory_probe.py \
  --backend wayland --batches 5 --idle-seconds 2 --reloads 12 \
  --output /tmp/dashboard-software-reloads-run
```

Bỏ biến QT_QUICK_BACKEND để đo mặc định (bảo đảm nó cũng chưa được đặt trong
môi trường gọi). Không chạy kiểm thử bàn phím đồng thời với probe Wayland.

Dữ liệu đo được lưu tại [measurements/dashboard-memory-2026-11-10.json](measurements/dashboard-memory-2026-11-10.json).

## Hồi quy và phạm vi thay đổi

Kiểm thử lại fixture giao diện đạt: mode/audio/slider/Wi-Fi/DND với service mô
phỏng; shortcut/launcher/popup; lịch năm nhuận và đổi năm; bố cục 380×500;
Tab/Shift+Tab, Enter, Escape, mũi tên slider/lịch; bỏ qua thiết bị bị vô hiệu.
Shell thật cuối đợt báo dashboard đóng, loaded=false, notification backend vẫn
available và center đã đóng. Tất cả tiến trình probe được dừng khi hoàn tất.

Lượt này chỉ thêm công cụ Python, báo cáo/số liệu và liên kết README; không sửa
QML runtime, cấu hình renderer, Hyprland, NixOS hoặc laptop. Không có nguyên nhân
rò rỉ QML được xác định để cần một bản vá vòng đời widget. Cần profiling native
riêng nếu gặp tăng RAM liên tục ngoài phạm vi các phép thử trên.
