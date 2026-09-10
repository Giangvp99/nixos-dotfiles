# Development Workflow

## Khi sửa UI hiện có

1. Xác định module.
2. Xác định component/widget cần sửa.
3. Không thêm system logic vào UI.
4. Không hardcode token nếu Theme/Config đã có.
5. Save.
6. Reload Quickshell.
7. Kiểm tra log.

## Khi thêm feature mới

Luôn đi theo thứ tự:

Data source
→ Service
→ reusable Component nếu cần
→ Module/Widget
→ Interaction
→ Animation
→ Edge cases
→ Documentation

## Checklist trước khi commit

- Có duplicate state không?
- Có Process không cần thiết không?
- Có Timer polling không cần thiết không?
- Có hardcoded color không?
- Có hardcoded animation duration không?
- Có component nào đáng tái sử dụng không?
- Service có chứa UI không?
- Component có truy cập system không?
- README của thư mục đã cập nhật chưa?

## Naming

PascalCase:

    AudioService.qml
    Workspaces.qml
    IconButton.qml

Singleton service:

    SomethingService.qml

Top-level feature:

    Launcher.qml
    ControlCenter.qml

Widget:

    Audio.qml
    Battery.qml

## Debug

Chạy foreground:

    qs

Theo dõi log Quickshell.

Thay đổi từng phần nhỏ và kiểm tra ngay.

Không thay đổi service + theme + module lớn cùng lúc nếu đang debug.
