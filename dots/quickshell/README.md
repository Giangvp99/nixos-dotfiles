# j4n9 Quickshell

Quickshell desktop shell dành cho cấu hình Hyprland trong nixos-dotfiles.

## Mục tiêu

Project được thiết kế theo các nguyên tắc:

- modular;
- event-driven;
- live editable;
- dễ mở rộng;
- state có owner rõ ràng;
- UI tách khỏi system logic;
- ưu tiên Quickshell native API;
- hạn chế Process và polling;
- tất cả appearance đi qua Theme/Config.

## Kiến trúc

shell.qml
    ↓
modules/
    ↓
components/
    ↑
services/
    ↑
System

config/ được sử dụng xuyên suốt để quản lý appearance và behavior.

## Các thư mục

- `config/`: cấu hình, theme, animation token.
- `services/`: system integration và dữ liệu.
- `components/`: UI primitives có thể tái sử dụng.
- `modules/`: feature hoàn chỉnh.
- `utils/`: hàm helper thuần.
- `assets/`: icon, image và tài nguyên tĩnh.
- `docs/`: tài liệu kiến trúc và quy trình phát triển.

## Quy tắc bắt buộc

Không truy cập trực tiếp system từ component.

Không hardcode màu sắc và animation trong module nếu giá trị đó có thể nằm trong Theme.

Không tạo state trùng lặp ở nhiều widget.

Không dùng polling nếu Quickshell hoặc subsystem đã cung cấp event/API.

Không đặt business logic trong shell.qml.

## Development

QML được symlink trực tiếp từ repository tới:

    ~/.config/quickshell

Do đó thay đổi trong `dots/quickshell/` không yêu cầu rebuild NixOS.

Sau khi sửa:

    qs

hoặc reload instance Quickshell đang chạy.

Xem thêm:

- docs/ARCHITECTURE.md
- docs/DEVELOPMENT.md
- docs/NEW_FEATURE.md
