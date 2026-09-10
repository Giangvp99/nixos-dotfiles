# Quickshell Architecture

## 1. Dependency direction

Dependency chỉ được đi theo hướng:

System
  ↓
Services
  ↓
Modules
  ↓
Components

Config có thể được Services, Modules và Components đọc.

Không được để Components gọi ngược System.

## 2. shell.qml

shell.qml là composition root.

Nó chỉ:

- khởi tạo module cấp cao;
- khởi tạo global service nếu cần;
- quản lý lifecycle cấp shell.

shell.qml không chứa:

- widget implementation;
- màu sắc;
- system command;
- feature-specific logic.

## 3. Config layer

Config layer gồm:

- Config.qml: kích thước, behavior, feature flag;
- Theme.qml: màu sắc, font, radius;
- Animations.qml: duration và easing.

## 4. Service layer

Một service sở hữu dữ liệu thuộc một domain.

Ví dụ:

AudioService
- volume
- muted
- sink
- toggleMute()
- setVolume()

NetworkService
- enabled
- connected
- ssid
- strength

Service không render Item, Rectangle, Text hoặc Window.

## 5. Component layer

Component là UI primitive.

Ví dụ:

- StyledText
- Surface
- IconButton
- Slider
- Tooltip
- Card

Component phải sử dụng được ở nhiều feature khác nhau.

## 6. Module layer

Module là feature hoàn chỉnh.

Ví dụ:

- Bar
- Launcher
- ControlCenter
- Notifications
- OSD

Module được phép sử dụng:

- services
- components
- config
- utils

## 7. Widget

Widget là component thuộc một feature cụ thể.

Ví dụ:

modules/bar/widgets/Audio.qml

Audio là widget vì nó chỉ có ý nghĩa trong UI bar.

IconButton không phải widget vì nó có thể được dùng ở nhiều module.

## 8. State ownership

Mỗi state chỉ có một owner.

Không copy trạng thái system vào nhiều widget nếu có thể bind trực tiếp với service.

## 9. Event-driven

Ưu tiên:

1. Quickshell native API
2. Qt API / DBus
3. event/socket
4. Process
5. polling

Polling là lựa chọn cuối cùng.

## 10. Imports

Luôn import layer bằng alias rõ ràng:

    import "../../../config" as Config
    import "../../../services" as Services
    import "../../../components" as Components

Dùng:

    Config.Theme.text
    Services.HyprlandService.activeToplevel
    Components.StyledText

Không dựa vào global implicit import giữa các thư mục.
